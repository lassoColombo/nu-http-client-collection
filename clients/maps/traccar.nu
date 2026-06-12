# Auto-generated client for Traccar v5.6
# Source: https://api.apis.guru/v2/specs/traccar.org/5.6/openapi.json
# Auth: --token flag or $env.TRACCAR_TOKEN

const BASE_URL = "https://demo.traccar.org/api"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRACCAR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://demo.traccar.org/api" "https://demo2.traccar.org/api" "https://demo3.traccar.org/api" "https://demo4.traccar.org/api" "https://server.traccar.org/api" "http://localhost:8082/api" "http://localhost:80/api"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/gpx+xml" "application/json" "text/csv"] }
def accept-completer-1 [] { ["application/json" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attributes-computed get" } } | get name | first)
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

# Fetch a list of Attributes
#
# GET /attributes/computed
export def "attributes-computed get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<attribute: string, description: string, expression: string, id: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attributes/computed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Attribute
#
# POST /attributes/computed
export def "attributes-computed post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string
  --description: string
  --expression: string
  --id: int
  --type: string # String|Number|Boolean
]: any -> record<attribute: string, description: string, expression: string, id: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/computed")
  let body = {attribute: $attribute, description: $description, expression: $expression, id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Attribute
#
# DELETE /attributes/computed/{id}
export def "attributes-computed delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attributes/computed/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Attribute
#
# PUT /attributes/computed/{id}
export def "attributes-computed put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string
  --description: string
  --expression: string
  --body-id: int
  --type: string # String|Number|Boolean
]: any -> record<attribute: string, description: string, expression: string, id: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attributes/computed/($id)")
  let body = {attribute: $attribute, description: $description, expression: $expression, id: $body_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Calendars
#
# GET /calendars
export def "calendars get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
]: nothing -> table<attributes: record, data: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Calendar
#
# POST /calendars
export def "calendars post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --data: string # base64 encoded in iCalendar format
  --id: int
  --name: string
]: any -> record<attributes: record, data: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calendars")
  let body = {attributes: $attributes, data: $data, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Calendar
#
# DELETE /calendars/{id}
export def "calendars delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Calendar
#
# PUT /calendars/{id}
export def "calendars put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --data: string # base64 encoded in iCalendar format
  --body-id: int
  --name: string
]: any -> record<attributes: record, data: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/($id)")
  let body = {attributes: $attributes, data: $data, id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Saved Commands
#
# GET /commands
export def "commands get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<attributes: record, description: string, deviceId: int, id: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Saved Command
#
# POST /commands
export def "commands post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --deviceId: int
  --id: int
  --type: string
]: any -> record<attributes: record, description: string, deviceId: int, id: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commands")
  let body = {attributes: $attributes, description: $description, deviceId: $deviceId, id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Saved Commands supported by Device at the moment
#
# GET /commands/send
export def "commands-send get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
]: nothing -> table<attributes: record, description: string, deviceId: int, id: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commands/send" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dispatch commands to device
#
# POST /commands/send
export def "commands-send post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --deviceId: int
  --id: int
  --type: string
]: any -> record<attributes: record, description: string, deviceId: int, id: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commands/send")
  let body = {attributes: $attributes, description: $description, deviceId: $deviceId, id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of available Commands for the Device or all possible Commands if Device ommited
#
# GET /commands/types
export def "commands-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deviceId: int # Internal device identifier. Only works if device has already reported some locations
  --protocol: string # Protocol name. Can be used instead of device id
  --textChannel: oneof<nothing, bool> # When `true` return SMS commands. If not specified or `false` return data commands
]: nothing -> table<type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "textChannel" $textChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commands/types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Saved Command
#
# DELETE /commands/{id}
export def "commands delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commands/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Saved Command
#
# PUT /commands/{id}
export def "commands put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --deviceId: int
  --body-id: int
  --type: string
]: any -> record<attributes: record, description: string, deviceId: int, id: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commands/($id)")
  let body = {attributes: $attributes, description: $description, deviceId: $deviceId, id: $body_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Devices
#
# GET /devices
export def "devices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --id: int # To fetch one or more devices. Multiple params can be passed like `id=31&id=42`
  --uniqueId: string # To fetch one or more devices. Multiple params can be passed like `uniqueId=333331&uniqieId=44442`
]: nothing -> table<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "uniqueId" $uniqueId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Device
#
# POST /devices
export def "devices post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --category: string
  --contact: string
  --disabled: oneof<nothing, bool>
  --geofenceIds: list
  --groupId: int
  --id: int
  --lastUpdate: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --model: string
  --name: string
  --phone: string
  --positionId: int
  --status: string
  --uniqueId: string
]: any -> record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/devices")
  let body = {attributes: $attributes, category: $category, contact: $contact, disabled: $disabled, geofenceIds: $geofenceIds, groupId: $groupId, id: $id, lastUpdate: $lastUpdate, model: $model, name: $name, phone: $phone, positionId: $positionId, status: $status, uniqueId: $uniqueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Device
#
# DELETE /devices/{id}
export def "devices delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Device
#
# PUT /devices/{id}
export def "devices put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --category: string
  --contact: string
  --disabled: oneof<nothing, bool>
  --geofenceIds: list
  --groupId: int
  --body-id: int
  --lastUpdate: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --model: string
  --name: string
  --phone: string
  --positionId: int
  --status: string
  --uniqueId: string
]: any -> record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($id)")
  let body = {attributes: $attributes, category: $category, contact: $contact, disabled: $disabled, geofenceIds: $geofenceIds, groupId: $groupId, id: $body_id, lastUpdate: $lastUpdate, model: $model, name: $name, phone: $phone, positionId: $positionId, status: $status, uniqueId: $uniqueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update total distance and hours of the Device
#
# PUT /devices/{id}/accumulators
export def "devices-accumulators put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deviceId: int
  --hours: float
  --totalDistance: float # in meters
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($id)/accumulators")
  let body = {deviceId: $deviceId, hours: $hours, totalDistance: $totalDistance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Drivers
#
# GET /drivers
export def "drivers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<attributes: record, id: int, name: string, uniqueId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drivers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Driver
#
# POST /drivers
export def "drivers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --id: int
  --name: string
  --uniqueId: string
]: any -> record<attributes: record, id: int, name: string, uniqueId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drivers")
  let body = {attributes: $attributes, id: $id, name: $name, uniqueId: $uniqueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Driver
#
# DELETE /drivers/{id}
export def "drivers delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/drivers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Driver
#
# PUT /drivers/{id}
export def "drivers put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --body-id: int
  --name: string
  --uniqueId: string
]: any -> record<attributes: record, id: int, name: string, uniqueId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/drivers/($id)")
  let body = {attributes: $attributes, id: $body_id, name: $name, uniqueId: $uniqueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /events/{id}
export def "events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of Geofences
#
# GET /geofences
export def "geofences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<area: string, attributes: record, calendarId: int, description: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geofences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Geofence
#
# POST /geofences
export def "geofences post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string
  --attributes: record
  --calendarId: int
  --description: string
  --id: int
  --name: string
]: any -> record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofences")
  let body = {area: $area, attributes: $attributes, calendarId: $calendarId, description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Geofence
#
# DELETE /geofences/{id}
export def "geofences delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/geofences/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Geofence
#
# PUT /geofences/{id}
export def "geofences put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string
  --attributes: record
  --calendarId: int
  --description: string
  --body-id: int
  --name: string
]: any -> record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/geofences/($id)")
  let body = {area: $area, attributes: $attributes, calendarId: $calendarId, description: $description, id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Groups
#
# GET /groups
export def "groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
]: nothing -> table<attributes: record, groupId: int, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Group
#
# POST /groups
export def "groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --groupId: int
  --id: int
  --name: string
]: any -> record<attributes: record, groupId: int, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let body = {attributes: $attributes, groupId: $groupId, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Group
#
# DELETE /groups/{id}
export def "groups delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Group
#
# PUT /groups/{id}
export def "groups put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --groupId: int
  --body-id: int
  --name: string
]: any -> record<attributes: record, groupId: int, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let body = {attributes: $attributes, groupId: $groupId, id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Maintenance
#
# GET /maintenance
export def "maintenance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<attributes: record, id: int, name: string, period: float, start: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maintenance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Maintenance
#
# POST /maintenance
export def "maintenance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --id: int
  --name: string
  --period: float
  --start: float
  --type: string
]: any -> record<attributes: record, id: int, name: string, period: float, start: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maintenance")
  let body = {attributes: $attributes, id: $id, name: $name, period: $period, start: $start, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Maintenance
#
# DELETE /maintenance/{id}
export def "maintenance delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Maintenance
#
# PUT /maintenance/{id}
export def "maintenance put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --body-id: int
  --name: string
  --period: float
  --start: float
  --type: string
]: any -> record<attributes: record, id: int, name: string, period: float, start: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance/($id)")
  let body = {attributes: $attributes, id: $body_id, name: $name, period: $period, start: $start, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of Notifications
#
# GET /notifications
export def "notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --userId: int # Standard users can use this only with their own _userId_
  --deviceId: int # Standard users can use this only with _deviceId_s, they have access to
  --groupId: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> table<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Notification
#
# POST /notifications
export def "notifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --always: oneof<nothing, bool>
  --attributes: record
  --calendarId: int
  --id: int
  --mail: oneof<nothing, bool>
  --sms: oneof<nothing, bool>
  --type: string
  --web: oneof<nothing, bool>
]: any -> record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications")
  let body = {always: $always, attributes: $attributes, calendarId: $calendarId, id: $id, mail: $mail, sms: $sms, type: $type, web: $web} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send test notification to current user via Email and SMS
#
# POST /notifications/test
export def "notifications-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of available Notification types
#
# GET /notifications/types
export def "notifications-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Notification
#
# DELETE /notifications/{id}
export def "notifications delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Notification
#
# PUT /notifications/{id}
export def "notifications put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --always: oneof<nothing, bool>
  --attributes: record
  --calendarId: int
  --body-id: int
  --mail: oneof<nothing, bool>
  --sms: oneof<nothing, bool>
  --type: string
  --web: oneof<nothing, bool>
]: any -> record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($id)")
  let body = {always: $always, attributes: $attributes, calendarId: $calendarId, id: $body_id, mail: $mail, sms: $sms, type: $type, web: $web} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlink an Object from another Object
#
# DELETE /permissions
export def "permissions delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributeId: int # Computed Attribute Id, can be second parameter only
  --calendarId: int # Calendar Id, can be second parameter only and only in combination with userId
  --deviceId: int # Device Id, can be first parameter or second only in combination with userId
  --driverId: int # Driver Id, can be second parameter only
  --geofenceId: int # Geofence Id, can be second parameter only
  --groupId: int # Group Id, can be first parameter or second only in combination with userId
  --managedUserId: int # User Id, can be second parameter only and only in combination with userId
  --notificationId: int # Notification Id, can be second parameter only
  --userId: int # User Id, can be only first parameter
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let body = {attributeId: $attributeId, calendarId: $calendarId, deviceId: $deviceId, driverId: $driverId, geofenceId: $geofenceId, groupId: $groupId, managedUserId: $managedUserId, notificationId: $notificationId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Link an Object to another Object
#
# POST /permissions
export def "permissions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributeId: int # Computed Attribute Id, can be second parameter only
  --calendarId: int # Calendar Id, can be second parameter only and only in combination with userId
  --deviceId: int # Device Id, can be first parameter or second only in combination with userId
  --driverId: int # Driver Id, can be second parameter only
  --geofenceId: int # Geofence Id, can be second parameter only
  --groupId: int # Group Id, can be first parameter or second only in combination with userId
  --managedUserId: int # User Id, can be second parameter only and only in combination with userId
  --notificationId: int # Notification Id, can be second parameter only
  --userId: int # User Id, can be only first parameter
]: any -> record<attributeId: int, calendarId: int, deviceId: int, driverId: int, geofenceId: int, groupId: int, managedUserId: int, notificationId: int, userId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let body = {attributeId: $attributeId, calendarId: $calendarId, deviceId: $deviceId, driverId: $driverId, geofenceId: $geofenceId, groupId: $groupId, managedUserId: $managedUserId, notificationId: $notificationId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetches a list of Positions
#
# GET /positions
export def "positions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deviceId: int # _deviceId_ is optional, but requires the _from_ and _to_ parameters when used
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --id: int # To fetch one or more positions. Multiple params can be passed like `id=31&id=42`
]: nothing -> table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/positions" $qp)
  let accept_val = ($accept | default "application/gpx+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of Events within the time period for the Devices or Groups
#
# GET /reports/events
export def "reports-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --deviceId: list
  --groupId: list
  --type: list # % can be used to return events of all types
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "multi") (serialize-qp "groupId" $groupId "multi") (serialize-qp "type" $type "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of Positions within the time period for the Devices or Groups
#
# GET /reports/route
export def "reports-route get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --deviceId: list
  --groupId: list
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "multi") (serialize-qp "groupId" $groupId "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/route" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of ReportStops within the time period for the Devices or Groups
#
# GET /reports/stops
export def "reports-stops get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --deviceId: list
  --groupId: list
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<address: string, deviceId: int, deviceName: string, duration: int, endTime: string, engineHours: int, lat: float, lon: float, spentFuel: float, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "multi") (serialize-qp "groupId" $groupId "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/stops" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of ReportSummary within the time period for the Devices or Groups
#
# GET /reports/summary
export def "reports-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --deviceId: list
  --groupId: list
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, engineHours: int, maxSpeed: float, spentFuel: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "multi") (serialize-qp "groupId" $groupId "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of ReportTrips within the time period for the Devices or Groups
#
# GET /reports/trips
export def "reports-trips get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --deviceId: list
  --groupId: list
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, driverName: string, driverUniqueId: int, duration: int, endAddress: string, endLat: float, endLon: float, endTime: string, maxSpeed: float, spentFuel: float, startAddress: string, startLat: float, startLon: float, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deviceId" $deviceId "multi") (serialize-qp "groupId" $groupId "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/trips" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch Server information
#
# GET /server
export def "server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Server information
#
# PUT /server
export def "server put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --bingKey: string
  --coordinateFormat: string
  --deviceReadonly: oneof<nothing, bool>
  --forceSettings: oneof<nothing, bool>
  --id: int
  --latitude: float
  --limitCommands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --mapUrl: string
  --poiLayer: string
  --readonly: oneof<nothing, bool>
  --registration: oneof<nothing, bool>
  --twelveHourFormat: oneof<nothing, bool>
  --version: string
  --zoom: int
]: any -> record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server")
  let body = {attributes: $attributes, bingKey: $bingKey, coordinateFormat: $coordinateFormat, deviceReadonly: $deviceReadonly, forceSettings: $forceSettings, id: $id, latitude: $latitude, limitCommands: $limitCommands, longitude: $longitude, map: $map, mapUrl: $mapUrl, poiLayer: $poiLayer, readonly: $readonly, registration: $registration, twelveHourFormat: $twelveHourFormat, version: $version, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close the Session
#
# DELETE /session
export def "session delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch Session information
#
# GET /session
export def "session get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string
]: nothing -> record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Session
#
# POST /session
export def "session post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  password: string # format: password
]: any -> record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch server Statistics
#
# GET /statistics
export def "statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --qp-to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
]: nothing -> table<activeDevices: int, activeUsers: int, captureTime: string, messagesReceived: int, messagesStored: int, requests: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of Users
#
# GET /users
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # Can only be used by admin or manager users
]: nothing -> table<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a User
#
# POST /users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --administrator: oneof<nothing, bool>
  --attributes: record
  --coordinateFormat: string
  --deviceLimit: int
  --deviceReadonly: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  --email: string
  --expirationTime: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --id: int
  --latitude: float
  --limitCommands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --name: string
  --password: string
  --phone: string
  --poiLayer: string
  --readonly: oneof<nothing, bool>
  --twelveHourFormat: oneof<nothing, bool>
  --userLimit: int
  --zoom: int
]: any -> record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {administrator: $administrator, attributes: $attributes, coordinateFormat: $coordinateFormat, deviceLimit: $deviceLimit, deviceReadonly: $deviceReadonly, disabled: $disabled, email: $email, expirationTime: $expirationTime, id: $id, latitude: $latitude, limitCommands: $limitCommands, longitude: $longitude, map: $map, name: $name, password: $password, phone: $phone, poiLayer: $poiLayer, readonly: $readonly, twelveHourFormat: $twelveHourFormat, userLimit: $userLimit, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a User
#
# DELETE /users/{id}
export def "users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a User
#
# PUT /users/{id}
export def "users put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --administrator: oneof<nothing, bool>
  --attributes: record
  --coordinateFormat: string
  --deviceLimit: int
  --deviceReadonly: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  --email: string
  --expirationTime: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --body-id: int
  --latitude: float
  --limitCommands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --name: string
  --password: string
  --phone: string
  --poiLayer: string
  --readonly: oneof<nothing, bool>
  --twelveHourFormat: oneof<nothing, bool>
  --userLimit: int
  --zoom: int
]: any -> record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {administrator: $administrator, attributes: $attributes, coordinateFormat: $coordinateFormat, deviceLimit: $deviceLimit, deviceReadonly: $deviceReadonly, disabled: $disabled, email: $email, expirationTime: $expirationTime, id: $body_id, latitude: $latitude, limitCommands: $limitCommands, longitude: $longitude, map: $map, name: $name, password: $password, phone: $phone, poiLayer: $poiLayer, readonly: $readonly, twelveHourFormat: $twelveHourFormat, userLimit: $userLimit, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
