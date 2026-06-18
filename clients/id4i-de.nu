# Auto-generated client for ID4i API v1.0.2
# Source: https://api.apis.guru/v2/specs/id4i.de/1.0.2/openapi.json
# Auth: --token flag or $env.ID4I_API_TOKEN

const BASE_URL = "http://localhost//backend.id4i.de"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ID4I_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost//backend.id4i.de"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def type-completer [] { ["LABELLED_COLLECTION" "LOGISTIC_COLLECTION" "ROUTING_COLLECTION"] }
def physical-state-completer [] { ["ATTACHED" "DETACHED" "UNATTACHED"] }
def type-completer-1 [] { ["CREATED" "DELIVERY_REFUSED" "DESTROYED" "DISASSEMBLED" "DISPATCHED" "MAINTENANCE_CANCELLED" "MAINTENANCE_FINISHED" "MAINTENANCE_STARTED" "MAINTENANCE_STEP_CANCELLED" "MAINTENANCE_STEP_FINISHED" "MAINTENANCE_STEP_STARTED" "PACKAGED" "PRODUCTION_CANCELLED" "PRODUCTION_FINISHED" "PRODUCTION_STARTED" "PRODUCTION_STEP_CANCELLED" "PRODUCTION_STEP_FINISHED" "PRODUCTION_STEP_STARTED" "QUALITY_CHECK_PERFORMED" "RECEIVED" "RECYCLED" "REPROCESSING_CANCELLED" "REPROCESSING_FINISHED" "REPROCESSING_STARTED" "REPROCESSING_STEP_CANCELLED" "REPROCESSING_STEP_FINISHED" "REPROCESSING_STEP_STARTED" "RETRIEVED_FROM_STORAGE" "SHIPMENT_PREPARED" "STORED"] }
def alias-type-completer [] { ["article" "eclass" "gtin" "item" "mapp" "material" "product" "reference" "rfid" "tracking" "unspsc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-password request-reset" } } | get name | first)
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

# Request password reset
#
# POST /account/password
# operationId: requestPasswordReset
export def "account-password request-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  username: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/password")
  let req_body = {"username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Verify password reset
#
# PUT /account/password
# operationId: verifyPasswordReset
export def "account-password verify-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  password: string
  --body-token: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/password")
  let req_body = {"password": $password, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Register user
#
# POST /account/registration
# operationId: registerUser
export def "account-registration create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string
  password: string
  username: string
]: any -> record<email: string, id: int, message: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/registration")
  let req_body = {"email": $email, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Complete registration
#
# PUT /account/registration
# operationId: completeRegistration
export def "account-registration complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  username: string
  verification_token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/registration")
  let req_body = {"password": $password, "username": $username, "verificationToken": $verification_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Verify registration
#
# POST /account/verification
# operationId: verifyUserRegistration
export def "account-verification verify-user-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/verification")
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find API key by organization
#
# GET /api/v1/apikeys
# operationId: listAllApiKeysOfOrganization
export def "apikeys list-list-keys-of-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The namespace of the organization to search in.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/apikeys" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API key
#
# POST /api/v1/apikeys
# operationId: createNewApiKey
export def "apikeys create-new-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  label: string
  organization_id: string # e.g. de.acme
  secret: string
]: any -> record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/apikeys")
  let req_body = {"label": $label, "organizationId": $organization_id, "secret": $secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all privileges
#
# GET /api/v1/apikeys/privileges
# operationId: listAllApiKeyPrivileges
export def "apikeys-privileges list-list-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id4n-concerning: oneof<nothing, bool> # id4nConcerning
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<allowsBillableOperations: bool, helpText: string, id4nAssociated: bool, name: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id4nConcerning" $id4n_concerning "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/apikeys/privileges" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete API key
#
# DELETE /api/v1/apikeys/{key}
# operationId: deleteApiKey
export def "apikeys delete" [
  key: string
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show API key
#
# GET /api/v1/apikeys/{key}
# operationId: getApiKey
export def "apikeys get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update API keys
#
# PUT /api/v1/apikeys/{key}
# operationId: updateApiKey
export def "apikeys update" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  new_label: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}"))
  let req_body = {"active": $active, "newLabel": $new_label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove privilege
#
# DELETE /api/v1/apikeys/{key}/privileges
# operationId: removeApiKeyPrivilege
export def "apikeys-privileges delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  privilege: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}/privileges"))
  let req_body = {"privilege": $privilege} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List privileges
#
# GET /api/v1/apikeys/{key}/privileges
# operationId: listApiKeyPrivileges
export def "apikeys-privileges list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<id4nAssociated: bool, privilege: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}/privileges") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add privilege
#
# POST /api/v1/apikeys/{key}/privileges
# operationId: addApiKeyPrivilege
export def "apikeys-privileges create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  privilege: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/apikeys/{key}/privileges"))
  let req_body = {"privilege": $privilege} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove id4ns of a privilege
#
# DELETE /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# operationId: removeApiKeyPrivilegeForId4ns
export def "apikeys-privileges-id4ns delete" [
  key: string
  privilege: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key), privilege: (encode-path-segment $privilege)} | format pattern "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns"))
  let req_body = {"id4ns": $id4ns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ID4ns of a privilege
#
# GET /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# operationId: listId4ns
export def "apikeys-privileges-id4ns list" [
  key: string
  privilege: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), privilege: (encode-path-segment $privilege)} | format pattern "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add ID4ns of a privilege
#
# POST /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# operationId: addApiKeyPrivilegeForId4ns
export def "apikeys-privileges-id4ns create" [
  key: string
  privilege: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key), privilege: (encode-path-segment $privilege)} | format pattern "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns"))
  let req_body = {"id4ns": $id4ns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get billing amount of services for a given organization
#
# GET /api/v1/billing/{organizationId}
# operationId: getSumForOrganization
export def "billing get-sum-for-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-date: string # Billing start date (format: date-time)
  --to-date: string # Billing end date (format: date-time)
]: nothing -> record<listing: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/billing/{organization_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get billing positions for a given organization
#
# GET /api/v1/billing/{organizationId}/positions
# operationId: getPositionsForOrganization
export def "billing-positions get-for-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-date: string # Billing start date (format: date-time)
  --to-date: string # Billing end date (format: date-time)
]: nothing -> table<amount: int, count: float, description: string, service: string, singlePrice: float, sum: float, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/billing/{organization_id}/positions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List change log entries of an organization
#
# GET /api/v1/changelog/organization/{organizationId}/
# operationId: listOrganizationChangeLog
export def "changelog-organization list-change-log" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --message-mime-type: string # The Mime-type for the message format that should be returned. e.g. 'text/plain' or 'text/mustache' (default: text/mustache)
  --from-date: string # From date time as UTC Date-Time format (format: date-time)
  --to-date: string # To date time as UTC Date-Time format (format: date-time)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<id: string, message: string, messageProperties: record, timestamp: int>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "messageMimeType" $message_mime_type "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/changelog/organization/{organization_id}/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create collection
#
# POST /api/v1/collections
# operationId: createCollection
export def "collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --label: string
  length: int # format: int32
  organization_id: string # e.g. de.acme
  type: string@type-completer
]: any -> record<id4n: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/collections")
  let req_body = {"label": $label, "length": $length, "organizationId": $organization_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete collection
#
# DELETE /api/v1/collections/{id4n}
# operationId: deleteCollection
export def "collections delete" [
  id4n: string
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
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find collection
#
# GET /api/v1/collections/{id4n}
# operationId: findCollection
export def "collections find" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update collection
#
# PATCH /api/v1/collections/{id4n}
# operationId: updateCollection
export def "collections update" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --holder-organization-id: string # Organization namespace of the holder of the collection
  --label: string
  --physical-state: string@physical-state-completer # Physical attachment state of the collection
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}"))
  let req_body = {"holderOrganizationId": $holder_organization_id, "label": $label, "physicalState": $physical_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove elements from collection
#
# DELETE /api/v1/collections/{id4n}/elements
# operationId: removeElementsFromCollection
export def "collections-elements delete" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}/elements"))
  let req_body = {"id4ns": $id4ns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List contents of the collection
#
# GET /api/v1/collections/{id4n}/elements
# operationId: listElementsOfCollection
export def "collections-elements list" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
  --organization-id: string # The organization namespace.
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}/elements") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add elements to collection
#
# POST /api/v1/collections/{id4n}/elements
# operationId: addElementsToCollection
export def "collections-elements create" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/collections/{id4n}/elements"))
  let req_body = {"id4ns": $id4ns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List countries
#
# GET /api/v1/countries
# operationId: listCountries
export def "countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<code: string, name: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/countries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List documents
#
# GET /api/v1/documents/{id4n}
# operationId: listAllDocuments
export def "documents list-list" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/documents/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization specific documents
#
# GET /api/v1/documents/{id4n}/{organizationId}
# operationId: listDocuments
export def "documents list" [
  id4n: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/documents/{id4n}/{organization_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an document for an id4n
#
# POST /api/v1/documents/{id4n}/{organizationId}
# operationId: createDocument
export def "documents create" [
  id4n: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  content: string # content (format: binary)
]: any -> record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/documents/{id4n}/{organization_id}"))
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["content"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Put an document for an id4n
#
# PUT /api/v1/documents/{id4n}/{organizationId}
# operationId: putDocument
export def "documents update" [
  id4n: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  content: string # content (format: binary)
]: any -> record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/documents/{id4n}/{organization_id}"))
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["content"])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete a document
#
# DELETE /api/v1/documents/{id4n}/{organizationId}/{fileName}
# operationId: deleteDocument
export def "documents delete" [
  id4n: string
  organization_id: string
  file_name: string
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
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/documents/{id4n}/{organization_id}/{file_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read document contents
#
# GET /api/v1/documents/{id4n}/{organizationId}/{fileName}
# operationId: readDocument
export def "documents get" [
  id4n: string
  organization_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/documents/{id4n}/{organization_id}/{file_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a document (meta-data only, no content)
#
# GET /api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata
# operationId: getDocument
export def "documents-metadata get" [
  id4n: string
  organization_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/documents/{id4n}/{organization_id}/{file_name}/metadata"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a document
#
# PATCH /api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata
# operationId: updateDocumentMetadata
# --visibility shape: {public?: bool, sharedWithOrganizationIds?: list<string>}
export def "documents-metadata update" [
  id4n: string
  organization_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filename: string # File Name (e.g. publicInfo.pdf)
  --mime-type: string # Mime Type (e.g. text/plain)
  --visibility: record # shape: {public?: bool, sharedWithOrganizationIds?: list<string>}
]: any -> record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/documents/{id4n}/{organization_id}/{file_name}/metadata"))
  let req_body = {"filename": $filename, "mimeType": $mime_type, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create GUID(s)
#
# POST /api/v1/guids
# operationId: createGuid
export def "guids create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  count: int # The total number of GUIDs to create (format: int32, e.g. 1)
  length: int # The charactersequence length of the GUID (format: int32, e.g. 40)
  organization_id: string # The namespace of the organization where the generated GUIDs should be assigned. (e.g. de.acme)
]: any -> record<id4ns: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/guids")
  let req_body = {"count": $count, "length": $length, "organizationId": $organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve GUIDs not in any collection
#
# GET /api/v1/guids/withoutCollection
# operationId: getGuidsWithoutCollection
export def "guids-without-collection get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The namespace of the organization to search GUIDs for
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/guids/withoutCollection" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve GUID information
#
# GET /api/v1/guids/{id4n}
# operationId: getGuid
export def "guids get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The organization namespace to resolve.
]: nothing -> record<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/guids/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change GUID information.
#
# PATCH /api/v1/guids/{id4n}
# operationId: updateGuid
export def "guids update" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --physical-state: string@physical-state-completer # Physical attachment state of the GUID
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/guids/{id4n}"))
  let req_body = {"physicalState": $physical_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List history
#
# GET /api/v1/history/{id4n}
# operationId: filteredList
export def "history list-filtered" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-private: oneof<nothing, bool> # Also return private history entries (default: true)
  --organization: string # Show only entries created by one of the given organizations. This parameter can be used multiple times.
  --type: list<string>@type-completer-1 # Show only entries matching one of the given history item types. This parameter can be used multiple times.
  --qualifier: list<string> # Show only entries matching one of the given history item qualifiers (additional property de.id4i.history.item.qualifier). This parameter can be used multiple times.
  --from-date: string # From date time as UTC Date-Time format (format: date-time)
  --to-date: string # To date time as UTC Date-Time format (format: date-time)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePrivate" $include_private "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "type" $type "multi") (serialize-qp "qualifier" $qualifier "multi") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/history/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add history item
#
# POST /api/v1/history/{id4n}
# operationId: addItem
# --visibility shape: {public?: bool, sharedOrganizationIds?: list<string>}
export def "history create-item" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-properties: record # History items custom additional properties
  organization_id: string # Originator of the history item (e.g. org.acme)
  type: string@type-completer-1 # Type of the history item (e.g. DISPATCHED)
  --visibility: record # shape: {public?: bool, sharedOrganizationIds?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/history/{id4n}"))
  let req_body = {"additionalProperties": $additional_properties, "organizationId": $organization_id, "type": $type, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEPRECATED - List history
#
# GET /api/v1/history/{id4n}/{organizationId}
# DEPRECATED
# operationId: list
@deprecated
export def "history list" [
  id4n: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-private: oneof<nothing, bool> # Also return private history entries (default: true)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePrivate" $include_private "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/history/{id4n}/{organization_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get history item
#
# GET /api/v1/history/{id4n}/{organizationId}/{sequenceId}
# operationId: retrieveItem
export def "history get-item" [
  id4n: string
  organization_id: string
  sequence_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), sequence_id: (encode-path-segment $sequence_id)} | format pattern "/api/v1/history/{id4n}/{organization_id}/{sequence_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update history item
#
# PATCH /api/v1/history/{id4n}/{organizationId}/{sequenceId}
# operationId: updateItem
# --visibility shape: {public?: bool, sharedOrganizationIds?: list<string>}
export def "history update-item" [
  id4n: string
  organization_id: string
  sequence_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-organization-id: string # New organization id displayed for this item. If given, must match the holder of GUID and the organization the history item is found under. (e.g. de.acme)
  --visibility: record # shape: {public?: bool, sharedOrganizationIds?: list<string>}
]: any -> record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), sequence_id: (encode-path-segment $sequence_id)} | format pattern "/api/v1/history/{id4n}/{organization_id}/{sequence_id}"))
  let req_body = {"organizationId": $body_organization_id, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set history item visibility
#
# PUT /api/v1/history/{id4n}/{organizationId}/{sequenceId}/visibility
# operationId: updateItemVisibility
export def "history-visibility update-item" [
  id4n: string
  organization_id: string
  sequence_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --public: oneof<nothing, bool> # Document is publicly readable (if ID4N is owned by the same organization) (e.g. true)
  --shared-organization-ids: list<string> # Document is readable by these organizations (independend of ID4N ownership) (e.g. [de.acme, com.porsche, de.bluerain])
]: any -> record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), sequence_id: (encode-path-segment $sequence_id)} | format pattern "/api/v1/history/{id4n}/{organization_id}/{sequence_id}/visibility"))
  let req_body = {"public": $public, "sharedOrganizationIds": $shared_organization_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve ID4n information
#
# GET /api/v1/id4ns/{id4n}
# operationId: getId4n
export def "id4ns get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The organization namespace to resolve.
]: nothing -> record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all aliases for the given GUID or Collection.
#
# GET /api/v1/id4ns/{id4n}/alias
# operationId: getGuidAliases
export def "id4ns-alias get-guid-aliases" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}/alias"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove aliases from GUID or Collection
#
# DELETE /api/v1/id4ns/{id4n}/alias/{aliasType}
# operationId: removeGuidAlias
export def "id4ns-alias delete-guid" [
  id4n: string
  alias_type: string
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
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), alias_type: (encode-path-segment $alias_type)} | format pattern "/api/v1/id4ns/{id4n}/alias/{alias_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add alias for GUID or Collection
#
# POST /api/v1/id4ns/{id4n}/alias/{aliasType}
# operationId: addGuidAlias
export def "id4ns-alias create-guid" [
  id4n: string
  alias_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alias: string # An alias (e.g. alias)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), alias_type: (encode-path-segment $alias_type)} | format pattern "/api/v1/id4ns/{id4n}/alias/{alias_type}"))
  let req_body = {"alias": $alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve collections of an ID
#
# GET /api/v1/id4ns/{id4n}/collections
# operationId: getCollections
export def "id4ns-collections get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The organization holding the collections.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}/collections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete ID4n properties
#
# DELETE /api/v1/id4ns/{id4n}/properties
# operationId: deleteProperties
export def "id4ns-properties delete" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The organization namespace to work on while deleting the properties.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}/properties") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve ID4n properties
#
# GET /api/v1/id4ns/{id4n}/properties
# operationId: getProperties
export def "id4ns-properties get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # The organization namespace.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}/properties") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch ID4n properties
#
# PATCH /api/v1/id4ns/{id4n}/properties
# operationId: patchProperties
export def "id4ns-properties update" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The organization namespace to work on while patching the properties.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/id4ns/{id4n}/properties") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Import GS1/MAPP codes
#
# POST /api/v1/import/gs1
# operationId: importGS1Codes
# --listOfGS1s shape: {codes?: list<string>}
export def "import-gs1 import-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  list_of_gs1s: record # A list of GS1/MAPP codes — shape: {codes?: list<string>}
  organization_id: string # The organization where the GS1/Mapp code is imported. (e.g. de.acme)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/import/gs1")
  let req_body = {"listOfGS1s": $list_of_gs1s, "organizationId": $organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve version information about ID4i
#
# GET /api/v1/info
# operationId: applicationInfo
export def "info get-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<branch: string, commitTime: string, name: string, productionMode: bool, revision: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/info")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read data from microstorage
#
# GET /api/v1/microstorage/{id4n}/{organization}
# operationId: readFromMicrostorage
export def "microstorage get" [
  id4n: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization: (encode-path-segment $organization)} | format pattern "/api/v1/microstorage/{id4n}/{organization}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write data to microstorage
#
# PUT /api/v1/microstorage/{id4n}/{organization}
# operationId: writeToMicrostorage
export def "microstorage update-write" [
  id4n: string
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Content-Type
  --content-length: int # Content-Length
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization: (encode-path-segment $organization)} | format pattern "/api/v1/microstorage/{id4n}/{organization}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Content-Length": $content_length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "*/*")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Get multiple ID4n properties
#
# GET /api/v1/multiple/id4ns/properties
# operationId: getMultipleProperties
export def "multiple-id4ns-properties get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id4ns: list<string> # The list of ID4ns to resolve.
  --organization-id: string # The organization namespace.
]: nothing -> record<list: table<id4n: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id4ns" $id4ns "multi") (serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/multiple/id4ns/properties" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create organization
#
# POST /api/v1/organizations
# operationId: createOrganization
export def "organizations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # The name of the organization (e.g. ACME Inc.)
  namespace: string # The namespace of the organization (e.g. de.acme)
]: any -> record<id: int, logoURL: string, name: string, namespace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/organizations")
  let req_body = {"name": $name, "namespace": $namespace} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete organization
#
# DELETE /api/v1/organizations/{organizationId}
# operationId: deleteOrganization
export def "organizations delete" [
  organization_id: string
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
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find organization by id/namespace
#
# GET /api/v1/organizations/{organizationId}
# operationId: findOrganization
export def "organizations find" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, logoURL: string, name: string, namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization
#
# PUT /api/v1/organizations/{organizationId}
# operationId: updateOrganization
export def "organizations update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The name of the organization (e.g. ACME Inc.)
]: any -> record<id: int, logoURL: string, name: string, namespace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove billing address
#
# DELETE /api/v1/organizations/{organizationId}/addresses/billing
# operationId: deleteOrganizationBillingAddress
export def "organizations-addresses-billing delete-address" [
  organization_id: string
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
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/addresses/billing"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve billing address
#
# GET /api/v1/organizations/{organizationId}/addresses/billing
# operationId: findOrganizationBillingAddress
export def "organizations-addresses-billing find-address" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/addresses/billing"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store billing address
#
# PUT /api/v1/organizations/{organizationId}/addresses/billing
# operationId: updateOrganizationBillingAddress
export def "organizations-addresses-billing update-address" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  city: string # e.g. MyCity
  --company-name: string # e.g. ACME Inc.
  country_code: string # The ISO 3166 two-letter country code (e.g. DE)
  firstname: string # e.g. Max
  lastname: string # e.g. Muster
  post_code: string # e.g. 12345
  street: string # e.g. Examplestreet 1
  --telephone: string # The telephone number e.g. (e.g. +49 8088 12345)
]: any -> record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/addresses/billing"))
  let req_body = {"city": $city, "companyName": $company_name, "countryCode": $country_code, "firstname": $firstname, "lastname": $lastname, "postCode": $post_code, "street": $street, "telephone": $telephone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve address
#
# GET /api/v1/organizations/{organizationId}/addresses/default
# operationId: findOrganizationAddress
export def "organizations-addresses-default find-address" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/addresses/default"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store address
#
# PUT /api/v1/organizations/{organizationId}/addresses/default
# operationId: updateOrganizationAddress
export def "organizations-addresses-default update-address" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  city: string # e.g. MyCity
  --company-name: string # e.g. ACME Inc.
  country_code: string # The ISO 3166 two-letter country code (e.g. DE)
  firstname: string # e.g. Max
  lastname: string # e.g. Muster
  post_code: string # e.g. 12345
  street: string # e.g. Examplestreet 1
  --telephone: string # The telephone number e.g. (e.g. +49 8088 12345)
]: any -> record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/addresses/default"))
  let req_body = {"city": $city, "companyName": $company_name, "countryCode": $country_code, "firstname": $firstname, "lastname": $lastname, "postCode": $post_code, "street": $street, "telephone": $telephone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get collections of organization
#
# GET /api/v1/organizations/{organizationId}/collections
# operationId: getAllCollectionsOfOrganization
export def "organizations-collections get-list" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
  --type: string@type-completer # Filter by this type
  --label: string # Filter by this label
  --label-prefix: string # Filter by this label prefix
  --property: list<string> # List of i4dn property filter. e.g. "com.myorga.state:IN:waiting|processing" or "com.myorga.orderId:EQ:SAP001"
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "labelPrefix" $label_prefix "scalar") (serialize-qp "property" $property "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/collections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete organization logo
#
# DELETE /api/v1/organizations/{organizationId}/logo
# operationId: deleteOrganizationLogo
export def "organizations-logo delete" [
  organization_id: string
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
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/logo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization logo
#
# POST /api/v1/organizations/{organizationId}/logo
# operationId: setOrganizationLogo
export def "organizations-logo update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  file: string # An image containing the new logo. (format: binary)
]: any -> record<uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/logo"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# GET /api/v1/organizations/{organizationId}/messaging
#
# operationId: getDefaultQueue
export def "organizations-messaging get-default-queue" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, id: string, waitingMessages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/messaging"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/organizations/{organizationId}/messaging
#
# operationId: patchDefaultQueue
export def "organizations-messaging update-default-queue" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # If this value is set to false the queue will be deleted. (e.g. true)
  --id: string # e.g. <default>
  --purge-queue: oneof<nothing, bool> # Set this value to true if you want to purge the queue. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/messaging"))
  let req_body = {"active": $active, "id": $id, "purgeQueue": $purge_queue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Enqueue a custom message
#
# POST /api/v1/organizations/{organizationId}/messaging/enqueueCustomMessage
# operationId: enqueueCustomMessage
export def "organizations-messaging-enqueue-custom-message create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Custom data in a map. You may use JSON content (e.g. x = y)
  name: string # The name of the message (organisation specific) (e.g. <event name>)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/messaging/enqueueCustomMessage"))
  let req_body = {"data": $data, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove partner
#
# DELETE /api/v1/organizations/{organizationId}/partner
# operationId: removePartnerOrganization
export def "organizations-partner delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-organization-id: string # The namespace of the partner organization to remove (e.g. org.acme)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/partner"))
  let req_body = {"organizationId": $body_organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get partners of an organization
#
# GET /api/v1/organizations/{organizationId}/partner
# operationId: getPartnerOrganizations
export def "organizations-partner get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/partner") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add partner
#
# PUT /api/v1/organizations/{organizationId}/partner
# operationId: addPartnerOrganization
export def "organizations-partner create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-organization-id: string # The namespace of the partner organization to add (e.g. org.acme)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/partner"))
  let req_body = {"organizationId": $body_organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List my privileges
#
# GET /api/v1/organizations/{organizationId}/privileges
# operationId: getOrganizationPrivileges
export def "organizations-privileges get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/privileges"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users and their roles
#
# GET /api/v1/organizations/{organizationId}/roles
# operationId: getAllOrganizationRoles
export def "organizations-roles get-list" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<roles: list, user: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/roles") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users in organization
#
# GET /api/v1/organizations/{organizationId}/users
# operationId: getUsersOfOrganization
export def "organizations-users get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<id: string, name: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/users") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite Users
#
# POST /api/v1/organizations/{organizationId}/users/invite
# operationId: inviteUsers
# --invitations item shape: {email?: string, roles: list<string>, userName?: string}
export def "organizations-users-invite create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  invitations: list # item shape: {email?: string, roles: list<string>, userName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/users/invite"))
  let req_body = {"invitations": $invitations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove role(s) from user
#
# DELETE /api/v1/organizations/{organizationId}/users/{username}/roles
# operationId: removeUserRoles
export def "organizations-users-roles delete" [
  organization_id: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --roles: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), username: (encode-path-segment $username)} | format pattern "/api/v1/organizations/{organization_id}/users/{username}/roles"))
  let req_body = {"roles": $roles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get user roles by username
#
# GET /api/v1/organizations/{organizationId}/users/{username}/roles
# operationId: getUserRoles
export def "organizations-users-roles get" [
  organization_id: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: list<string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), username: (encode-path-segment $username)} | format pattern "/api/v1/organizations/{organization_id}/users/{username}/roles") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add role(s) to user
#
# POST /api/v1/organizations/{organizationId}/users/{username}/roles
# operationId: addUserRoles
export def "organizations-users-roles create" [
  organization_id: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --roles: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), username: (encode-path-segment $username)} | format pattern "/api/v1/organizations/{organization_id}/users/{username}/roles"))
  let req_body = {"roles": $roles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List public documents
#
# GET /api/v1/public/documents/{id4n}
# operationId: listAllPublicDocuments
export def "public-documents list-list" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # organizationId
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/public/documents/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read public document contents
#
# GET /api/v1/public/documents/{id4n}/{organizationId}/{fileName}
# operationId: readPublicDocument
export def "public-documents get" [
  id4n: string
  organization_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/public/documents/{id4n}/{organization_id}/{file_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a public document (meta-data only, no content)
#
# GET /api/v1/public/documents/{id4n}/{organizationId}/{fileName}/metadata
# operationId: getPublicDocument
export def "public-documents-metadata get" [
  id4n: string
  organization_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), organization_id: (encode-path-segment $organization_id), file_name: (encode-path-segment $file_name)} | format pattern "/api/v1/public/documents/{id4n}/{organization_id}/{file_name}/metadata"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shows the public history of the given GUID
#
# GET /api/v1/public/history/{id4n}
# operationId: listPublicHistory
export def "public-history list" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/public/history/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve image
#
# GET /api/v1/public/image/{imageID}
# operationId: resolveImageUsingGET
export def "public-image get-resolve-using" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/api/v1/public/image/{image_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read public organization information
#
# GET /api/v1/public/organizations/{organizationId}
# operationId: readOrganizationInfo
export def "public-organizations get-get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, logoURL: string, name: string, namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/public/organizations/{organization_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all public routes for a GUID
#
# GET /api/v1/public/routes/{id4n}
# operationId: getRoutes
export def "public-routes get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # type (default: web)
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> table<params: record, priority: int, public: bool, type: string, validUntil: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "interpolate" $interpolate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/public/routes/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List roles
#
# GET /api/v1/roles
# operationId: listAllRoles
export def "roles list-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --privilege: string # If specified the roles will be filtered containing that privilege.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<name: string, privileges: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "privilege" $privilege "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/roles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve routing file
#
# GET /api/v1/routingfiles/{id4n}
# operationId: getRoutingFile
export def "routingfiles get-routing-file" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # organizationId
]: nothing -> record<options: record<deleteOutdatedRoutes: bool>, routes: table<params: record, priority: int, public: bool, type: string, validUntil: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/routingfiles/{id4n}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store routing file
#
# PUT /api/v1/routingfiles/{id4n}
# operationId: updateRoutingFile
# --routing shape: {options?: record, routes: list}
export def "routingfiles update-routing-file" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string
  routing: record # shape: {options?: record, routes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/routingfiles/{id4n}"))
  let req_body = {"organizationId": $organization_id, "routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve current route of a GUID (or ID4N)
#
# GET /api/v1/routingfiles/{id4n}/route/{type}
# operationId: getRoute
export def "routingfiles-route get" [
  id4n: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --private-routes: oneof<nothing, bool> # privateRoutes (default: true)
  --public-routes: oneof<nothing, bool> # publicRoutes (default: true)
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> record<params: record, priority: int, public: bool, type: string, validUntil: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "privateRoutes" $private_routes "scalar") (serialize-qp "publicRoutes" $public_routes "scalar") (serialize-qp "interpolate" $interpolate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), type: (encode-path-segment $type)} | format pattern "/api/v1/routingfiles/{id4n}/route/{type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all routes of a GUID (or ID4N)
#
# GET /api/v1/routingfiles/{id4n}/routes/{type}
# operationId: getAllRoutes
export def "routingfiles-routes get-list" [
  id4n: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --organization-id: string # organizationId
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> table<params: record, priority: int, public: bool, type: string, validUntil: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "interpolate" $interpolate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n), type: (encode-path-segment $type)} | format pattern "/api/v1/routingfiles/{id4n}/routes/{type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for GUIDs by alias
#
# GET /api/v1/search/guids
# operationId: searchByAlias
export def "search-guids list-by-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alias: string # The alias to search for
  --alias-type: string@alias-type-completer # Alias type type to search for
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "aliasType" $alias_type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/guids" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all supported alias types
#
# GET /api/v1/search/guids/aliases/types
# operationId: getGuidAliasTypes
export def "search-guids-aliases-types get-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/search/guids/aliases/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer a GUID or collection, obtaining it (i.e. becoming the holder) and if allowed also taking ownership
#
# PUT /api/v1/transfers/{id4n}/receiveInfo
# operationId: receive
export def "transfers-receive-info receive" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_id: string # Organization to take the ownership of the ID. If the sender chose to keep the ownership, this organization becomes the holder. Otherwise, it becomes the new owner. (e.g. de.id4i)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/transfers/{id4n}/receiveInfo"))
  let req_body = {"organizationId": $organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Show transfer preparation information
#
# GET /api/v1/transfers/{id4n}/sendInfo
# operationId: getSendInfo
export def "transfers-send-info get" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<holderOrganizationId: string, keepOwnership: bool, openForClaims: bool, ownerOrganizationId: string, recipientOrganizationIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/transfers/{id4n}/sendInfo"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prepare an object for transfer
#
# PUT /api/v1/transfers/{id4n}/sendInfo
# operationId: prepare
export def "transfers-send-info update-prepare" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --keep-ownership: oneof<nothing, bool> # Keep the public ownership while transferring the object (e.g. true)
  --open-for-claims: oneof<nothing, bool> # Allow anyone who knows (or can scan) the ID4N to claim ownership of this object (e.g. false)
  recipient_organization_ids: list<string> # Allow only these organizations to obtain this object (e.g. [de.acme, com.porsche, de.bluerain])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/api/v1/transfers/{id4n}/sendInfo"))
  let req_body = {"keepOwnership": $keep_ownership, "openForClaims": $open_for_claims, "recipientOrganizationIds": $recipient_organization_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve organizations of user
#
# GET /api/v1/user/organizations
# operationId: getOrganizationsOfUser
export def "user-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --role: string # role
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<id: int, logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/user/organizations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users
#
# GET /api/v1/users
# operationId: findUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --username-prefix: string
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> record<elements: table<id: string, name: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "usernamePrefix" $username_prefix "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find by username
#
# GET /api/v1/users/{username}
# operationId: findUserByUsername
export def "users find" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/api/v1/users/{username}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Forward
#
# GET /go/{guid}
# operationId: go
export def "go get" [
  guid: string
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
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/go/{guid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ID4i API Login
#
# POST /login
# operationId: login
export def "login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/login")
  let req_body = {"login": $login, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resolve owner of id4n
#
# GET /whois/{id4n}
# operationId: resolveWhoIsEntry
export def "whois get-resolve-who-is-entry" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<aliases: record, organization: record<id: int, logoURL: string, name: string, namespace: string>, organizationAddress: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id4n: (encode-path-segment $id4n)} | format pattern "/whois/{id4n}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
