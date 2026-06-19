# Auto-generated client for Labs64 NetLicensing RESTful API Test Center v2.x
# Source: https://api.apis.guru/v2/specs/netlicensing.io/2.x/openapi.json
# Auth: --token flag or $env.LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN

const BASE_URL = "https://go.netlicensing.io/core/v2/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://go.netlicensing.io/core/v2/rest"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def action-completer [] { ["checkIn" "checkOut"] }
def vat-mode-completer [] { ["GROSS" "NET"] }
def action-completer-1 [] { ["licenseeLogin"] }
def api-key-role-completer [] { ["ROLE_APIKEY_ADMIN" "ROLE_APIKEY_ANALYTICS" "ROLE_APIKEY_LICENSEE" "ROLE_APIKEY_MAINTENANCE" "ROLE_APIKEY_OPERATION"] }
def token-type-completer [] { ["APIKEY" "DEFAULT" "SHOP"] }
def type-completer [] { ["ACTION"] }
def source-completer [] { ["SHOP"] }
def status-completer [] { ["CANCELLED" "CLOSED" "PENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "license list" } } | get name | first)
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

# List Licenses
#
# GET /license
# operationId: listLicenses
export def "license list" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create License
#
# POST /license
# operationId: createLicense
export def "license create" [
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
  --active: oneof<nothing, bool>
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported. Read-only, set from License Template on creation
  --hidden: oneof<nothing, bool> # If set to 'true', this License is not shown in NetLicensing Shop as purchased License. Set from License Template on creation, if not specified explicitly
  license_template_number: string
  licensee_number: string
  --name: string # Name for the Licensed item. Set from License Template on creation, if not specified explicitly.
  --number: string
  --parentfeature: string # Mandatory for 'TIMEVOLUME' License Type and 'RENTAL' licensing model
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. Read-only, set from License Template on creation (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' License Model.
  --start-date: string # Mandatory for 'TIMEVOLUME' License Type. (format: date-time)
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
  --used-quantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license")
  let req_body = {"active": $active, "currency": $currency, "hidden": $hidden, "licenseTemplateNumber": $license_template_number, "licenseeNumber": $licensee_number, "name": $name, "number": $number, "parentfeature": $parentfeature, "price": $price, "quantity": $quantity, "startDate": $start_date, "timeVolume": $time_volume, "timeVolumePeriod": $time_volume_period, "usedQuantity": $used_quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete License
#
# DELETE /license/{licenseNumber}
# operationId: deleteLicense
export def "license delete" [
  license_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseNumber' must be non-empty" } }
  let full_url = (build-url $base ({license_number: (encode-path-segment $license_number)} | format pattern "/license/{license_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get License
#
# GET /license/{licenseNumber}
# operationId: getLicense
export def "license get" [
  license_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseNumber' must be non-empty" } }
  let full_url = (build-url $base ({license_number: (encode-path-segment $license_number)} | format pattern "/license/{license_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update License
#
# POST /license/{licenseNumber}
# operationId: updateLicense
export def "license update" [
  license_number: string
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
  --active: oneof<nothing, bool>
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported. Read-only, set from License Template on creation
  --hidden: oneof<nothing, bool> # If set to 'true', this License is not shown in NetLicensing Shop as purchased License. Set from License Template on creation, if not specified explicitly
  --name: string # Name for the Licensed item. Set from License Template on creation, if not specified explicitly.
  --number: string # Unique number (across all Products/Licensees of a Vendor) that identifies the License. Vendor can assign this number when creating a License or let NetLicensing generate one. Read-only after corresponding creation Transaction status is set to closed.
  --parentfeature: string
  --price: float # Price for the License. If > 0, it must always be accompanied by the currency specification. Read-only, set from License Template on creation (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' License Model.
  --start-date: string # For 'TIMEVOLUME' License type (format: date-time)
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
  --used-quantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseNumber' must be non-empty" } }
  let full_url = (build-url $base ({license_number: (encode-path-segment $license_number)} | format pattern "/license/{license_number}"))
  let req_body = {"active": $active, "currency": $currency, "hidden": $hidden, "name": $name, "number": $number, "parentfeature": $parentfeature, "price": $price, "quantity": $quantity, "startDate": $start_date, "timeVolume": $time_volume, "timeVolumePeriod": $time_volume_period, "usedQuantity": $used_quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Licensees
#
# GET /licensee
# operationId: listLicensees
export def "licensee list" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensee")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Licensee
#
# POST /licensee
# operationId: createLicensee
export def "licensee create" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --marked-for-transfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Licensee. Vendor can assign this number when creating a Licensee or let NetLicensing generate one. Read-only after creation of the first License for the Licensee
  product_number: string # 'productNumber' to assign new Licensee object
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensee")
  let req_body = {"active": $active, "markedForTransfer": $marked_for_transfer, "name": $name, "number": $number, "productNumber": $product_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete Licensee
#
# DELETE /licensee/{licenseeNumber}
# operationId: deleteLicensee
export def "licensee delete" [
  licensee_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($licensee_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseeNumber' must be non-empty" } }
  let qp = [(serialize-qp "forceCascade" $force_cascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({licensee_number: (encode-path-segment $licensee_number)} | format pattern "/licensee/{licensee_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"forceCascade": $force_cascade} | compact), body: null}
}

# Get Licensee
#
# GET /licensee/{licenseeNumber}
# operationId: getLicensee
export def "licensee get" [
  licensee_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($licensee_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseeNumber' must be non-empty" } }
  let full_url = (build-url $base ({licensee_number: (encode-path-segment $licensee_number)} | format pattern "/licensee/{licensee_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Licensee
#
# POST /licensee/{licenseeNumber}
# operationId: updateLicensee
export def "licensee update" [
  licensee_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --marked-for-transfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # New Licensee number (update).
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($licensee_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseeNumber' must be non-empty" } }
  let full_url = (build-url $base ({licensee_number: (encode-path-segment $licensee_number)} | format pattern "/licensee/{licensee_number}"))
  let req_body = {"active": $active, "markedForTransfer": $marked_for_transfer, "name": $name, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Transfer Licenses
#
# POST /licensee/{licenseeNumber}/transfer
# operationId: transferLicenses
export def "licensee-transfer create-licenses" [
  licensee_number: string
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
  source_licensee_number: string # Licensee number which Licenses to be transferred
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($licensee_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseeNumber' must be non-empty" } }
  let full_url = (build-url $base ({licensee_number: (encode-path-segment $licensee_number)} | format pattern "/licensee/{licensee_number}/transfer"))
  let req_body = {"sourceLicenseeNumber": $source_licensee_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Validate Licensee
#
# POST /licensee/{licenseeNumber}/validate
# operationId: validateLicensee
export def "licensee-validate validate" [
  licensee_number: string
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
  --action: string@action-completer # 'Floating' licensing model: check-out or check-in session action, to allocate or return it from/to the pool of available sessions
  --licensee-name: string # Human-readable name for the auto-created Licensee (will be set as custom Licensee property)
  --node-secret: string # 'Node-Locked' licensing model: specifies unique secret
  --product-module-number: string # 'Node-Locked' licensing model: product module number
  --product-number: string # Product number, must be provided when 'Licensee auto-create' is enabled (see also Product JavaDoc). Identifies the Product to which new Licensee should be added
  --session-id: string # 'Floating' licensing model: specifies unique session identifier
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($licensee_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseeNumber' must be non-empty" } }
  let full_url = (build-url $base ({licensee_number: (encode-path-segment $licensee_number)} | format pattern "/licensee/{licensee_number}/validate"))
  let req_body = {"action": $action, "licenseeName": $licensee_name, "nodeSecret": $node_secret, "productModuleNumber": $product_module_number, "productNumber": $product_number, "sessionId": $session_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List License Templates
#
# GET /licensetemplate
# operationId: listLicenseTemplates
export def "licensetemplate list-license-templates" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensetemplate")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create License Template
#
# POST /licensetemplate
# operationId: createLicenseTemplate
export def "licensetemplate create-license-template" [
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
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hide-licenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  license_type: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --max-sessions: string # Mandatory for 'FLOATING' License Type.
  name: string # License Template name to create License Template object
  --number: string # Unique number (across all Products of a Vendor) that identifies the License Template. Vendor can assign this number when creating a License Template or let NetLicensing generate one. Read-only after creation of the first License from this License Template.
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  product_module_number: string # Number of Product Module to create License Template object
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensetemplate")
  let req_body = {"active": $active, "automatic": $automatic, "currency": $currency, "hidden": $hidden, "hideLicenses": $hide_licenses, "licenseType": $license_type, "maxSessions": $max_sessions, "name": $name, "number": $number, "price": $price, "productModuleNumber": $product_module_number, "quantity": $quantity, "quota": $quota, "timeVolume": $time_volume, "timeVolumePeriod": $time_volume_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete License Template
#
# DELETE /licensetemplate/{licenseTemplateNumber}
# operationId: deleteLicenseTemplate
export def "licensetemplate delete-license-template" [
  license_template_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_template_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseTemplateNumber' must be non-empty" } }
  let qp = [(serialize-qp "forceCascade" $force_cascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({license_template_number: (encode-path-segment $license_template_number)} | format pattern "/licensetemplate/{license_template_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"forceCascade": $force_cascade} | compact), body: null}
}

# Get License Template
#
# GET /licensetemplate/{licenseTemplateNumber}
# operationId: getLicenseTemplate
export def "licensetemplate get-license-template" [
  license_template_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_template_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseTemplateNumber' must be non-empty" } }
  let full_url = (build-url $base ({license_template_number: (encode-path-segment $license_template_number)} | format pattern "/licensetemplate/{license_template_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update License Template
#
# POST /licensetemplate/{licenseTemplateNumber}
# operationId: updateLicenseTemplate
export def "licensetemplate update-license-template" [
  license_template_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hide-licenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  --license-type: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --max-sessions: string # Mandatory for 'FLOATING' License Type.
  --name: string # Name for the Licensed item
  --number: string # New License Template number (update).
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($license_template_number | is-empty) { error make --unspanned { msg: "path parameter 'licenseTemplateNumber' must be non-empty" } }
  let full_url = (build-url $base ({license_template_number: (encode-path-segment $license_template_number)} | format pattern "/licensetemplate/{license_template_number}"))
  let req_body = {"active": $active, "automatic": $automatic, "currency": $currency, "hidden": $hidden, "hideLicenses": $hide_licenses, "licenseType": $license_type, "maxSessions": $max_sessions, "name": $name, "number": $number, "price": $price, "quantity": $quantity, "quota": $quota, "timeVolume": $time_volume, "timeVolumePeriod": $time_volume_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Payment Methods
#
# GET /paymentmethod
# operationId: listPaymentMethods
export def "paymentmethod list-payment-methods" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentmethod")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Method
#
# GET /paymentmethod/{paymentMethodNumber}
# operationId: getPaymentMethod
export def "paymentmethod get-payment-method" [
  payment_method_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_method_number | is-empty) { error make --unspanned { msg: "path parameter 'paymentMethodNumber' must be non-empty" } }
  let full_url = (build-url $base ({payment_method_number: (encode-path-segment $payment_method_number)} | format pattern "/paymentmethod/{payment_method_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Payment Method
#
# POST /paymentmethod/{paymentMethodNumber}
# operationId: updatePaymentMethod
export def "paymentmethod update-payment-method" [
  payment_method_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Payment Method is disabled.
  --paypal-subject: string # The e-mail address of the PayPal account for which you are making the API calls.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_method_number | is-empty) { error make --unspanned { msg: "path parameter 'paymentMethodNumber' must be non-empty" } }
  let full_url = (build-url $base ({payment_method_number: (encode-path-segment $payment_method_number)} | format pattern "/paymentmethod/{payment_method_number}"))
  let req_body = {"active": $active, "paypal.subject": $paypal_subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Products
#
# GET /product
# operationId: listProducts
export def "product list" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Product
#
# POST /product
# operationId: createProduct
export def "product create" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licensee-auto-create: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensing-info: string # Licensing information.
  name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # Unique number that identifies the Product. Vendor can assign this number when creating a Product or let NetLicensing generate one.
  --vat-mode: string@vat-mode-completer # Vat mode for Product. Supported types: GROSS, NET
  version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product")
  let req_body = {"active": $active, "description": $description, "licenseeAutoCreate": $licensee_auto_create, "licensingInfo": $licensing_info, "name": $name, "number": $number, "vatMode": $vat_mode, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete Product
#
# DELETE /product/{productNumber}
# operationId: deleteProduct
export def "product delete" [
  product_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_number | is-empty) { error make --unspanned { msg: "path parameter 'productNumber' must be non-empty" } }
  let qp = [(serialize-qp "forceCascade" $force_cascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_number: (encode-path-segment $product_number)} | format pattern "/product/{product_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"forceCascade": $force_cascade} | compact), body: null}
}

# Get Product
#
# GET /product/{productNumber}
# operationId: productNumber
export def "product get-number" [
  product_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_number | is-empty) { error make --unspanned { msg: "path parameter 'productNumber' must be non-empty" } }
  let full_url = (build-url $base ({product_number: (encode-path-segment $product_number)} | format pattern "/product/{product_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Product
#
# POST /product/{productNumber}
# operationId: updateProduct
export def "product update" [
  product_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licensee-auto-create: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensing-info: string # Licensing information.
  --name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # New Product number (update)
  --vat-mode: string@vat-mode-completer # Vat mode for Product. Supported types: GROSS, NET
  --version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_number | is-empty) { error make --unspanned { msg: "path parameter 'productNumber' must be non-empty" } }
  let full_url = (build-url $base ({product_number: (encode-path-segment $product_number)} | format pattern "/product/{product_number}"))
  let req_body = {"active": $active, "description": $description, "licenseeAutoCreate": $licensee_auto_create, "licensingInfo": $licensing_info, "name": $name, "number": $number, "vatMode": $vat_mode, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Product Modules
#
# GET /productmodule
# operationId: listProductModules
export def "productmodule list-product-modules" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/productmodule")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Product Module
#
# POST /productmodule
# operationId: createProductModule
export def "productmodule create-product-module" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --license-template: list<string> # License Template. Mandatory for 'Try & Buy' licensing model.
  licensing_model: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --max-checkout-validity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --node-secret-mode: list<string> # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  product_number: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  --red-threshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellow-threshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/productmodule")
  let req_body = {"active": $active, "licenseTemplate": $license_template, "licensingModel": $licensing_model, "maxCheckoutValidity": $max_checkout_validity, "name": $name, "nodeSecretMode": $node_secret_mode, "number": $number, "productNumber": $product_number, "redThreshold": $red_threshold, "yellowThreshold": $yellow_threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete Product Module
#
# DELETE /productmodule/{productModuleNumber}
# operationId: deleteProductModule
export def "productmodule delete-product-module" [
  product_module_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_module_number | is-empty) { error make --unspanned { msg: "path parameter 'productModuleNumber' must be non-empty" } }
  let qp = [(serialize-qp "forceCascade" $force_cascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_module_number: (encode-path-segment $product_module_number)} | format pattern "/productmodule/{product_module_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"forceCascade": $force_cascade} | compact), body: null}
}

# Get Product Module
#
# GET /productmodule/{productModuleNumber}
# operationId: getProductModule
export def "productmodule get-product-module" [
  product_module_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_module_number | is-empty) { error make --unspanned { msg: "path parameter 'productModuleNumber' must be non-empty" } }
  let full_url = (build-url $base ({product_module_number: (encode-path-segment $product_module_number)} | format pattern "/productmodule/{product_module_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Product Module
#
# POST /productmodule/{productModuleNumber}
# operationId: updateProductModule
export def "productmodule update-product-module" [
  product_module_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --license-template: list<string> # License Template. Mandatory for 'Try & Buy' licensing model.
  --licensing-model: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --max-checkout-validity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  --name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --node-secret-mode: list<string> # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # New Product Module number (update).
  --red-threshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellow-threshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($product_module_number | is-empty) { error make --unspanned { msg: "path parameter 'productModuleNumber' must be non-empty" } }
  let full_url = (build-url $base ({product_module_number: (encode-path-segment $product_module_number)} | format pattern "/productmodule/{product_module_number}"))
  let req_body = {"active": $active, "licenseTemplate": $license_template, "licensingModel": $licensing_model, "maxCheckoutValidity": $max_checkout_validity, "name": $name, "nodeSecretMode": $node_secret_mode, "number": $number, "redThreshold": $red_threshold, "yellowThreshold": $yellow_threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Tokens
#
# GET /token
# operationId: listTokens
export def "token list" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create token
#
# POST /token
# operationId: createToken
export def "token create" [
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
  --action: string@action-completer-1 # For type=ACTION only; defines token action to be perfromed
  --api-key-role: string@api-key-role-completer # For tokenType=APIKEY only (default: ROLE_APIKEY_LICENSEE); defines token RoleID
  --cancel-url: string # For tokenType=SHOP only; take customers to this URL when they cancel their checkout
  --cancel-url-title: string # For tokenType=SHOP only; shop link title for cancel checkout process
  --license-template-number: string # For tokenType=SHOP only; identifies LicenseTemplate that will be assigned to the shop token
  --licensee-number: string # For tokenType=SHOP or type=ACTION only (mandatory); identifies Licensee that will be assigned to the shop token
  --predefined-shopping-item: string # For tokenType=SHOP only; identifies Shopping Item name that will be shown to the customer
  --private-key: string # For tokenType=APIKEY only (optional); defines PrivateKey to be used with the validate methodPlease Note: PrivateKey need to be provided as one line without spaces
  --product-number: string # For tokenType=SHOP only (mandatory); identifies Product that will be assigned to the shop token
  --success-url: string # For tokenType=SHOP only; take customers to this URL when they finish checkout
  --success-url-title: string # For tokenType=SHOP only; shop link title for successful checkout process
  token_type: string@token-type-completer # Token type to be generated
  --type: string@type-completer # For tokenType=DEFAULT only; action type to be set
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let req_body = {"action": $action, "apiKeyRole": $api_key_role, "cancelURL": $cancel_url, "cancelURLTitle": $cancel_url_title, "licenseTemplateNumber": $license_template_number, "licenseeNumber": $licensee_number, "predefinedShoppingItem": $predefined_shopping_item, "privateKey": $private_key, "productNumber": $product_number, "successURL": $success_url, "successURLTitle": $success_url_title, "tokenType": $token_type, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete token
#
# DELETE /token/{tokenNumber}
# operationId: deleteToken
export def "token delete" [
  token_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($token_number | is-empty) { error make --unspanned { msg: "path parameter 'tokenNumber' must be non-empty" } }
  let full_url = (build-url $base ({token_number: (encode-path-segment $token_number)} | format pattern "/token/{token_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get token
#
# GET /token/{tokenNumber}
# operationId: getToken
export def "token get" [
  token_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($token_number | is-empty) { error make --unspanned { msg: "path parameter 'tokenNumber' must be non-empty" } }
  let full_url = (build-url $base ({token_number: (encode-path-segment $token_number)} | format pattern "/token/{token_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Transactions
#
# GET /transaction
# operationId: listTransactions
export def "transaction list" [
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
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Transaction
#
# POST /transaction
# operationId: createTransaction
export def "transaction create" [
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
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --date-closed: string # format: date-time
  --date-created: string # format: date-time
  --licensee-number: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --payment-method: string
  --body-source: string@source-completer # AUTO Transaction for internal use only
  status: string@status-completer
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction")
  let req_body = {"active": $active, "dateClosed": $date_closed, "dateCreated": $date_created, "licenseeNumber": $licensee_number, "number": $number, "paymentMethod": $payment_method, "source": $body_source, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get Transaction
#
# GET /transaction/{transactionNumber}
# operationId: getTransaction
export def "transaction get" [
  transaction_number: string
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_number | is-empty) { error make --unspanned { msg: "path parameter 'transactionNumber' must be non-empty" } }
  let full_url = (build-url $base ({transaction_number: (encode-path-segment $transaction_number)} | format pattern "/transaction/{transaction_number}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Transaction
#
# POST /transaction/{transactionNumber}
# operationId: updateTransaction
export def "transaction update" [
  transaction_number: string
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
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --date-closed: string # format: date-time
  --date-created: string # format: date-time
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --payment-method: string
  --body-source: string@source-completer # AUTO Transaction for internal use only
  --status: string@status-completer
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_number | is-empty) { error make --unspanned { msg: "path parameter 'transactionNumber' must be non-empty" } }
  let full_url = (build-url $base ({transaction_number: (encode-path-segment $transaction_number)} | format pattern "/transaction/{transaction_number}"))
  let req_body = {"active": $active, "dateClosed": $date_closed, "dateCreated": $date_created, "number": $number, "paymentMethod": $payment_method, "source": $body_source, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List License Types
#
# GET /utility/licenseTypes
# operationId: licenseTypes
export def "utility-license-types get" [
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/utility/licenseTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Licensing Models
#
# GET /utility/licensingModels
# operationId: licensingModels
export def "utility-licensing-models get" [
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
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/utility/licensingModels")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
