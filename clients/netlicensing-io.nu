# Auto-generated client for Labs64 NetLicensing RESTful API Test Center v2.x
# Source: https://api.apis.guru/v2/specs/netlicensing.io/2.x/openapi.json
# Auth: --token flag or $env.LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN

const BASE_URL = "https://go.netlicensing.io/core/v2/rest"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN | default "" }
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

def base-url-completer [] { ["https://go.netlicensing.io/core/v2/rest"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def action-completer [] { ["checkIn" "checkOut"] }
def vatMode-completer [] { ["GROSS" "NET"] }
def action-completer-1 [] { ["licenseeLogin"] }
def apiKeyRole-completer [] { ["ROLE_APIKEY_ADMIN" "ROLE_APIKEY_ANALYTICS" "ROLE_APIKEY_LICENSEE" "ROLE_APIKEY_MAINTENANCE" "ROLE_APIKEY_OPERATION"] }
def tokenType-completer [] { ["APIKEY" "DEFAULT" "SHOP"] }
def type-completer [] { ["ACTION"] }
def source-completer [] { ["SHOP"] }
def status-completer [] { ["CANCELLED" "CLOSED" "PENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "license listLicenses" } } | get name | first)
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
export def "license listLicenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create License
#
# POST /license
# operationId: createLicense
export def "license createLicense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool>
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported. Read-only, set from License Template on creation
  --hidden: oneof<nothing, bool> # If set to 'true', this License is not shown in NetLicensing Shop as purchased License. Set from License Template on creation, if not specified explicitly
  licenseTemplateNumber: string
  licenseeNumber: string
  --name: string # Name for the Licensed item. Set from License Template on creation, if not specified explicitly.
  --number: string
  --parentfeature: string # Mandatory for 'TIMEVOLUME' License Type and 'RENTAL' licensing model
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. Read-only, set from License Template on creation (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' License Model.
  --startDate: string # Mandatory for 'TIMEVOLUME' License Type. (format: date-time)
  --timeVolume: string # Mandatory for 'TIMEVOLUME' License Type.
  --timeVolumePeriod: string # For 'TIMEVOLUME' License Type.
  --usedQuantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license")
  let body = {active: $active, currency: $currency, hidden: $hidden, licenseTemplateNumber: $licenseTemplateNumber, licenseeNumber: $licenseeNumber, name: $name, number: $number, parentfeature: $parentfeature, price: $price, quantity: $quantity, startDate: $startDate, timeVolume: $timeVolume, timeVolumePeriod: $timeVolumePeriod, usedQuantity: $usedQuantity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete License
#
# DELETE /license/{licenseNumber}
# operationId: deleteLicense
export def "license delete" [
  licenseNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/license/($licenseNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get License
#
# GET /license/{licenseNumber}
# operationId: getLicense
export def "license get" [
  licenseNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/license/($licenseNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update License
#
# POST /license/{licenseNumber}
# operationId: updateLicense
export def "license updateLicense" [
  licenseNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --startDate: string # For 'TIMEVOLUME' License type (format: date-time)
  --timeVolume: string # Mandatory for 'TIMEVOLUME' License Type.
  --timeVolumePeriod: string # For 'TIMEVOLUME' License Type.
  --usedQuantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/license/($licenseNumber)")
  let body = {active: $active, currency: $currency, hidden: $hidden, name: $name, number: $number, parentfeature: $parentfeature, price: $price, quantity: $quantity, startDate: $startDate, timeVolume: $timeVolume, timeVolumePeriod: $timeVolumePeriod, usedQuantity: $usedQuantity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Licensees
#
# GET /licensee
# operationId: listLicensees
export def "licensee listLicensees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensee")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Licensee
#
# POST /licensee
# operationId: createLicensee
export def "licensee createLicensee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --markedForTransfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Licensee. Vendor can assign this number when creating a Licensee or let NetLicensing generate one. Read-only after creation of the first License for the Licensee
  productNumber: string # 'productNumber' to assign new Licensee object
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensee")
  let body = {active: $active, markedForTransfer: $markedForTransfer, name: $name, number: $number, productNumber: $productNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Licensee
#
# DELETE /licensee/{licenseeNumber}
# operationId: deleteLicensee
export def "licensee delete" [
  licenseeNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --forceCascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceCascade" $forceCascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/licensee/($licenseeNumber)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Licensee
#
# GET /licensee/{licenseeNumber}
# operationId: getLicensee
export def "licensee get" [
  licenseeNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensee/($licenseeNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Licensee
#
# POST /licensee/{licenseeNumber}
# operationId: updateLicensee
export def "licensee updateLicensee" [
  licenseeNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --markedForTransfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # New Licensee number (update).
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensee/($licenseeNumber)")
  let body = {active: $active, markedForTransfer: $markedForTransfer, name: $name, number: $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Transfer Licenses
#
# POST /licensee/{licenseeNumber}/transfer
# operationId: transferLicenses
export def "licensee-transfer transferLicenses" [
  licenseeNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  sourceLicenseeNumber: string # Licensee number which Licenses to be transferred
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensee/($licenseeNumber)/transfer")
  let body = {sourceLicenseeNumber: $sourceLicenseeNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Validate Licensee
#
# POST /licensee/{licenseeNumber}/validate
# operationId: validateLicensee
export def "licensee-validate validateLicensee" [
  licenseeNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string@action-completer # 'Floating' licensing model: check-out or check-in session action, to allocate or return it from/to the pool of available sessions
  --licenseeName: string # Human-readable name for the auto-created Licensee (will be set as custom Licensee property)
  --nodeSecret: string # 'Node-Locked' licensing model: specifies unique secret
  --productModuleNumber: string # 'Node-Locked' licensing model: product module number
  --productNumber: string # Product number, must be provided when 'Licensee auto-create' is enabled (see also Product JavaDoc). Identifies the Product to which new Licensee should be added
  --sessionId: string # 'Floating' licensing model: specifies unique session identifier
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensee/($licenseeNumber)/validate")
  let body = {action: $action, licenseeName: $licenseeName, nodeSecret: $nodeSecret, productModuleNumber: $productModuleNumber, productNumber: $productNumber, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List License Templates
#
# GET /licensetemplate
# operationId: listLicenseTemplates
export def "licensetemplate listLicenseTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensetemplate")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create License Template
#
# POST /licensetemplate
# operationId: createLicenseTemplate
export def "licensetemplate createLicenseTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hideLicenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  licenseType: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --maxSessions: string # Mandatory for 'FLOATING' License Type.
  name: string # License Template name to create License Template object
  --number: string # Unique number (across all Products of a Vendor) that identifies the License Template. Vendor can assign this number when creating a License Template or let NetLicensing generate one. Read-only after creation of the first License from this License Template.
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  productModuleNumber: string # Number of Product Module to create License Template object
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --timeVolume: string # Mandatory for 'TIMEVOLUME' License Type.
  --timeVolumePeriod: string # For 'TIMEVOLUME' License Type.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensetemplate")
  let body = {active: $active, automatic: $automatic, currency: $currency, hidden: $hidden, hideLicenses: $hideLicenses, licenseType: $licenseType, maxSessions: $maxSessions, name: $name, number: $number, price: $price, productModuleNumber: $productModuleNumber, quantity: $quantity, quota: $quota, timeVolume: $timeVolume, timeVolumePeriod: $timeVolumePeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete License Template
#
# DELETE /licensetemplate/{licenseTemplateNumber}
# operationId: deleteLicenseTemplate
export def "licensetemplate delete" [
  licenseTemplateNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --forceCascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceCascade" $forceCascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/licensetemplate/($licenseTemplateNumber)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get License Template
#
# GET /licensetemplate/{licenseTemplateNumber}
# operationId: getLicenseTemplate
export def "licensetemplate get" [
  licenseTemplateNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensetemplate/($licenseTemplateNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update License Template
#
# POST /licensetemplate/{licenseTemplateNumber}
# operationId: updateLicenseTemplate
export def "licensetemplate updateLicenseTemplate" [
  licenseTemplateNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hideLicenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  --licenseType: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --maxSessions: string # Mandatory for 'FLOATING' License Type.
  --name: string # Name for the Licensed item
  --number: string # New License Template number (update).
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --timeVolume: string # Mandatory for 'TIMEVOLUME' License Type.
  --timeVolumePeriod: string # For 'TIMEVOLUME' License Type.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licensetemplate/($licenseTemplateNumber)")
  let body = {active: $active, automatic: $automatic, currency: $currency, hidden: $hidden, hideLicenses: $hideLicenses, licenseType: $licenseType, maxSessions: $maxSessions, name: $name, number: $number, price: $price, quantity: $quantity, quota: $quota, timeVolume: $timeVolume, timeVolumePeriod: $timeVolumePeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Payment Methods
#
# GET /paymentmethod
# operationId: listPaymentMethods
export def "paymentmethod listPaymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentmethod")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Method
#
# GET /paymentmethod/{paymentMethodNumber}
# operationId: getPaymentMethod
export def "paymentmethod get" [
  paymentMethodNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentmethod/($paymentMethodNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Payment Method
#
# POST /paymentmethod/{paymentMethodNumber}
# operationId: updatePaymentMethod
export def "paymentmethod updatePaymentMethod" [
  paymentMethodNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Payment Method is disabled.
  --paypalsubject: string # The e-mail address of the PayPal account for which you are making the API calls.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentmethod/($paymentMethodNumber)")
  let body = {active: $active, paypal.subject: $paypalsubject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Products
#
# GET /product
# operationId: listProducts
export def "product listProducts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Product
#
# POST /product
# operationId: createProduct
export def "product createProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licenseeAutoCreate: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensingInfo: string # Licensing information.
  name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # Unique number that identifies the Product. Vendor can assign this number when creating a Product or let NetLicensing generate one.
  --vatMode: string@vatMode-completer # Vat mode for Product. Supported types: GROSS, NET
  version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product")
  let body = {active: $active, description: $description, licenseeAutoCreate: $licenseeAutoCreate, licensingInfo: $licensingInfo, name: $name, number: $number, vatMode: $vatMode, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Product
#
# DELETE /product/{productNumber}
# operationId: deleteProduct
export def "product delete" [
  productNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --forceCascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceCascade" $forceCascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/product/($productNumber)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product
#
# GET /product/{productNumber}
# operationId: productNumber
export def "product productNumber" [
  productNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($productNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Product
#
# POST /product/{productNumber}
# operationId: updateProduct
export def "product updateProduct" [
  productNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licenseeAutoCreate: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensingInfo: string # Licensing information.
  --name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # New Product number (update)
  --vatMode: string@vatMode-completer # Vat mode for Product. Supported types: GROSS, NET
  --version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($productNumber)")
  let body = {active: $active, description: $description, licenseeAutoCreate: $licenseeAutoCreate, licensingInfo: $licensingInfo, name: $name, number: $number, vatMode: $vatMode, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Product Modules
#
# GET /productmodule
# operationId: listProductModules
export def "productmodule listProductModules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/productmodule")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Product Module
#
# POST /productmodule
# operationId: createProductModule
export def "productmodule createProductModule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --licenseTemplate: list # License Template. Mandatory for 'Try &amp; Buy' licensing model.
  licensingModel: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --maxCheckoutValidity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --nodeSecretMode: list # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  productNumber: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  --redThreshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellowThreshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/productmodule")
  let body = {active: $active, licenseTemplate: $licenseTemplate, licensingModel: $licensingModel, maxCheckoutValidity: $maxCheckoutValidity, name: $name, nodeSecretMode: $nodeSecretMode, number: $number, productNumber: $productNumber, redThreshold: $redThreshold, yellowThreshold: $yellowThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Product Module
#
# DELETE /productmodule/{productModuleNumber}
# operationId: deleteProductModule
export def "productmodule delete" [
  productModuleNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --forceCascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceCascade" $forceCascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/productmodule/($productModuleNumber)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Module
#
# GET /productmodule/{productModuleNumber}
# operationId: getProductModule
export def "productmodule get" [
  productModuleNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/productmodule/($productModuleNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Product Module
#
# POST /productmodule/{productModuleNumber}
# operationId: updateProductModule
export def "productmodule updateProductModule" [
  productModuleNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --licenseTemplate: list # License Template. Mandatory for 'Try &amp; Buy' licensing model.
  --licensingModel: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --maxCheckoutValidity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  --name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --nodeSecretMode: list # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # New Product Module number (update).
  --redThreshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellowThreshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/productmodule/($productModuleNumber)")
  let body = {active: $active, licenseTemplate: $licenseTemplate, licensingModel: $licensingModel, maxCheckoutValidity: $maxCheckoutValidity, name: $name, nodeSecretMode: $nodeSecretMode, number: $number, redThreshold: $redThreshold, yellowThreshold: $yellowThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Tokens
#
# GET /token
# operationId: listTokens
export def "token listTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create token
#
# POST /token
# operationId: createToken
export def "token createToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string@action-completer-1 # For <i>type=ACTION</i> only; defines token action to be perfromed
  --apiKeyRole: string@apiKeyRole-completer # For <i>tokenType=APIKEY</i> only (default: ROLE_APIKEY_LICENSEE); defines token RoleID
  --cancelURL: string # For <i>tokenType=SHOP</i> only; take customers to this URL when they cancel their checkout
  --cancelURLTitle: string # For <i>tokenType=SHOP</i> only; shop link title for cancel checkout process
  --licenseTemplateNumber: string # For <i>tokenType=SHOP</i> only; identifies LicenseTemplate that will be assigned to the shop token
  --licenseeNumber: string # For <i>tokenType=SHOP</i> or <i>type=ACTION</i> only (mandatory); identifies Licensee that will be assigned to the shop token
  --predefinedShoppingItem: string # For <i>tokenType=SHOP</i> only; identifies Shopping Item name that will be shown to the customer
  --privateKey: string # For <i>tokenType=APIKEY</i> only (optional); defines PrivateKey to be used with the validate method<br/><strong>Please Note:</strong> PrivateKey need to be provided as one line without spaces
  --productNumber: string # For <i>tokenType=SHOP</i> only (mandatory); identifies Product that will be assigned to the shop token
  --successURL: string # For <i>tokenType=SHOP</i> only; take customers to this URL when they finish checkout
  --successURLTitle: string # For <i>tokenType=SHOP</i> only; shop link title for successful checkout process
  tokenType: string@tokenType-completer # Token type to be generated
  --type: string@type-completer # For <i>tokenType=DEFAULT</i> only; action type to be set
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let body = {action: $action, apiKeyRole: $apiKeyRole, cancelURL: $cancelURL, cancelURLTitle: $cancelURLTitle, licenseTemplateNumber: $licenseTemplateNumber, licenseeNumber: $licenseeNumber, predefinedShoppingItem: $predefinedShoppingItem, privateKey: $privateKey, productNumber: $productNumber, successURL: $successURL, successURLTitle: $successURLTitle, tokenType: $tokenType, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete token
#
# DELETE /token/{tokenNumber}
# operationId: deleteToken
export def "token delete" [
  tokenNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/token/($tokenNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get token
#
# GET /token/{tokenNumber}
# operationId: getToken
export def "token get" [
  tokenNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/token/($tokenNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Transactions
#
# GET /transaction
# operationId: listTransactions
export def "transaction listTransactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Transaction
#
# POST /transaction
# operationId: createTransaction
export def "transaction createTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --dateClosed: string # format: date-time
  --dateCreated: string # format: date-time
  --licenseeNumber: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --paymentMethod: string
  --body-source: string@source-completer # AUTO Transaction for internal use only
  status: string@status-completer
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction")
  let body = {active: $active, dateClosed: $dateClosed, dateCreated: $dateCreated, licenseeNumber: $licenseeNumber, number: $number, paymentMethod: $paymentMethod, source: $body_source, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Transaction 
#
# GET /transaction/{transactionNumber}
# operationId: getTransaction
export def "transaction get" [
  transactionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transaction/($transactionNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Transaction
#
# POST /transaction/{transactionNumber}
# operationId: updateTransaction
export def "transaction updateTransaction" [
  transactionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --dateClosed: string # format: date-time
  --dateCreated: string # format: date-time
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --paymentMethod: string
  --body-source: string@source-completer # AUTO Transaction for internal use only
  --status: string@status-completer
]: any -> record<infos: any, items: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transaction/($transactionNumber)")
  let body = {active: $active, dateClosed: $dateClosed, dateCreated: $dateCreated, number: $number, paymentMethod: $paymentMethod, source: $body_source, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List License Types
#
# GET /utility/licenseTypes
# operationId: licenseTypes
export def "utility-license-types licenseTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/utility/licenseTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Licensing Models
#
# GET /utility/licensingModels
# operationId: licensingModels
export def "utility-licensing-models licensingModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<infos: any, items: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/utility/licensingModels")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
