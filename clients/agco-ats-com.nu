# Auto-generated client for AGCO API vv1
# Source: https://api.apis.guru/v2/specs/agco-ats.com/v1/openapi.json
# Auth: --token flag or $env.AGCO_API_TOKEN

const BASE_URL = "https://secure.agco-ats.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGCO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://secure.agco-ats.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def State-completer [] { ["Active" "Damaged" "Inactive"] }
def State-completer-1 [] { ["Active" "Inactive" "None"] }
def BearerAction-completer [] { ["Disable" "None" "Reset"] }
def MACAction-completer [] { ["Disable" "None" "Reset"] }
def DurationUnits-completer [] { ["Days" "Hours" "Minutes" "Weeks"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def State-completer-2 [] { ["Available" "Created" "Removed"] }
def LicenseActivationType-completer [] { ["EDT" "EDTLite"] }
def Status-completer [] { ["Active" "All" "Inactive"] }
def SubscriptionType-completer [] { ["ExcludeByDefault" "IncludeByDefault" "Required"] }
def DataRequired-completer [] { ["No" "Optional" "Yes"] }
def Status-completer-1 [] { ["Active" "All" "Completed"] }
def SubscriptionTypeFilter-completer [] { ["All" "Default" "RequiredOnly"] }
def State-completer-3 [] { ["CreatePending" "Invalidated" "Original" "Processed" "Processing" "RequestPending" "Requested" "Validated"] }
def State-completer-4 [] { ["Cancelled" "Completed" "NotSubmitted" "Submitted"] }
def state-completer [] { ["Cancelled" "Completed" "OutForProcessing" "OutForTranslation" "PendingApproval" "Processing"] }
def State-completer-5 [] { ["Cancelled" "Completed" "OutForProcessing" "OutForTranslation" "PendingApproval" "Processing"] }
def Type-completer [] { ["Commercial" "Internal" "RightToRepair" "Temporary"] }
def Deleted-completer [] { ["All" "Deleted" "NotDeleted"] }
def status-completer [] { ["Cancelled" "Failed" "InProgress" "Ready" "Succeeded"] }
def Status-completer-2 [] { ["Cancelled" "Failed" "InProgress" "Ready" "Succeeded"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aftermarket-services-certificates GetCerts" } } | get name | first)
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

# No Documentation Found.
#
# GET /api/v2/AftermarketServices/Certificates
# operationId: AftermarketServices_GetCerts
export def "aftermarket-services-certificates GetCerts" [
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
  let full_url = (build-url $base "/api/v2/AftermarketServices/Certificates")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate or Deactivate an ECU, or Report an ECU as Damaged.
#
# PUT /api/v2/AftermarketServices/ECUs/{serialNumber}
# operationId: AftermarketServices_PutECU
export def "aftermarket-services-ec-us PutECU" [
  serialNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EDTInstanceId: string # The EDT Instance Id of the kit calling this method.
  --ActivationCode: string # The code used to activate the ECU. May not be modified. Returned only on activation. (format: byte)
  --DamagedDescription: string # A description why the ECU cannot be deactivated.
  EngineSerialNumber: string # The serial number of the ECU’s engine
  --ReplacesECUSerialNumber: string # The serial number of the ECU that this ECU replaces. Required if activating an ECU..
  SerialNumber: string # The serial number of the ECU
  State: string@State-completer # The state of the ECU
]: any -> record<ActivationCode: string, DamagedDescription: string, EngineSerialNumber: string, ReplacesECUSerialNumber: string, SerialNumber: string, State: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EDTInstanceId" $EDTInstanceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/AftermarketServices/ECUs/($serialNumber)" $qp)
  let body = {ActivationCode: $ActivationCode, DamagedDescription: $DamagedDescription, EngineSerialNumber: $EngineSerialNumber, ReplacesECUSerialNumber: $ReplacesECUSerialNumber, SerialNumber: $SerialNumber, State: $State} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get injector codes given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# operationId: AftermarketServices_GetEngineIQACodes
export def "aftermarket-services-engines-iqa-codes GetEngineIQACodes" [
  serialNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EDTInstanceId: string # The EDT Instance Id of the kit calling this method.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EDTInstanceId" $EDTInstanceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/AftermarketServices/Engines/($serialNumber)/IQACodes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report the IQA codes used by an engine
#
# PUT /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# operationId: AftermarketServices_PutIQACodes
export def "aftermarket-services-engines-iqa-codes PutIQACodes" [
  serialNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EDTInstanceId: string # The EDT Instance Id of the kit calling this method.
  --body: record
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EDTInstanceId" $EDTInstanceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/AftermarketServices/Engines/($serialNumber)/IQACodes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get production calibration data for given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/ProductionData
# operationId: AftermarketServices_GetProductionData
export def "aftermarket-services-engines-production-data GetProductionData" [
  serialNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EDTInstanceId: string # The EDT Instance Id of the kit calling this method.
]: nothing -> table<DataType: string, DataValues: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EDTInstanceId" $EDTInstanceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/AftermarketServices/Engines/($serialNumber)/ProductionData" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check whether there is connectivity to AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/Hello
# operationId: AftermarketServices_GetConnectionStatus
export def "aftermarket-services-hello GetConnectionStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AftermarketServices/Hello")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the status of an EDT Kit Registration with AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/UserStatuses
# operationId: AftermarketServices_GetUserStatus
export def "aftermarket-services-user-statuses GetUserStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voucherCode: string
  --dealerCode: string
]: nothing -> record<DealerCode: string, State: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "voucherCode" $voucherCode "scalar") (serialize-qp "dealerCode" $dealerCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AftermarketServices/UserStatuses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of an EDT Kit Registration with AGCO Power Web Services
#
# PUT /api/v2/AftermarketServices/UserStatuses
# operationId: AftermarketServices_UpdateUserStatus
export def "aftermarket-services-user-statuses UpdateUserStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  DealerCode: string # The dealer code of the voucher
  --State: string@State-completer-1 # The state of the voucher
  VoucherCode: string # The voucher code
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AftermarketServices/UserStatuses")
  let body = {DealerCode: $DealerCode, State: $State, VoucherCode: $VoucherCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manage API tokens.
#
# PUT /api/v2/AuthenticatedUsers/{UserID}/Tokens
# operationId: Authentication_PutManageTokens
export def "authenticated-users-tokens PutManageTokens" [
  UserID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BearerAction: string@BearerAction-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --MACAction: string@MACAction-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthenticatedUsers/($UserID)/Tokens")
  let body = {BearerAction: $BearerAction, MACAction: $MACAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authenticate a user.
#
# POST /api/v2/Authentication
# operationId: Authentication_Default
export def "authentication Default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BearerAction: string@BearerAction-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --MACAction: string@MACAction-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
  password: string # A secret word or phrase that must be used to gain admission
  username: string # A unique ID a user needs to login with
]: any -> record<Email: string, MACId: string, MACToken: string, Name: string, Token: string, UserID: int, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication")
  let body = {BearerAction: $BearerAction, MACAction: $MACAction, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Acknowledges the connection to the API
#
# GET /api/v2/Authentication/IsAlive
# operationId: Authentication_IsAlive
export def "authentication-is-alive IsAlive" [
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
  let full_url = (build-url $base "/api/v2/Authentication/IsAlive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a password reset.
#
# POST /api/v2/Authentication/RequestPasswordReset
# operationId: Authentication_RequestPasswordReset
export def "authentication-request-password-reset RequestPasswordReset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ParameterName: string # The query string parameter name to use for supplying the password reset token
  Url: string # The URL to direct the user to reset the password.
  Username: string # The username to reset the password for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication/RequestPasswordReset")
  let body = {ParameterName: $ParameterName, Url: $Url, Username: $Username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset a password
#
# POST /api/v2/Authentication/ResetPasword
# operationId: Authentication_ResetPasword
export def "authentication-reset-pasword ResetPasword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  NewPassword: string # The new password
  Token: string # The password reset token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication/ResetPasword")
  let body = {NewPassword: $NewPassword, Token: $Token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get authorization categories.
#
# GET /api/v2/AuthorizationCategories
# operationId: AuthorizationCategories_Get
export def "authorization-categories Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --userID: int # Optional. Filter by categories visible to the provided user with the provided userID. (format: int32)
  --definitionID: string # Optional. Filter by categories containing a definition with the provided ID.
]: nothing -> record<Entities: table<Description: string, ID: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar") (serialize-qp "definitionID" $definitionID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCategories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an authorization category.
#
# POST /api/v2/AuthorizationCategories
# operationId: AuthorizationCategories_Post
export def "authorization-categories Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Description: string # A description of the Category.
  --ID: string # The ID of the Category.
  --Name: string # The Name of the Category.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCategories")
  let body = {Description: $Description, ID: $ID, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a report of access that users have to Authorization Categories.
#
# GET /api/v2/AuthorizationCategories/Users
# operationId: AuthorizationCategories_GetUsers
export def "authorization-categories-users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. Defaults to 10. (format: int32)
  --offset: int # Optional. Defaults to 0. (format: int32)
  --userIDs: string # Optional. Includes only users with IDs on the provided comma-separated list.
  --categoryIDs: string # Optional. Includes only users with categories with IDs on the provided comma-separated list.
  --includeCategories: oneof<nothing, bool> # If true, include full Authorization Category detail. Defaults to false.
  --includeUsers: oneof<nothing, bool> # If true, include full User detail. Defaults to false.
  --userSearch: string # Optional. Includes only users with a Name, Username, or Email containing the provided value.
]: nothing -> record<Entities: table<Categories: list, User: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userIDs" $userIDs "scalar") (serialize-qp "categoryIDs" $categoryIDs "scalar") (serialize-qp "includeCategories" $includeCategories "scalar") (serialize-qp "includeUsers" $includeUsers "scalar") (serialize-qp "userSearch" $userSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCategories/Users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an authorization category.
#
# DELETE /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Delete
export def "authorization-categories Delete" [
  id: string
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCategories/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authorization category.
#
# PUT /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Put
export def "authorization-categories Put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Description: string # A description of the Category.
  --ID: string # The ID of the Category.
  --Name: string # The Name of the Category.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCategories/($id)")
  let body = {Description: $Description, ID: $ID, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a category a user could see.
#
# DELETE /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_RemoveUser
export def "authorization-categories-users RemoveUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCategories/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a category that a user can see.
#
# POST /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_AddUser
export def "authorization-categories-users AddUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCategories/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authorization code definitions.
#
# GET /api/v2/AuthorizationCodeDefinitions
# operationId: AuthorizationCodeDefinitions_GetAuthorizationCodeDefinition
export def "authorization-code-definitions GetAuthorizationCodeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. If specified, filters definitions by name. Starting and ending wildcards (*) supported.
  --createdByUserID: int # Optional. If specified, filters definitions to those created by the given User ID. (format: int32)
  --deletedByUserID: int # Optional. If specified, filters definitions to those deleted by the given User ID. (format: int32)
  --includeDeleted: oneof<nothing, bool> # Optional. Whether to include deleted definitions. 'False' by default.
  --categoryID: string # Optional. If specified, filters definitions with the designated categoryID.
]: nothing -> record<Entities: table<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: list, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "createdByUserID" $createdByUserID "scalar") (serialize-qp "deletedByUserID" $deletedByUserID "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "categoryID" $categoryID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCodeDefinitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an authorization code definition.
#
# POST /api/v2/AuthorizationCodeDefinitions
# operationId: AuthorizationCodeDefinitions_PostAuthorizationCodeDefinition
# --DataFields item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
# --ValidationFields item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
export def "authorization-code-definitions PostAuthorizationCodeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AuthorizationID: string # The value used for securing codes generated.
  --CreatedByUserID: int # The ID of the user that created this definition. Read only. (format: int32)
  --CreatedDate: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --DataFields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --DeletedByUserID: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --DeletedDate: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --Description: string # A description of this definition. May not be updated.
  --DurationAccuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --DurationAmount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --DurationUnits: string@DurationUnits-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --HashLength: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --ID: string # The ID of the authorization code definition. Read only.
  --IsDeleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  Name: string # The name of the authorization code definition. May not be updated.
  --RandomLength: int # The bit length of random data which will be included in the authorization code.  This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --ValidationFields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCodeDefinitions")
  let body = {AuthorizationID: $AuthorizationID, CreatedByUserID: $CreatedByUserID, CreatedDate: $CreatedDate, DataFields: $DataFields, DeletedByUserID: $DeletedByUserID, DeletedDate: $DeletedDate, Description: $Description, DurationAccuracy: $DurationAccuracy, DurationAmount: $DurationAmount, DurationUnits: $DurationUnits, HashLength: $HashLength, ID: $ID, IsDeleted: $IsDeleted, Name: $Name, RandomLength: $RandomLength, ValidationFields: $ValidationFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the category from the authorization code definition.
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_RemoveCategoryFromDefinition
export def "authorization-code-definitions-categories RemoveCategoryFromDefinition" [
  ID: string
  categoryID: string
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCodeDefinitions/($ID)/Categories/($categoryID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a category to an authorizationCodeDefintion.
#
# POST /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_AddCategoryToDefinition
export def "authorization-code-definitions-categories AddCategoryToDefinition" [
  ID: string
  categoryID: string
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCodeDefinitions/($ID)/Categories/($categoryID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable an authorization code definition
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_DeleteAuthorizationCodeDefinition
export def "authorization-code-definitions DeleteAuthorizationCodeDefinition" [
  id: string
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
  let full_url = (build-url $base $"/api/v2/AuthorizationCodeDefinitions/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an authorization code definition by its ID
#
# GET /api/v2/AuthorizationCodeDefinitions/{id}
export def "authorization-code-definitions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: table<DigitsPrecision: int, MaxExponent: int, MaxValue: float, MinExponent: int, MinValue: float, Name: string, ScaleFactor: float, Signed: bool, Type: string>, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: table<Name: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodeDefinitions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authorization code definition
#
# PUT /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_PutAuthorizationCodeDefinition
# --DataFields item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
# --ValidationFields item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
export def "authorization-code-definitions PutAuthorizationCodeDefinition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AuthorizationID: string # The value used for securing codes generated.
  --CreatedByUserID: int # The ID of the user that created this definition. Read only. (format: int32)
  --CreatedDate: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --DataFields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --DeletedByUserID: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --DeletedDate: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --Description: string # A description of this definition. May not be updated.
  --DurationAccuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --DurationAmount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --DurationUnits: string@DurationUnits-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --HashLength: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --ID: string # The ID of the authorization code definition. Read only.
  --IsDeleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  Name: string # The name of the authorization code definition. May not be updated.
  --RandomLength: int # The bit length of random data which will be included in the authorization code.  This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --ValidationFields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodeDefinitions/($id)")
  let body = {AuthorizationID: $AuthorizationID, CreatedByUserID: $CreatedByUserID, CreatedDate: $CreatedDate, DataFields: $DataFields, DeletedByUserID: $DeletedByUserID, DeletedDate: $DeletedDate, Description: $Description, DurationAccuracy: $DurationAccuracy, DurationAmount: $DurationAmount, DurationUnits: $DurationUnits, HashLength: $HashLength, ID: $ID, IsDeleted: $IsDeleted, Name: $Name, RandomLength: $RandomLength, ValidationFields: $ValidationFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get authorization codes.
#
# GET /api/v2/AuthorizationCodes
# operationId: AuthorizationCodes_GetAuthorizationCodes
export def "authorization-codes GetAuthorizationCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string # Optional. If provided, searches for entities with the provided authorization code.
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --definitionID: string # Optional. If specified, filters codes by definition id.
  --createdByUserID: int # Optional. If specified, filters codes to those created by the given User ID. (format: int32)
  --deletedByUserID: int # Optional. If specified, filters codes to those deleted by the given User ID. (format: int32)
  --includeDeleted: oneof<nothing, bool> # Optional. Whether to include deleted codes. 'False' by default.
]: nothing -> record<Entities: table<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: list, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "definitionID" $definitionID "scalar") (serialize-qp "createdByUserID" $createdByUserID "scalar") (serialize-qp "deletedByUserID" $deletedByUserID "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCodes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates an authorization code using the provided definition and parameters.
#
# POST /api/v2/AuthorizationCodes
# operationId: AuthorizationCodes_PostAuthorizationCode
# --DataParameters item shape: {Name: string, Value: string}
# --ValidationParameters item shape: {Name: string, Value: string}
export def "authorization-codes PostAuthorizationCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Code: string # The code to enter to unlock a feature. Read only.
  --CreatedByUserID: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --CreatedDate: string # A timestamp of when this code was created. Read only. (format: date-time)
  --DataParameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --DefinitionID: string # The id of the definition for this authorization code. May not be updated.
  --DeletedByUserID: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --DeletedDate: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --EffectiveDate: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --ID: int # The identifier for the authorization code. Read only. (format: int32)
  --IsDeleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --ValidationParameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCodes")
  let body = {Code: $Code, CreatedByUserID: $CreatedByUserID, CreatedDate: $CreatedDate, DataParameters: $DataParameters, DefinitionID: $DefinitionID, DeletedByUserID: $DeletedByUserID, DeletedDate: $DeletedDate, EffectiveDate: $EffectiveDate, ID: $ID, IsDeleted: $IsDeleted, ValidationParameters: $ValidationParameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Hide an authorization code.
#
# DELETE /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_DeleteAuthorizationCode
export def "authorization-codes DeleteAuthorizationCode" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodes/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an authorization code by its ID.
#
# GET /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_GetAuthorizationCode
export def "authorization-codes GetAuthorizationCode" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: table<Name: string, Value: string>, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: table<Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodes/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authorization code.
#
# PUT /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_PutAuthorizationCode
# --DataParameters item shape: {Name: string, Value: string}
# --ValidationParameters item shape: {Name: string, Value: string}
export def "authorization-codes PutAuthorizationCode" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Code: string # The code to enter to unlock a feature. Read only.
  --CreatedByUserID: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --CreatedDate: string # A timestamp of when this code was created. Read only. (format: date-time)
  --DataParameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --DefinitionID: string # The id of the definition for this authorization code. May not be updated.
  --DeletedByUserID: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --DeletedDate: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --EffectiveDate: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --ID: int # The identifier for the authorization code. Read only. (format: int32)
  --IsDeleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --ValidationParameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodes/($id)")
  let body = {Code: $Code, CreatedByUserID: $CreatedByUserID, CreatedDate: $CreatedDate, DataParameters: $DataParameters, DefinitionID: $DefinitionID, DeletedByUserID: $DeletedByUserID, DeletedDate: $DeletedDate, EffectiveDate: $EffectiveDate, ID: $ID, IsDeleted: $IsDeleted, ValidationParameters: $ValidationParameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get contact information for an authorization code.
#
# GET /api/v2/AuthorizationCodes/{id}/ContactInformation
# operationId: AuthorizationCodes_GetContactInformation
export def "authorization-codes-contact-information GetContactInformation" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodes/($id)/ContactInformation")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# No Documentation Found.
#
# GET /api/v2/AuthorizationCodes/{id}/Validate
# operationId: AuthorizationCodes_ValidateAuthorizationCode
export def "authorization-codes-validate ValidateAuthorizationCode" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ExpirationDate: string, IsValid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/AuthorizationCodes/($id)/Validate")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contact information for authorization codes.
#
# GET /api/v2/AuthorizationContactInformation
# operationId: AuthorizationContactInformation_Get
export def "authorization-contact-information Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --authorizationCode: string # Optional. Search by authorization code.
  --afterDate: string # Optional. Include only data for authorization codes created after a provided date. (format: date-time)
  --beforeDate: string # Optional. Include only data for authorization codes created before a provided date. (format: date-time)
  --dealerCode: string # Optional. Search by dealer code.
]: nothing -> record<Entities: table<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "authorizationCode" $authorizationCode "scalar") (serialize-qp "afterDate" $afterDate "scalar") (serialize-qp "beforeDate" $beforeDate "scalar") (serialize-qp "dealerCode" $dealerCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationContactInformation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add contact information for authorization code.
#
# POST /api/v2/AuthorizationContactInformation
# operationId: AuthorizationContactInformation_Post
export def "authorization-contact-information Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  AuthorizationCodeID: int # AuthorizationCode ID that the contact information ties into. (format: int32)
  --Code: string # The authorization code. Read Only.
  Contact: string # Name of contact requesting an authorization code. Minimum length of 3 characters.
  --CreatedBy: string # The name of the user that created this code. Read Only.
  --CreatedDate: string # The date the authorization code was created. (format: date-time)
  DealerCode: string # Dealer code that relates to the dealership. Minimum length of 3 characters.
  Dealership: string # Name of dealership. Minimum length of 3 characters.
  --DefinitionName: string # The name of the definition used for generating this authorization code. Read Only.
  --Email: string # Email of contact.
  --ID: int # ID of authorizationContactInformation (format: int32)
  --Notes: string # Optional notes used for internal use.
  Phone: string # Phone number of contact.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationContactInformation")
  let body = {AuthorizationCodeID: $AuthorizationCodeID, Code: $Code, Contact: $Contact, CreatedBy: $CreatedBy, CreatedDate: $CreatedDate, DealerCode: $DealerCode, Dealership: $Dealership, DefinitionName: $DefinitionName, Email: $Email, ID: $ID, Notes: $Notes, Phone: $Phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of Brands.
#
# GET /api/v2/Brands
# operationId: Brands_Brands
export def "brands Brands" [
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
  let full_url = (build-url $base "/api/v2/Brands")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of bundles.
#
# GET /api/v2/Bundles
# operationId: Bundles_GetBundles
export def "bundles GetBundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --UpdateGroupID: string # Optional. Filter by UpdateGroup ID.
  --Active: oneof<nothing, bool> # Optional. Filter by active status.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --BundleNumber: int # Optional. If provided, filters by BundleNumber. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "Active" $Active "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "BundleNumber" $BundleNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Bundles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Bundle to the Update System.
#
# POST /api/v2/Bundles
# operationId: Bundles_PostBundle
export def "bundles PostBundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --BundleID: string # Read-Only.
  BundleNumber: int # The bundle number (format: int32)
  Description: string # The Bundle description.
  UpdateGroupID: string # The update group this bundle belongs to.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Bundles")
  let body = {Active: $Active, BundleID: $BundleID, BundleNumber: $BundleNumber, Description: $Description, UpdateGroupID: $UpdateGroupID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Bundle.
#
# DELETE /api/v2/Bundles/{ID}
# operationId: Bundles_DeleteBundle
export def "bundles DeleteBundle" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/Bundles/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Bundle by ID.
#
# GET /api/v2/Bundles/{ID}
# operationId: Bundles_GetBundle
export def "bundles GetBundle" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Bundles/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Bundle in the Update System.
#
# PUT /api/v2/Bundles/{ID}
# operationId: Bundles_PutBundle
export def "bundles PutBundle" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --BundleID: string # Read-Only.
  BundleNumber: int # The bundle number (format: int32)
  Description: string # The Bundle description.
  UpdateGroupID: string # The update group this bundle belongs to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Bundles/($ID)")
  let body = {Active: $Active, BundleID: $BundleID, BundleNumber: $BundleNumber, Description: $Description, UpdateGroupID: $UpdateGroupID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a List of Clients in the Update System.
#
# GET /api/v2/Clients
# operationId: Clients_Get
export def "clients Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Tag: string # Optional. Filter clients by Tag. Wildcards are supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, LastCheckin: string, Tag: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Tag" $Tag "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Clients" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Cached Files installed on the client Machine.
#
# GET /api/v2/Clients/{ClientID}/CachedFiles
# operationId: UpdateSystem_GetCachedFiles
export def "clients-cached-files GetCachedFiles" [
  ClientID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Expired: oneof<nothing, bool> # Only Expired Files (true|false)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Expired" $Expired "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Clients/($ClientID)/CachedFiles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the package reports for a client.
#
# GET /api/v2/Clients/{ClientID}/PackageReports
# operationId: PackageReports_Default
export def "clients-package-reports Default" [
  ClientID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Categories: list<record>, PackageDescription: string, PackageID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Clients/($ClientID)/PackageReports")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a package report
#
# PUT /api/v2/Clients/{ClientID}/PackageReports
# --Categories item shape: {Values?: list, category: string}
export def "clients-package-reports put" [
  ClientID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Categories: list # The package report's categories. — item shape: {Values?: list, category: string}
  --PackageDescription: string # Read Only. The package description
  --PackageID: string # The PackageID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Clients/($ClientID)/PackageReports")
  let body = {Categories: $Categories, PackageDescription: $PackageDescription, PackageID: $PackageID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a batch of package reports
#
# PUT /api/v2/Clients/{ClientID}/PackageReports/Batch
# operationId: PackageReports_Batch
export def "clients-package-reports-batch Batch" [
  ClientID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Clients/($ClientID)/PackageReports/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Client in the Update System.
#
# GET /api/v2/Clients/{ID}
export def "clients get" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ClientID: string, LastCheckin: string, Tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Clients/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Client.
#
# PUT /api/v2/Clients/{ID}
# operationId: Clients_Put
export def "clients Put" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientID: string # Read Only. The id of the client
  --LastCheckin: string # Read Only. The time of the client's last checkin with the server. (format: date-time)
  --Tag: string # A description of the client that can be used for easy reference
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Clients/($ID)")
  let body = {ClientID: $ClientID, LastCheckin: $LastCheckin, Tag: $Tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Client's Available Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/AvailableUpdateGroupSubscriptions
# operationId: Clients_GetAvailableSubscriptions
export def "clients-available-update-group-subscriptions GetAvailableSubscriptions" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --UpdateGroupID: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AvailableSubscriptions: list, UpdateGroup: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Clients/($ID)/AvailableUpdateGroupSubscriptions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Client's Current Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/UpdateGroupSubscriptions
# operationId: Clients_GetSubscriptions
export def "clients-update-group-subscriptions GetSubscriptions" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --UpdateGroupID: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Clients/($ID)/UpdateGroupSubscriptions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# No Documentation Found.
#
# PUT /api/v2/ContentDefinitionAttributes/Batch
# operationId: ContentDefinitions_PutContentDefinitionAttributes
export def "content-definition-attributes-batch PutContentDefinitionAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentDefinitionAttributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an Attribute from a ContentDefinition
#
# DELETE /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_DeleteContentDefinitionAttribute
export def "content-definition-attributes DeleteContentDefinitionAttribute" [
  contentDefinitionAttributeID: int
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
  let full_url = (build-url $base $"/api/v2/ContentDefinitionAttributes/($contentDefinitionAttributeID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Attribute for a ContentDefinition
#
# PUT /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_PutContentDefinitionAttributeAsync
export def "content-definition-attributes PutContentDefinitionAttributeAsync" [
  contentDefinitionAttributeID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ContentDefinitionID: int # The ID of the content definition to which this attribute belongs. (format: int32)
  --ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --Value: string # The value of this Attribute
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentDefinitionAttributes/($contentDefinitionAttributeID)")
  let body = {ContentDefinitionID: $ContentDefinitionID, ID: $ID, Name: $Name, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ContentDefinitions
#
# GET /api/v2/ContentDefinitions
# operationId: ContentDefinitions_GetContentDefinitions
export def "content-definitions GetContentDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --userID: int # Optional. Filter by UserID. (format: int32)
  --includeAttributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --name: string # Optional. Filter by Name. Supports beginning and ending wildcard (*).
  --typeID: int # Optional. Filter by TypeID. (format: int32)
  --packageTypeID: string # Optional. Filter by PackageTypeID.
]: nothing -> record<Entities: table<Attributes: list, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar") (serialize-qp "includeAttributes" $includeAttributes "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "typeID" $typeID "scalar") (serialize-qp "packageTypeID" $packageTypeID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentDefinitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ContentDefinition
#
# POST /api/v2/ContentDefinitions
# operationId: ContentDefinitions_PostContentDefinition
# --Attributes item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
export def "content-definitions PostContentDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --ContentDefinitionID: int # The ID of this content definition. (format: int32)
  Description: string # The description used on the package type in the AGCO Update System
  --Name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --PackageTypeID: string # Read Only. The ID of the package type used for this content.
  --TypeID: int # The type of content. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentDefinitions")
  let body = {Attributes: $Attributes, ContentDefinitionID: $ContentDefinitionID, Description: $Description, Name: $Name, PackageTypeID: $PackageTypeID, TypeID: $TypeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a ContentDefinition
#
# DELETE /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_DeleteContentDefinition
export def "content-definitions DeleteContentDefinition" [
  contentDefinitionID: int
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
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ContentDefinition by ID
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_GetContentDefinition
export def "content-definitions GetContentDefinition" [
  contentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeAttributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Attributes: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAttributes" $includeAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ContentDefinition
#
# PUT /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_PutContentDefinition
# --Attributes item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
export def "content-definitions PutContentDefinition" [
  contentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --ContentDefinitionID: int # The ID of this content definition. (format: int32)
  Description: string # The description used on the package type in the AGCO Update System
  --Name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --PackageTypeID: string # Read Only. The ID of the package type used for this content.
  --TypeID: int # The type of content. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)")
  let body = {Attributes: $Attributes, ContentDefinitionID: $ContentDefinitionID, Description: $Description, Name: $Name, PackageTypeID: $PackageTypeID, TypeID: $TypeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Attributes for a ContentDefinition
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# operationId: ContentDefinitions_GetContentDefinitionAttributes
export def "content-definitions-attributes GetContentDefinitionAttributes" [
  contentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> record<Entities: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)/Attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an Attribute to a ContentDefinition
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# operationId: ContentDefinitions_PostContentDefinitionAttribute
export def "content-definitions-attributes PostContentDefinitionAttribute" [
  contentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ContentDefinitionID: int # The ID of the content definition to which this attribute belongs. (format: int32)
  --ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --Value: string # The value of this Attribute
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)/Attributes")
  let body = {ContentDefinitionID: $ContentDefinitionID, ID: $ID, Name: $Name, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes/Batch
# operationId: ContentDefinitions_PostContentDefinitionAttributes
export def "content-definitions-attributes-batch PostContentDefinitionAttributes" [
  contentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentDefinitions/($contentDefinitionID)/Attributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ContentReleaseVersion
#
# GET /api/v2/ContentReleases
# operationId: ContentRelease_GetContentReleaseVersion
export def "content-releases GetContentReleaseVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --deleted: oneof<nothing, bool> # Optional. Filter by deleted.
  --releaseID: int # Optional. Filter by releaseID. (format: int32)
  --userId: int # Optional. Filter by UserID. (format: int32)
  --contentDefinitionID: int # Optional. Filter by ContentDefinitionID. (format: int32)
  --version: int # Optional. Filter by Version. (format: int32)
]: nothing -> record<Entities: table<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "releaseID" $releaseID "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "contentDefinitionID" $contentDefinitionID "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentReleases" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ContentReleaseVersion
#
# POST /api/v2/ContentReleases
# operationId: ContentRelease_PostContentRelease
export def "content-releases PostContentRelease" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ContentDefinitionID: int # ContentDefinitionID (format: int32)
  --ContentReleaseID: int # ContentReleaseID (format: int32)
  --Deleted: oneof<nothing, bool> # deleted flag
  --PublisherUserID: int # PublisherUser ID (format: int32)
  --ReleaseID: int # rele4ase Id (format: int32)
  --TestReportUrl: string # The URL at which test reports for this content can be found
  --UpdatedDate: string # Updated Date (format: date-time)
  --Version: int # version (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentReleases")
  let body = {ContentDefinitionID: $ContentDefinitionID, ContentReleaseID: $ContentReleaseID, Deleted: $Deleted, PublisherUserID: $PublisherUserID, ReleaseID: $ReleaseID, TestReportUrl: $TestReportUrl, UpdatedDate: $UpdatedDate, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a ContentReleaseVersion
#
# DELETE /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_DeleteContentReleaseVersionn
export def "content-releases DeleteContentReleaseVersionn" [
  ContentReleaseId: int
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
  let full_url = (build-url $base $"/api/v2/ContentReleases/($ContentReleaseId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Content Release Version by ID
#
# GET /api/v2/ContentReleases/{ContentReleaseId}
export def "content-releases get" [
  ContentReleaseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentReleases/($ContentReleaseId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ContentReleaseVersion
#
# PUT /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_PutContentDefinition
export def "content-releases PutContentDefinition" [
  ContentReleaseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ContentDefinitionID: int # ContentDefinitionID (format: int32)
  --ContentReleaseID: int # ContentReleaseID (format: int32)
  --Deleted: oneof<nothing, bool> # deleted flag
  --PublisherUserID: int # PublisherUser ID (format: int32)
  --ReleaseID: int # rele4ase Id (format: int32)
  --TestReportUrl: string # The URL at which test reports for this content can be found
  --UpdatedDate: string # Updated Date (format: date-time)
  --Version: int # version (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentReleases/($ContentReleaseId)")
  let body = {ContentDefinitionID: $ContentDefinitionID, ContentReleaseID: $ContentReleaseID, Deleted: $Deleted, PublisherUserID: $PublisherUserID, ReleaseID: $ReleaseID, TestReportUrl: $TestReportUrl, UpdatedDate: $UpdatedDate, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# PUT /api/v2/ContentSubmissionAttributes/Batch
# operationId: ContentSubmissions_PutContentSubmissionAttributes
export def "content-submission-attributes-batch PutContentSubmissionAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissionAttributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an Attribute from a ContentSubmission
#
# DELETE /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_DeleteContentSubmissionAttribute
export def "content-submission-attributes DeleteContentSubmissionAttribute" [
  contentSubmissionAttributeID: int
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
  let full_url = (build-url $base $"/api/v2/ContentSubmissionAttributes/($contentSubmissionAttributeID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Attribute for a ContentSubmission
#
# PUT /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_PutContentSubmissionAttributeAsync
export def "content-submission-attributes PutContentSubmissionAttributeAsync" [
  contentSubmissionAttributeID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ContentSubmissionID: int # The ID of the content submission to which this attribute belongs. (format: int32)
  --ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --Value: string # The value of this Attribute
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissionAttributes/($contentSubmissionAttributeID)")
  let body = {ContentSubmissionID: $ContentSubmissionID, ID: $ID, Name: $Name, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns available Content Submission Types.
#
# GET /api/v2/ContentSubmissionTypes
# operationId: ContentSubmissionTypes_GetContentSubmissionTypes
export def "content-submission-types GetContentSubmissionTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --enabled: oneof<nothing, bool>
]: nothing -> table<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentSubmissionTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Content Submission Type
#
# POST /api/v2/ContentSubmissionTypes
# operationId: ContentSubmissionTypes_PostContentSubmissionType
export def "content-submission-types PostContentSubmissionType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AttributeTemplate: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --BuildDefinitionID: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --CategoryTemplate: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  Description: string # A description for the Content Submission Type
  --Enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --ID: int # The ID of the Content Submission Type (format: int32)
  --InventoryPackageID: string # The ID of the Inventory Package from which to read the version of the package installed.
  --JobID: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  Name: string # The Name of the Content Submission Type
  --ReleaseNotesDescription: string # A description of how release notes for this Content Submission Type are used
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissionTypes")
  let body = {AttributeTemplate: $AttributeTemplate, BuildDefinitionID: $BuildDefinitionID, CategoryTemplate: $CategoryTemplate, Description: $Description, Enabled: $Enabled, ID: $ID, InventoryPackageID: $InventoryPackageID, JobID: $JobID, Name: $Name, ReleaseNotesDescription: $ReleaseNotesDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Content Submission Type
#
# DELETE /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_DeleteContentSubmissionType
export def "content-submission-types DeleteContentSubmissionType" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissionTypes/($id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Content Submission Type by its ID.
#
# GET /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_GetContentSubmissionType
export def "content-submission-types GetContentSubmissionType" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissionTypes/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Content Submission Type
#
# PUT /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_PutContentSubmissionType
export def "content-submission-types PutContentSubmissionType" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttributeTemplate: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --BuildDefinitionID: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --CategoryTemplate: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  Description: string # A description for the Content Submission Type
  --Enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --ID: int # The ID of the Content Submission Type (format: int32)
  --InventoryPackageID: string # The ID of the Inventory Package from which to read the version of the package installed.
  --JobID: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  Name: string # The Name of the Content Submission Type
  --ReleaseNotesDescription: string # A description of how release notes for this Content Submission Type are used
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissionTypes/($id)")
  let body = {AttributeTemplate: $AttributeTemplate, BuildDefinitionID: $BuildDefinitionID, CategoryTemplate: $CategoryTemplate, Description: $Description, Enabled: $Enabled, ID: $ID, InventoryPackageID: $InventoryPackageID, JobID: $JobID, Name: $Name, ReleaseNotesDescription: $ReleaseNotesDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ContentSubmissions
#
# GET /api/v2/ContentSubmissions
# operationId: ContentSubmissions_GetContentSubmissions
export def "content-submissions GetContentSubmissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --userID: int # Optional. Filter by UserID. (format: int32)
  --contentDefinitionID: int # Optional. Filter by ContentDefinitionID (format: int32)
  --includeAttributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --releaseID: int # Optional. Filter the submissions by whether they are part of the Release with the specified Release ID. (format: int32)
  --typeID: int # Optional. Filter submissions by their ContentDefinition's Type ID. (format: int32)
  --version: int # Optional. Filter submissions by their Version. (format: int32)
  --includeDefinition: oneof<nothing, bool> # Optional. If true, includes the ContentDefinition for each submission.
]: nothing -> record<Entities: table<Attributes: list, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar") (serialize-qp "contentDefinitionID" $contentDefinitionID "scalar") (serialize-qp "includeAttributes" $includeAttributes "scalar") (serialize-qp "releaseID" $releaseID "scalar") (serialize-qp "typeID" $typeID "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "includeDefinition" $includeDefinition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentSubmissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ContentSubmission
#
# POST /api/v2/ContentSubmissions
# operationId: ContentSubmissions_PostContentSubmission
# --Attributes item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
# --Definition shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
export def "content-submissions PostContentSubmission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --BuildID: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --ContentDefinitionID: int # The ID of the Content Definition. (format: int32)
  --ContentSubmissionID: int # The ID of this Content Submission. (format: int32)
  --Definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --JobRunID: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --PackageID: string # The ID of package generated by this content submission.
  --ReleaseNotes: string # Release Notes for this ContentSubmission
  --Repository: string # The SVN repository used as the source of this content submission
  --Revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --SubmissionDate: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --UserID: int # Read Only. The ID of the user who submitted the content (format: int32)
  --Version: int # Optional.  The version number assigned to this Content Submission and the resulting Package.             If not provided, version shall be 1 if it is the first content submission for the              ContentDefinitionID otherwise it shall be the highest content submission version for the             specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissions")
  let body = {Attributes: $Attributes, BuildID: $BuildID, ContentDefinitionID: $ContentDefinitionID, ContentSubmissionID: $ContentSubmissionID, Definition: $Definition, JobRunID: $JobRunID, PackageID: $PackageID, ReleaseNotes: $ReleaseNotes, Repository: $Repository, Revision: $Revision, SubmissionDate: $SubmissionDate, UserID: $UserID, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a ContentSubmission
#
# DELETE /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_DeleteContentSubmission
export def "content-submissions DeleteContentSubmission" [
  contentSubmissionID: int
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
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ContentSubmission by ID
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_GetContentSubmission
export def "content-submissions GetContentSubmission" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeAttributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list.
]: nothing -> record<Attributes: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record<Attributes: list<record>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAttributes" $includeAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ContentSubmission
#
# PUT /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_PutContentSubmission
# --Attributes item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
# --Definition shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
export def "content-submissions PutContentSubmission" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --BuildID: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --ContentDefinitionID: int # The ID of the Content Definition. (format: int32)
  --ContentSubmissionID: int # The ID of this Content Submission. (format: int32)
  --Definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --JobRunID: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --PackageID: string # The ID of package generated by this content submission.
  --ReleaseNotes: string # Release Notes for this ContentSubmission
  --Repository: string # The SVN repository used as the source of this content submission
  --Revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --SubmissionDate: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --UserID: int # Read Only. The ID of the user who submitted the content (format: int32)
  --Version: int # Optional.  The version number assigned to this Content Submission and the resulting Package.             If not provided, version shall be 1 if it is the first content submission for the              ContentDefinitionID otherwise it shall be the highest content submission version for the             specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)")
  let body = {Attributes: $Attributes, BuildID: $BuildID, ContentDefinitionID: $ContentDefinitionID, ContentSubmissionID: $ContentSubmissionID, Definition: $Definition, JobRunID: $JobRunID, PackageID: $PackageID, ReleaseNotes: $ReleaseNotes, Repository: $Repository, Revision: $Revision, SubmissionDate: $SubmissionDate, UserID: $UserID, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Attributes for a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# operationId: ContentSubmissions_GetContentSubmissionAttributes
export def "content-submissions-attributes GetContentSubmissionAttributes" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> record<Entities: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)/Attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an Attribute to a ContentSubmission
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# operationId: ContentSubmissions_PostContentSubmissionAttribute
export def "content-submissions-attributes PostContentSubmissionAttribute" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ContentSubmissionID: int # The ID of the content submission to which this attribute belongs. (format: int32)
  --ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --Value: string # The value of this Attribute
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)/Attributes")
  let body = {ContentSubmissionID: $ContentSubmissionID, ID: $ID, Name: $Name, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes/Batch
# operationId: ContentSubmissions_PostContentSubmissionAttributes
export def "content-submissions-attributes-batch PostContentSubmissionAttributes" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)/Attributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the status of a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Status
# operationId: ContentSubmissions_GetContentSubmissionStatus
export def "content-submissions-status GetContentSubmissionStatus" [
  contentSubmissionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeActivityRunDetails: oneof<nothing, bool> # True to include all status details if JobRun. Defaults to false
]: nothing -> record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeActivityRunDetails" $includeActivityRunDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ContentSubmissions/($contentSubmissionID)/Status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a total count of dealers per country
#
# GET /api/v2/DealerByCountry
# operationId: DealerByCountry_GetCountries
export def "dealer-by-country GetCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Count: int, Country: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/DealerByCountry" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of dealers.
#
# GET /api/v2/Dealers
# operationId: Dealers_GetDealers
export def "dealers GetDealers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Brand: string # The brand to filter by.
  --ShippingCountry: string # The country to filter by.
  --DealerName: string # The partial Dealer Name to filter by. Wildcard supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Brand" $Brand "scalar") (serialize-qp "ShippingCountry" $ShippingCountry "scalar") (serialize-qp "DealerName" $DealerName "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Dealers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lookup a dealer using a dealer code.
#
# GET /api/v2/Dealers/{DealerCode}
# operationId: Dealers_GetDealerbyDealerCode
export def "dealers GetDealerbyDealerCode" [
  DealerCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list<string>, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Dealers/($DealerCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paged response of file metadata.
#
# GET /api/v2/Files
# operationId: Files_GetFiles
export def "files GetFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeDeleted: oneof<nothing, bool> # Indicates whether to include files marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the metadata for a file before uploading. The State of the File should be 'Created'.
#
# POST /api/v2/Files
# operationId: Files_PostFile
export def "files PostFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  CRC: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  ContentType: string # The type of file; sent as the content-type header.
  Description: string # The description of the file.
  --Id: string # The Id of the file.
  --IsPublic: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  Name: string # The name of the file when downloaded.
  Path: string # The Path of the file.
  --Size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  State: string@State-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Files")
  let body = {CRC: $CRC, ContentType: $ContentType, Description: $Description, Id: $Id, IsPublic: $IsPublic, Name: $Name, Path: $Path, Size: $Size, State: $State} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark a file as 'Removed'. Disables download of the file and hides metadata from GET all method
#
# DELETE /api/v2/Files/{ID}
# operationId: Files_DeleteFile
export def "files DeleteFile" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/Files/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a file's metadata.
#
# GET /api/v2/Files/{ID}
# operationId: Files_GetFile
export def "files GetFile" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Files/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the metadata for a file. Size may not be modified by the client.
#
# PUT /api/v2/Files/{ID}
# operationId: Files_PutFile
export def "files PutFile" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  CRC: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  ContentType: string # The type of file; sent as the content-type header.
  Description: string # The description of the file.
  --Id: string # The Id of the file.
  --IsPublic: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  Name: string # The name of the file when downloaded.
  Path: string # The Path of the file.
  --Size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  State: string@State-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Files/($ID)")
  let body = {CRC: $CRC, ContentType: $ContentType, Description: $Description, Id: $Id, IsPublic: $IsPublic, Name: $Name, Path: $Path, Size: $Size, State: $State} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the contents of a file. The current State of the File should be 'Available'.
#
# GET /api/v2/Files/{ID}/FileContents
# operationId: Files_GetFileContents
export def "files-file-contents GetFileContents" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/Files/($ID)/FileContents")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload the contents of a file. The current State of the File should be 'Created'.
#
# PUT /api/v2/Files/{ID}/FileContents
# operationId: Files_PutFileContents
export def "files-file-contents PutFileContents" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/Files/($ID)/FileContents")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paged response of file metadata.
#
# GET /api/v2/GlobalImageCategories
# operationId: GlobalImageCategories_GetFiles
export def "global-image-categories GetFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Id: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImageCategories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the metadata for a file before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImageCategories
# operationId: GlobalImageCategories_PostFile
export def "global-image-categories PostFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Id: string # The Id of the GlobalImage Categories.
  Name: string # The name of the globalImage Catetory.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/GlobalImageCategories")
  let body = {Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a file's metadata.
#
# GET /api/v2/GlobalImageCategories/{ID}
# operationId: GlobalImageCategories_GetFile
export def "global-image-categories GetFile" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/GlobalImageCategories/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paged response of GlobalImage.
#
# GET /api/v2/GlobalImages
# operationId: GlobalImages_GetGlobalImages
export def "global-images GetGlobalImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Optional. Searches for matching global images with the matching Category Name, Publisher or Description
  --categoryId: string
  --publisher: string
  --includeDeleted: oneof<nothing, bool> # Indicates whether to include GlobalImages marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CRC: string, Categories: list, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "categoryId" $categoryId "scalar") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the metadata for a GlobalImage before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImages
# operationId: GlobalImages_PostGlobalImage
# --Categories item shape: {Id?: string, Name: string}
export def "global-images PostGlobalImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --overridePublisherOrDate: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  CRC: string # The Hash of the file (SHA256, HEX-encoded).
  --Categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --Date: string # The date of the file. (format: date-time)
  Description: string # The description of the file.
  Height: int # The height of the file. (format: int32)
  --Id: string # The Id of the GlobalImage Metadata.
  Name: string # The name of the file when downloaded.
  --Publisher: string # The Publisher of the file.
  --Size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  State: string@State-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  ThumbnailCRC: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --ThumbnailSize: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  Width: int # The width of the file. (format: int32)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overridePublisherOrDate" $overridePublisherOrDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImages" $qp)
  let body = {CRC: $CRC, Categories: $Categories, Date: $Date, Description: $Description, Height: $Height, Id: $Id, Name: $Name, Publisher: $Publisher, Size: $Size, State: $State, ThumbnailCRC: $ThumbnailCRC, ThumbnailSize: $ThumbnailSize, Width: $Width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark a file as 'Removed'. Disables download of the image and hides metadata from GET all method
#
# DELETE /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_DeleteFile
export def "global-images DeleteFile" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/GlobalImages/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a GlobalImage's metadata.
#
# GET /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_GetGlobalImage
export def "global-images GetGlobalImage" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CRC: string, Categories: table<Id: string, Name: string>, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/GlobalImages/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the metadata for an image.
#
# PUT /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_PutGlobalImage
# --Categories item shape: {Id?: string, Name: string}
export def "global-images PutGlobalImage" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --overridePublisherOrDate: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  CRC: string # The Hash of the file (SHA256, HEX-encoded).
  --Categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --Date: string # The date of the file. (format: date-time)
  Description: string # The description of the file.
  Height: int # The height of the file. (format: int32)
  --Id: string # The Id of the GlobalImage Metadata.
  Name: string # The name of the file when downloaded.
  --Publisher: string # The Publisher of the file.
  --Size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  State: string@State-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  ThumbnailCRC: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --ThumbnailSize: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  Width: int # The width of the file. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overridePublisherOrDate" $overridePublisherOrDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/GlobalImages/($ID)" $qp)
  let body = {CRC: $CRC, Categories: $Categories, Date: $Date, Description: $Description, Height: $Height, Id: $Id, Name: $Name, Publisher: $Publisher, Size: $Size, State: $State, ThumbnailCRC: $ThumbnailCRC, ThumbnailSize: $ThumbnailSize, Width: $Width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the contents of a GlobalImage. The current State of the GlobalImage should be 'Available'.
#
# GET /api/v2/GlobalImages/{ID}/ImageContents
# operationId: GlobalImages_GetGlobalImageContents
export def "global-images-image-contents GetGlobalImageContents" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isFullImage: oneof<nothing, bool> # Indicated whether to download the full image or the thumbnail. Defaults to 'true'.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isFullImage" $isFullImage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/GlobalImages/($ID)/ImageContents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload the contents of a GlobalImage. The current State of the File for the GlobalImage should be 'Created'.
#
# PUT /api/v2/GlobalImages/{ID}/ImageContents
# operationId: GlobalImages_PutGlobalImageContents
export def "global-images-image-contents PutGlobalImageContents" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isFullImage: oneof<nothing, bool> # Indicated whether this is the full image or the thumbnail. Defaults to 'true'.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isFullImage" $isFullImage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/GlobalImages/($ID)/ImageContents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of the languages for which translations are supported. Returns a PagedResponse of Language objects.
#
# GET /api/v2/Languages
# operationId: Languages_GetLanguages
export def "languages GetLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # limit the number of Language objects returned. Optional (defaults to 10). (format: int32)
  --offset: int # the number of Language objects to skip. Optional (defaults to 0). (format: int32)
  --includeDeleted: oneof<nothing, bool> # whether to include languages marked as deleted. Defaults to false
]: nothing -> record<Entities: table<Description: string, IsDeleted: bool, LocaleId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Languages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Language to support for translations. Accepts a Language object. Returns the Id of the created object.
#
# POST /api/v2/Languages
# operationId: Languages_CreateLanguage
export def "languages CreateLanguage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  Description: string # The description of the language (e.g. “English – United States”).
  --IsDeleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  LocaleId: int # The Locale Id of the language. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Languages")
  let body = {Description: $Description, IsDeleted: $IsDeleted, LocaleId: $LocaleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Language from those supported for translations. Marks language as deleted.
#
# DELETE /api/v2/Languages/{LocaleID}
# operationId: Languages_DeleteLanguage
export def "languages DeleteLanguage" [
  LocaleID: int
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
  let full_url = (build-url $base $"/api/v2/Languages/($LocaleID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a language by its id. Returns a Language object
#
# GET /api/v2/Languages/{LocaleID}
# operationId: Languages_GetLanguage
export def "languages GetLanguage" [
  LocaleID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, IsDeleted: bool, LocaleId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Languages/($LocaleID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a language’s description. Accepts a Language object.
#
# PUT /api/v2/Languages/{LocaleID}
# operationId: Languages_UpdateLanguage
export def "languages UpdateLanguage" [
  LocaleID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Description: string # The description of the language (e.g. “English – United States”).
  --IsDeleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  LocaleId: int # The Locale Id of the language. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Languages/($LocaleID)")
  let body = {Description: $Description, IsDeleted: $IsDeleted, LocaleId: $LocaleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a license activation.
#
# POST /api/v2/LicenseActivations
# operationId: LicenseActivations_Post
export def "license-activations Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  DealerCode: string # The Dealer Code of the dealer activating the license
  --LicenseActivationType: string@LicenseActivationType-completer # The type of license to create (e.g. EDT, EDT Lite)
  PostalCode: string # The dealer's postal code (zip code)
  SystemInfo: string # Information about  the system being activated
  VoucherCode: string # The Voucher Code to use for activation
]: any -> record<Key: string, LicenseData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/LicenseActivations")
  let body = {DealerCode: $DealerCode, LicenseActivationType: $LicenseActivationType, PostalCode: $PostalCode, SystemInfo: $SystemInfo, VoucherCode: $VoucherCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Register an EDT Lite with the Server
#
# POST /api/v2/LicenseActivations/RegisterEDTLite
# operationId: LicenseActivations_PostRegisterEDTLite
export def "license-activations-register-edt-lite PostRegisterEDTLite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --DealerCode: string # The dealer code with which the EDT Lite was created.
  ExpirationDate: string # The date at which the content of the EDT Lite expires. (format: date-time)
  InstanceID: string # The identifier for the EDT Lite.
  VoucherCode: string # The voucher code with which the EDT Lite was created.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/LicenseActivations/RegisterEDTLite")
  let body = {DealerCode: $DealerCode, ExpirationDate: $ExpirationDate, InstanceID: $InstanceID, VoucherCode: $VoucherCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a license activiation.
#
# PUT /api/v2/LicenseActivations/{ID}
# operationId: LicenseActivations_Put
export def "license-activations Put" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  LicenseVersion: string # The license version to update
  --SystemInfo: string # Information about  the system being activated
]: any -> record<Key: string, LicenseData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/LicenseActivations/($ID)")
  let body = {LicenseVersion: $LicenseVersion, SystemInfo: $SystemInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirm that the client has applied the updated license.
#
# PUT /api/v2/LicenseActivations/{ID}/Confirm
# operationId: LicenseActivations_PutConfirm
export def "license-activations-confirm PutConfirm" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  LicenseVersion: string # The license version to confirm
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/LicenseActivations/($ID)/Confirm")
  let body = {LicenseVersion: $LicenseVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of licenses with the specified criteria.
#
# GET /api/v2/Licenses
# operationId: Licenses_Get
export def "licenses Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --VoucherCode: string # Optional. Filter by VoucherCode
  --DealerCode: string # Optional. Filter by DealerCode
  --Status: string@Status-completer # Optional. Filter by Status.  By default only active licenses will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "VoucherCode" $VoucherCode "scalar") (serialize-qp "DealerCode" $DealerCode "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Licenses" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a license.
#
# GET /api/v2/Licenses/{ID}
export def "licenses get" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Licenses/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the API System logs, most recent first.
#
# GET /api/v2/Logs
# operationId: Logs_GetLogs
export def "logs GetLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ID: string, Message: string, TimeStamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Log entry
#
# POST /api/v2/Logs
# operationId: Logs_PostLog
export def "logs PostLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Message: string # Message to enter into the log
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Message" $Message "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a log by ID
#
# GET /api/v2/Logs/{ID}
# operationId: Logs_GetLog
export def "logs GetLog" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ID: string, Message: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Logs/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends an email message.
#
# POST /api/v2/Notifications
# operationId: Notifications_PostMail
export def "notifications PostMail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CC-Addresses: list
  --IsBodyHtml: oneof<nothing, bool>
  MessageBody: string
  Subject: string
  To_Addresses: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Notifications")
  let body = {CC_Addresses: $CC_Addresses, IsBodyHtml: $IsBodyHtml, MessageBody: $MessageBody, Subject: $Subject, To_Addresses: $To_Addresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all of the Package Types.
#
# GET /api/v2/PackageTypes
# operationId: PackageTypes_Get
export def "package-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --userID: int # Optional. The user ID to sort packageTypes by the user's access (format: int32)
]: nothing -> record<Entities: table<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Package Type.
#
# POST /api/v2/PackageTypes
# operationId: PackageTypes_Post
export def "package-types Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --Category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  Description: string # The description of the package type
  --Icon: string # Optional.  The icon to use for the PackageType, in base 64
  --InventoryFrequency: int # The number of minutes to wait before requesting another inventory.  The default value is 1440 (24 hours). (format: int32)
  --InventoryPackage: string # The inventory package used to determine what version of this package type is installed.
  --LocalizedDescription: string # Optional. The StringID used to localize the description of the PackageType
  --LocalizedName: string # Optional. The StringID used to localize the name of the PackageType
  --MaxDeltaPackages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --PackageTypeID: string # Read Only. The package type id.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypes")
  let body = {Attribute: $Attribute, Category: $Category, Description: $Description, Icon: $Icon, InventoryFrequency: $InventoryFrequency, InventoryPackage: $InventoryPackage, LocalizedDescription: $LocalizedDescription, LocalizedName: $LocalizedName, MaxDeltaPackages: $MaxDeltaPackages, PackageTypeID: $PackageTypeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Package Type.
#
# DELETE /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Delete
export def "package-types Delete" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/PackageTypes/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Package Type.
#
# GET /api/v2/PackageTypes/{ID}
export def "package-types get" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/PackageTypes/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Package Type.
#
# PUT /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Put
export def "package-types Put" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --Category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  Description: string # The description of the package type
  --Icon: string # Optional.  The icon to use for the PackageType, in base 64
  --InventoryFrequency: int # The number of minutes to wait before requesting another inventory.  The default value is 1440 (24 hours). (format: int32)
  --InventoryPackage: string # The inventory package used to determine what version of this package type is installed.
  --LocalizedDescription: string # Optional. The StringID used to localize the description of the PackageType
  --LocalizedName: string # Optional. The StringID used to localize the name of the PackageType
  --MaxDeltaPackages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --PackageTypeID: string # Read Only. The package type id.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/PackageTypes/($ID)")
  let body = {Attribute: $Attribute, Category: $Category, Description: $Description, Icon: $Icon, InventoryFrequency: $InventoryFrequency, InventoryPackage: $InventoryPackage, LocalizedDescription: $LocalizedDescription, LocalizedName: $LocalizedName, MaxDeltaPackages: $MaxDeltaPackages, PackageTypeID: $PackageTypeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a package type a user could see.
#
# DELETE /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_RemovePackageTypeUser
export def "package-types-users RemovePackageTypeUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/PackageTypes/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a package type that a user can see.
#
# POST /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_AddPackageTypeUser
export def "package-types-users AddPackageTypeUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/PackageTypes/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Package Type to Bundle Relationship.
#
# DELETE /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Delete
export def "package-typeto-bundles Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BundleID: string # The BundleID
  --PackageTypeID: string # The PackageTypeID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $BundleID "scalar") (serialize-qp "PackageTypeID" $PackageTypeID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all of the Package Type to Bundle Relationships.
#
# GET /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Get
export def "package-typeto-bundles Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --BundleID: string # Optional. Filter by BundleID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<BundleID: string, PackageTypeID: string, PackageVersion: int, Priority: int, SubscriptionType: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $BundleID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new Package Type ID to Bundle Relationship.
#
# POST /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Post
export def "package-typeto-bundles Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  BundleID: string # The bundle to include the package in.
  PackageTypeID: string # The package type id of the package to include
  PackageVersion: int # The package version of the package to include (format: int32)
  Priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --SubscriptionType: string@SubscriptionType-completer # Optional. The type of subscription supported.  The default subscription type is Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles")
  let body = {BundleID: $BundleID, PackageTypeID: $PackageTypeID, PackageVersion: $PackageVersion, Priority: $Priority, SubscriptionType: $SubscriptionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Package Type ID to Bundle Relationship.
#
# PUT /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Put
export def "package-typeto-bundles Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  BundleID: string # The bundle to include the package in.
  PackageTypeID: string # The package type id of the package to include
  PackageVersion: int # The package version of the package to include (format: int32)
  Priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --SubscriptionType: string@SubscriptionType-completer # Optional. The type of subscription supported.  The default subscription type is Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles")
  let body = {BundleID: $BundleID, PackageTypeID: $PackageTypeID, PackageVersion: $PackageVersion, Priority: $Priority, SubscriptionType: $SubscriptionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Packages.
#
# GET /api/v2/Packages
# operationId: Packages_GetPackages
export def "packages GetPackages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --PackageTypeID: string # Optional. If provided, filters by PackageTypeID.
  --Version: int # Optional. If provided, filters by Version. (format: int32)
  --Released: oneof<nothing, bool> # Optional. If provided, filters by Released.
]: nothing -> record<Entities: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "PackageTypeID" $PackageTypeID "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Released" $Released "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Packages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Package to the Update System.
#
# POST /api/v2/Packages
# operationId: Packages_PostPackage
export def "packages PostPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  CRC: string # The CRC used to validate the download.
  Description: string # The package description
  --LocalizedName: string # Optional. The StringID used to localize the name of the Package
  --Notes: string # Notes about the package
  --PackageID: string # Read Only. The package ID
  PackageTypeID: string # The id of the package type this package belongs to.
  --PreviousVersion: int # For delta packages, the previous version required.  For non-delta packages, the Previous version is 0.  Default value is 0. (format: int32)
  ReleaseDate: string # The date the package was released (format: date-time)
  --Released: oneof<nothing, bool> # True if the package is released.  Default value is False.
  --RemoveOnSuccess: oneof<nothing, bool> # True to remove the package after successful execution.  Default value is False.
  --Size: int # The size of the file at the specified URL.  If a size is not supplied at creation time, the size will be determined by the response from the URL.             If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --Switches: string # The command line arguments for the package.  Default value is an empty string.
  Url: string # The Url to download the package from.
  Version: int # The version. (format: int32)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Packages")
  let body = {Autorun: $Autorun, CRC: $CRC, Description: $Description, LocalizedName: $LocalizedName, Notes: $Notes, PackageID: $PackageID, PackageTypeID: $PackageTypeID, PreviousVersion: $PreviousVersion, ReleaseDate: $ReleaseDate, Released: $Released, RemoveOnSuccess: $RemoveOnSuccess, Size: $Size, Switches: $Switches, Url: $Url, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Package.
#
# DELETE /api/v2/Packages/{ID}
# operationId: Packages_DeletePackage
export def "packages DeletePackage" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/Packages/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a Package.
#
# GET /api/v2/Packages/{ID}
# operationId: Packages_GetPackage
export def "packages GetPackage" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Packages/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Packge to the Update System.
#
# PUT /api/v2/Packages/{ID}
# operationId: Packages_PutPackage
export def "packages PutPackage" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  CRC: string # The CRC used to validate the download.
  Description: string # The package description
  --LocalizedName: string # Optional. The StringID used to localize the name of the Package
  --Notes: string # Notes about the package
  --PackageID: string # Read Only. The package ID
  PackageTypeID: string # The id of the package type this package belongs to.
  --PreviousVersion: int # For delta packages, the previous version required.  For non-delta packages, the Previous version is 0.  Default value is 0. (format: int32)
  ReleaseDate: string # The date the package was released (format: date-time)
  --Released: oneof<nothing, bool> # True if the package is released.  Default value is False.
  --RemoveOnSuccess: oneof<nothing, bool> # True to remove the package after successful execution.  Default value is False.
  --Size: int # The size of the file at the specified URL.  If a size is not supplied at creation time, the size will be determined by the response from the URL.             If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --Switches: string # The command line arguments for the package.  Default value is an empty string.
  Url: string # The Url to download the package from.
  Version: int # The version. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Packages/($ID)")
  let body = {Autorun: $Autorun, CRC: $CRC, Description: $Description, LocalizedName: $LocalizedName, Notes: $Notes, PackageID: $PackageID, PackageTypeID: $PackageTypeID, PreviousVersion: $PreviousVersion, ReleaseDate: $ReleaseDate, Released: $Released, RemoveOnSuccess: $RemoveOnSuccess, Size: $Size, Switches: $Switches, Url: $Url, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Permissions
#
# GET /api/v2/Permissions
# operationId: Permissions_GetPermissions
export def "permissions GetPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Filter by permission name. Supports ending wildcard (*). Optional.
]: nothing -> record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Permissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Permission
#
# POST /api/v2/Permissions
# operationId: Permissions_PostPermission
export def "permissions PostPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --DataDescription: string # Description of data to be provided with Role Authorization
  DataRequired: string@DataRequired-completer # Indicates if data is required or optional
  --Description: string
  --Id: int # The identifier of the permission. (format: int32)
  Name: string # The name of the permission.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Permissions")
  let body = {DataDescription: $DataDescription, DataRequired: $DataRequired, Description: $Description, Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a Permission
#
# DELETE /api/v2/Permissions/{id}
# operationId: Permissions_DeletePermission
export def "permissions DeletePermission" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Permissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Permission
#
# GET /api/v2/Permissions/{id}
# operationId: Permissions_GetPermission
export def "permissions GetPermission" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Permissions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Permission
#
# PUT /api/v2/Permissions/{id}
# operationId: Permissions_PutPermission
export def "permissions PutPermission" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DataDescription: string # Description of data to be provided with Role Authorization
  DataRequired: string@DataRequired-completer # Indicates if data is required or optional
  --Description: string
  --Id: int # The identifier of the permission. (format: int32)
  Name: string # The name of the permission.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Permissions/($id)")
  let body = {DataDescription: $DataDescription, DataRequired: $DataRequired, Description: $Description, Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of Priority Packages by Client.
#
# GET /api/v2/PriorityPackages
# operationId: PriorityPackages_GetPriorityPackages
export def "priority-packages GetPriorityPackages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --ClientID: string # Optional. Filter priority packages by ClientID.
  --Status: string@Status-completer-1 # Optional. Filter returned packages by status. By default only active packages will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PriorityPackages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Priority Package for a Client.
#
# POST /api/v2/PriorityPackages
# operationId: PriorityPackages_PostPriorityPackages
export def "priority-packages PostPriorityPackages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Autorun: oneof<nothing, bool> # Read Only. From the package specified by package ID.             Value is true if package should run automatically. Default value is false.
  --CRC: string # Read Only. From the package specified by package ID.
  ClientID: string # The ID of the client to receive the priority package
  --Description: string # Read Only. From the package specified by package ID.
  --Notes: string # Read Only. From the package specified by package ID.
  PackageID: string # The ID of the package to push as a priority package.
  --PackageTypeID: string # Read Only. From the package specified by package ID.
  --PreviousVersion: int # Read Only. From the package specified by package ID. (format: int32)
  --PriorityPackageID: string # Read Only. The ID of the priority package.
  --ReleaseDate: string # Read Only. From the package specified by package ID.             The date the package was released (format: date-time)
  --Released: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --RemoveOnSuccess: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --Size: int # Read Only. From the package specified by package ID. (format: int64)
  --Switches: string # The command line arguments for the priority package.  Default value is an empty string.
  --TimeStamp: string # Read Only. The timestamp of the priority package. (format: date-time)
  --Url: string # Read Only. From the package specified by package ID.
  --Version: int # Read Only. From the package specified by package ID. (format: int32)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PriorityPackages")
  let body = {Autorun: $Autorun, CRC: $CRC, ClientID: $ClientID, Description: $Description, Notes: $Notes, PackageID: $PackageID, PackageTypeID: $PackageTypeID, PreviousVersion: $PreviousVersion, PriorityPackageID: $PriorityPackageID, ReleaseDate: $ReleaseDate, Released: $Released, RemoveOnSuccess: $RemoveOnSuccess, Size: $Size, Switches: $Switches, TimeStamp: $TimeStamp, Url: $Url, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Priority Package for a Client.
#
# DELETE /api/v2/PriorityPackages/{ID}
# operationId: PriorityPackages_DeletePriorityPackages
export def "priority-packages DeletePriorityPackages" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/PriorityPackages/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Priority Packages for a Client.
#
# GET /api/v2/PriorityPackages/{ID}
# operationId: PriorityPackages_GetPriorityPackage
export def "priority-packages GetPriorityPackage" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/PriorityPackages/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Release
#
# GET /api/v2/Releases
# operationId: Release_GetReleases
export def "releases GetReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --visible: oneof<nothing, bool> # Optional. Filter by visible.
  --bundleID: string # Optional. Filter by BundleID.
]: nothing -> record<Entities: table<BuildDate: string, BundleIDs: list, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "bundleID" $bundleID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Releases" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Release
#
# POST /api/v2/Releases
# operationId: Release_PostRelease
export def "releases PostRelease" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BuildDate: string # Build Date (format: date-time)
  --BundleIDs: list # IDs of AUC Bundles associated with this Release.
  --ReleaseDate: string # Release Date (format: date-time)
  --ReleaseID: int # Release ID (format: int32)
  --ReleaseNumber: string # Release Number
  --Visible: oneof<nothing, bool> # Visible
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Releases")
  let body = {BuildDate: $BuildDate, BundleIDs: $BundleIDs, ReleaseDate: $ReleaseDate, ReleaseID: $ReleaseID, ReleaseNumber: $ReleaseNumber, Visible: $Visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a  Release by ID
#
# GET /api/v2/Releases/{ReleaseId}
# operationId: Release_GetRelease
export def "releases GetRelease" [
  ReleaseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<BuildDate: string, BundleIDs: list<string>, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Releases/($ReleaseId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the association between a release and a bundle.
#
# DELETE /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_DeleteReleaseBundle
export def "releases-bundle DeleteReleaseBundle" [
  ReleaseId: int
  BundleId: string
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
  let full_url = (build-url $base $"/api/v2/Releases/($ReleaseId)/Bundle/($BundleId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associates the release with a bundle.
#
# POST /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_PostReleaseBundle
export def "releases-bundle PostReleaseBundle" [
  ReleaseId: int
  BundleId: string
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
  let full_url = (build-url $base $"/api/v2/Releases/($ReleaseId)/Bundle/($BundleId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Release
#
# PUT /api/v2/Releases/{releaseId}
# operationId: Release_PutContentDefinition
export def "releases PutContentDefinition" [
  releaseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BuildDate: string # Build Date (format: date-time)
  --BundleIDs: list # IDs of AUC Bundles associated with this Release.
  --ReleaseDate: string # Release Date (format: date-time)
  --ReleaseID: int # Release ID (format: int32)
  --ReleaseNumber: string # Release Number
  --Visible: oneof<nothing, bool> # Visible
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Releases/($releaseId)")
  let body = {BuildDate: $BuildDate, BundleIDs: $BundleIDs, ReleaseDate: $ReleaseDate, ReleaseID: $ReleaseID, ReleaseNumber: $ReleaseNumber, Visible: $Visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a summary of all Packages in a Bundle
#
# GET /api/v2/Reporting/BundleStatusSummary
# operationId: Reporting_BundleStatusSummary
export def "reporting-bundle-status-summary BundleStatusSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --BundleID: string # The BundleID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $BundleID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/BundleStatusSummary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/Reporting/BundlesInUpdateGroup
# operationId: Reporting_BundlesInUpdateGroup
export def "reporting-bundles-in-update-group BundlesInUpdateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --ID: string # The UpdateGroupID
  --IncludeInactive: oneof<nothing, bool> # Include Inactive Bundles (true|false)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $ID "scalar") (serialize-qp "IncludeInactive" $IncludeInactive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/BundlesInUpdateGroup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Client Information
#
# GET /api/v2/Reporting/ClientInfo
# operationId: Reporting_ClientInfo
export def "reporting-client-info ClientInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ClientID: string # The Client ID
]: nothing -> record<ClientID: string, Package: table<Categories: list, PackageDescription: string, PackageID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/ClientInfo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the current packages for an update group.
#
# GET /api/v2/Reporting/CurrentPackagesInUpdateGroup
# operationId: Reporting_CurrentPackagesInUpdateGroup
export def "reporting-current-packages-in-update-group CurrentPackagesInUpdateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ID: string # The UpdateGroupID
  --SubscriptionTypeFilter: string@SubscriptionTypeFilter-completer # Optional.  The subscription type filter to use.  By default the Default packages (Required and IncludeByDefault) will be returned.
]: nothing -> table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $ID "scalar") (serialize-qp "SubscriptionTypeFilter" $SubscriptionTypeFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/CurrentPackagesInUpdateGroup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Client in the Update System.
#
# GET /api/v2/Reporting/GetClient
# operationId: Reporting_GetClient
export def "reporting-get-client GetClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ID: string # The Client ID
]: nothing -> record<ClientID: string, LastCheckin: string, Tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $ID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/GetClient" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/Reporting/GetSubscriptions
# operationId: Reporting_GetSubscriptions
export def "reporting-get-subscriptions GetSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --ClientID: string # Optional. Filter by Client ID
  --UpdateGroupID: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/GetSubscriptions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a summary report for a Specific Package
#
# GET /api/v2/Reporting/PackageStatusSummary
# operationId: Reporting_PackageStatusSummary
export def "reporting-package-status-summary PackageStatusSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --PackageID: string # The Package ID
]: nothing -> record<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: table<ClientID: string, ClientKey: string, DownloadTime: string, Downloaded: string, InstallCompleted: string, InstallResult: string, InstallStarted: string, InstallTime: string, Percentage: string, Size: string, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PackageID" $PackageID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/PackageStatusSummary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of subscribed clients
#
# GET /api/v2/Reporting/RegisteredClients
# operationId: Reporting_RegisteredClients
export def "reporting-registered-clients RegisteredClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --UpdateGroupID: string # Optional but required when including any or all of following parameters: ReportValue, ReportResult, ReportResultIsValid. The Update Group ID. If not provided, all clients will be returned.
  --ClientID: string # Optional. Filter where ClientID matches a value. Wildcards are supported (*).
  --Tag: string # Optional. Filter where Tag matches a value. Wildcards are supported (*).
  --ReportResult: string # Optional and UpdateGroupID must be included. Filter where ReportResult matches a value. Wildcards are supported (*).
  --ReportResultIsValid: oneof<nothing, bool> # Optional and UpdateGroupID must be included. When 'true' filters results where ReportResult equals ReportResultExpected.  When 'false' filters results where ValueToValidate does not equal ReportResults.
  --ReportValue: string # Optional and UpdateGroupID must be included. Filter where ReportValue matches a value. Wildcards are supported (*).
  --LastCheckInBefore: string # Optional. Filter where LastCheckIn occured before the provided date. (format: date-time)
  --LastCheckInAfter: string # Optional. Filter where LastCheckIn occured after the provided date. (format: date-time)
  --OrderBy: string # Optional. Specify the order in which results should be returned. Use this format: [FieldName] [ASC|ASCENDING|DESC|DESCENDING],...                If sort direction is not provided for a field, it will be sorted ascending.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, LastCheckin: string, MinutesElapsed: int, ReportResult: string, ReportResultIsValid: bool, ReportValue: string, Tag: string>, Metadata: record<Limit: int, Offset: int, ReportResultExpected: string, ReportResultLabel: string, ReportValueLabel: string, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "Tag" $Tag "scalar") (serialize-qp "ReportResult" $ReportResult "scalar") (serialize-qp "ReportResultIsValid" $ReportResultIsValid "scalar") (serialize-qp "ReportValue" $ReportValue "scalar") (serialize-qp "LastCheckInBefore" $LastCheckInBefore "scalar") (serialize-qp "LastCheckInAfter" $LastCheckInAfter "scalar") (serialize-qp "OrderBy" $OrderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/RegisteredClients" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Update Groups.  Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/Reporting/UpdateGroups
# operationId: Reporting_UpdateGroups
export def "reporting-update-groups UpdateGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/UpdateGroups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get data for pie charts in UpdateMetrics.
#
# GET /api/v2/Reporting/UpdateMetrics
# operationId: Reporting_UpdateMetrics
export def "reporting-update-metrics UpdateMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdateGroupID: string # The UpdateType in which clients must be for the report to include them.
  --bundleNumber: int # Optional. Tells us which chart to show based upon filter. (format: int32)
]: nothing -> record<ActiveVersion: string, ActiveVersionByClient: table<BundleNumber: int, ClientCount: int, ReleaseName: string>, CurrentStateByClient: table<ClientCount: int, State: string>, CutOffDate: string, DataRefreshed: string, FilteredClientCount: int, PackageErrors: table<ClientCount: int, ErrorCode: string, LongDescription: string, ShortDescription: string>, TotalClientCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "bundleNumber" $bundleNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/UpdateMetrics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Roles
#
# GET /api/v2/Roles
# operationId: Roles_GetRoles
export def "roles GetRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Optional. Finds a role with the given name.
  --permissionID: int # format: int32
  --permissionName: string # Optional. Filters roles by whether they contain the provided permission.
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "permissionID" $permissionID "scalar") (serialize-qp "permissionName" $permissionName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Roles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a User Role
#
# POST /api/v2/Roles
# operationId: Roles_PostRole
export def "roles PostRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  Description: string # Role description
  --Id: int # The role's identifier. (format: int32)
  Name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Roles")
  let body = {Description: $Description, Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a User Role
#
# DELETE /api/v2/Roles/{id}
# operationId: Roles_DeleteRole
export def "roles DeleteRole" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a User Role
#
# GET /api/v2/Roles/{id}
# operationId: Roles_GetRole
export def "roles GetRole" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Roles/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a User Role
#
# PUT /api/v2/Roles/{id}
# operationId: Roles_PutRole
export def "roles PutRole" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Description: string # Role description
  --Id: int # The role's identifier. (format: int32)
  Name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Roles/($id)")
  let body = {Description: $Description, Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the Permissions for a Role
#
# GET /api/v2/Roles/{id}/Permissions
# operationId: Roles_GetRolePermissions
export def "roles-permissions GetRolePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --name: string # Filter by permission name. Optional.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Roles/($id)/Permissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manage the Permissions for a Role
#
# PUT /api/v2/Roles/{id}/Permissions
# operationId: Roles_PutRolePermissions
export def "roles-permissions PutRolePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Roles/($id)/Permissions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all user's in a role
#
# GET /api/v2/Roles/{id}/Users
# operationId: UserPermissions_GetUsers
export def "roles-users GetUsers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Roles/($id)/Users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Role's users
#
# PUT /api/v2/Roles/{id}/Users
export def "roles-users put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Roles/($id)/Users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions
# operationId: StringDefinitions_GetDefinitions
export def "string-definitions GetDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. Ignored if 'stringIds' is provided. (format: int32)
  --modifiedAfterTimestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
  --includeTranslations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --stringText: string # Optional. The text for which to search in the StringDefinition object’s translations. Only StringDefinition objects for matching StringTranslation objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards. includeTranslations must be true.
  --descriptionText: string # Optional. The text for which to search in the StringDefinition description field. Only matching objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards.
  --useFullText: oneof<nothing, bool> # Optional. This flag is used to determin whether to use the FullText Search or not.
  --includeDeletedLanguages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --languageIds: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
  --stringIds: string # Optional. A comma-delimited list of string ids. Up to 40 string IDs may be provided. May not be used with 'modifiedAfterTimestamp', 'stringText', 'descriptionText', or 'useFullText'.
  --matchingTranslationsOnly: oneof<nothing, bool> # Optional. If false, all translations for returned String Definitions are included. Must be used with 'stringText' provided and 'includeTranslations' = true.
]: nothing -> record<Entities: table<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "modifiedAfterTimestamp" $modifiedAfterTimestamp "scalar") (serialize-qp "includeTranslations" $includeTranslations "scalar") (serialize-qp "stringText" $stringText "scalar") (serialize-qp "descriptionText" $descriptionText "scalar") (serialize-qp "useFullText" $useFullText "scalar") (serialize-qp "includeDeletedLanguages" $includeDeletedLanguages "scalar") (serialize-qp "languageIds" $languageIds "scalar") (serialize-qp "stringIds" $stringIds "scalar") (serialize-qp "matchingTranslationsOnly" $matchingTranslationsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/StringDefinitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create StringDefinition object. The originating translation must be provided. Accepts an array of StringDefinition objects. Returns nothing.
#
# POST /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_PostDefinition
export def "string-definitions-batch PostDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringDefinitions/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update StringDefinition objects. Accepts an array of StringDefinition objects. This endpoint will add StringDefinitionChange objects to the database. The DescriptionForTranslator may not be modified after a String is submitted for translation.
#
# PUT /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_UpdateDefinitions
export def "string-definitions-batch UpdateDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringDefinitions/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions/{ID}
# operationId: StringDefinitions_GetDefinition
export def "string-definitions GetDefinition" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeTranslations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --includeDeletedLanguages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --languageIds: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
]: nothing -> record<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeTranslations" $includeTranslations "scalar") (serialize-qp "includeDeletedLanguages" $includeDeletedLanguages "scalar") (serialize-qp "languageIds" $languageIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/StringDefinitions/($ID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paged response of Global String Translations.
#
# GET /api/v2/StringTranslations
# operationId: StringTranslations_GetTranslations
export def "string-translations GetTranslations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --modifiedAfterTimestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
]: nothing -> record<Entities: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "modifiedAfterTimestamp" $modifiedAfterTimestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/StringTranslations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update corrections to string translations
#
# PUT /api/v2/StringTranslations/Batch
# operationId: StringTranslations_UpdateTranslations
export def "string-translations-batch UpdateTranslations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringTranslations/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single translation based upon stringId and languageId
#
# GET /api/v2/StringTranslations/{stringId}/{languageId}
# operationId: StringTranslations_GetTranslation
export def "string-translations GetTranslation" [
  stringId: string
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/StringTranslations/($stringId)/($languageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a string value or a state for a string translation.
#
# PUT /api/v2/StringTranslations/{stringId}/{languageId}
# operationId: StringTranslations_UpdateTranslation
export def "string-translations UpdateTranslation" [
  stringId: string
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AuthorId: int # The id of the user to last edit thie translation (format: int32)
  --LanguageId: int # The id of the language of the translation (format: int32)
  --State: string@State-completer-3 # The state of the translation
  --StringId: string # The id of the string that is translated
  StringValue: string # The translated string
  --Timestamp: string # A value indicating the last modification of this translation. Read Only. (format: byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/StringTranslations/($stringId)/($languageId)")
  let body = {AuthorId: $AuthorId, LanguageId: $LanguageId, State: $State, StringId: $StringId, StringValue: $StringValue, Timestamp: $Timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a paged response of TranslationKeys.
#
# GET /api/v2/TranslationKeys
# operationId: TranslationKeys_Get
export def "translation-keys Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
  --keyNames: string # Can filter by keyNames, a comma deliminated list.
]: nothing -> record<Entities: table<ID: int, KeyName: string, StringID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "keyNames" $keyNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationKeys" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a translationKey object.
#
# POST /api/v2/TranslationKeys
# operationId: TranslationKeys_CreateTranslationKey
export def "translation-keys CreateTranslationKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ID: int # The identifier for the translationKey. Read Only. (format: int32)
  KeyName: string # The key name of the item. One example is tkODX_HWIKM14R01
  StringID: string # Foreign key to StringDefinitionID
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationKeys")
  let body = {ID: $ID, KeyName: $KeyName, StringID: $StringID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get TranslationKey by ID
#
# GET /api/v2/TranslationKeys/{ID}
# operationId: TranslationKeys_GetTranslationKey
export def "translation-keys GetTranslationKey" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ID: int, KeyName: string, StringID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationKeys/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the StringID of the translationKey object.
#
# PUT /api/v2/TranslationKeys/{ID}
# operationId: TranslationKeys_UpdateTranslationKey
export def "translation-keys UpdateTranslationKey" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-ID: int # The identifier for the translationKey. Read Only. (format: int32)
  KeyName: string # The key name of the item. One example is tkODX_HWIKM14R01
  StringID: string # Foreign key to StringDefinitionID
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationKeys/($ID)")
  let body = {ID: $body_ID, KeyName: $KeyName, StringID: $StringID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all TranslationRequest objects. Returns a PagedResponse of TranslationRequest objects with their language ids and string ids.
#
# GET /api/v2/TranslationRequests
# operationId: TranslationRequests_GetTranslationRequests
export def "translation-requests GetTranslationRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<ApprovalUserId: int, CCEmailAddresses: list, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationRequests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a translation request. Accepts a TranslationRequest object. Returns the Id of the created object. The state of the TranslationRequest must be ‘NotSubmitted’.
#
# POST /api/v2/TranslationRequests
# operationId: TranslationRequests_CreateTranslationRequest
export def "translation-requests CreateTranslationRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ApprovalUserId: int # The ID of the user from which approval for the request is required (format: int32)
  CCEmailAddresses: list # Additional email addresses to CC on emails pertaining to the request
  ChargeToAccount: string # The account to charge for the request
  Deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --Id: int # The ID of the request (format: int32)
  LocaleIds: list # Locale IDs to which these strings are requested to be translated
  Notes: string # Additional notes or comments about the request
  --QuestionsUserId: int # The ID of the user to which to address questions regarding the request (format: int32)
  State: string@State-completer-4 # The state of the request
  --SubmittedBy: int # The ID of the User that submitted the request (format: int32)
  --TranslatorEmail: string # The email address for the translator
  --TranslatorName: string # The name of the translator
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationRequests")
  let body = {ApprovalUserId: $ApprovalUserId, CCEmailAddresses: $CCEmailAddresses, ChargeToAccount: $ChargeToAccount, Deadline: $Deadline, Id: $Id, LocaleIds: $LocaleIds, Notes: $Notes, QuestionsUserId: $QuestionsUserId, State: $State, SubmittedBy: $SubmittedBy, TranslatorEmail: $TranslatorEmail, TranslatorName: $TranslatorName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a TranslationRequest object by id. Returns TranslationRequest object with its language ids and string ids.
#
# GET /api/v2/TranslationRequests/{Id}
# operationId: TranslationRequests_GetTranslationRequest
export def "translation-requests GetTranslationRequest" [
  Id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ApprovalUserId: int, CCEmailAddresses: list<string>, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list<int>, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationRequests/($Id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a TranslationRequest object by id. Accepts a TranslationRequest object.
#
# PUT /api/v2/TranslationRequests/{Id}
# operationId: TranslationRequests_UpdateTranslationRequest
export def "translation-requests UpdateTranslationRequest" [
  Id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doResendRequest: oneof<nothing, bool>
  --ApprovalUserId: int # The ID of the user from which approval for the request is required (format: int32)
  CCEmailAddresses: list # Additional email addresses to CC on emails pertaining to the request
  ChargeToAccount: string # The account to charge for the request
  Deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --body-Id: int # The ID of the request (format: int32)
  LocaleIds: list # Locale IDs to which these strings are requested to be translated
  Notes: string # Additional notes or comments about the request
  --QuestionsUserId: int # The ID of the user to which to address questions regarding the request (format: int32)
  State: string@State-completer-4 # The state of the request
  --SubmittedBy: int # The ID of the User that submitted the request (format: int32)
  --TranslatorEmail: string # The email address for the translator
  --TranslatorName: string # The name of the translator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doResendRequest" $doResendRequest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/TranslationRequests/($Id)" $qp)
  let body = {ApprovalUserId: $ApprovalUserId, CCEmailAddresses: $CCEmailAddresses, ChargeToAccount: $ChargeToAccount, Deadline: $Deadline, Id: $body_Id, LocaleIds: $LocaleIds, Notes: $Notes, QuestionsUserId: $QuestionsUserId, State: $State, SubmittedBy: $SubmittedBy, TranslatorEmail: $TranslatorEmail, TranslatorName: $TranslatorName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# PUT /api/v2/TranslationRequests/{Id}/Strings
# operationId: TranslationRequests_UpdateTranslationRequestStrings
export def "translation-requests-strings UpdateTranslationRequestStrings" [
  Id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationRequests/($Id)/Strings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSetAttributes/Batch
# operationId: TranslationSets_UpdateTranslationSetAttributes
export def "translation-set-attributes-batch UpdateTranslationSetAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationSetAttributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a set of TranslationSetAttribute object
#
# DELETE /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_DeleteTranslationSetAttribute
export def "translation-set-attributes DeleteTranslationSetAttribute" [
  ID: int
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
  let full_url = (build-url $base $"/api/v2/TranslationSetAttributes/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a TranslationSetAttribute object
#
# PUT /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_UpdateTranslationSetAttribute
export def "translation-set-attributes UpdateTranslationSetAttribute" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --TranslationSetID: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --Value: string # The value of this Attribute
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSetAttributes/($ID)")
  let body = {ID: $body_ID, Name: $Name, TranslationSetID: $TranslationSetID, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a PagedResponse of TranslationSet objects. Related TranslationSetStrings are NOT returned
#
# GET /api/v2/TranslationSets
# operationId: TranslationSets_GetTranslationSets
export def "translation-sets GetTranslationSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
  --translationRequestID: int # format: int32
  --state: string@state-completer
  --stringId: string
  --languageId: int # format: int32
  --includeAttributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Entities: table<Attributes: list, FileIDs: list, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "translationRequestID" $translationRequestID "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stringId" $stringId "scalar") (serialize-qp "languageId" $languageId "scalar") (serialize-qp "includeAttributes" $includeAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationSets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a TranslationSet object by its id. Related TranslationSetStrings are NOT returned.
#
# GET /api/v2/TranslationSets/{ID}
# operationId: TranslationSets_GetTranslationSet
export def "translation-sets GetTranslationSet" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeAttributes: string # Names of Attributes to include when retrieving this Translation set. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Attributes: table<ID: int, Name: string, TranslationSetID: int, Value: string>, FileIDs: list<string>, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAttributes" $includeAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Translation Set. Accepts a TranslationSet object. Only the state property may be updated.
#
# PUT /api/v2/TranslationSets/{ID}
# operationId: TranslationSets_UpdateTranslationSet
# --Attributes item shape: {ID?: int, Name: string, TranslationSetID?: int, Value?: string}
export def "translation-sets UpdateTranslationSet" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: list # Attributes of the Translation Set — item shape: {ID?: int, Name: string, TranslationSetID?: int, Value?: string}
  FileIDs: list # IDs for files related to this translation set. For example, the original and processed files
  --Id: int # The id of the TranslationSet. (format: int32)
  --InDate: string # Read Only. The date the translation set was returned. (format: date-time)
  --Notes: string # Notes on the TranslationSet
  --OutDate: string # Read Only. The date the translation set was sent out. (format: date-time)
  State: string@State-completer-5 # An enum indicating the state of the translation set
  --TranslationRequestID: int # Read Only. The Id of the TranslationRequest which generated this translation set. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)")
  let body = {Attributes: $Attributes, FileIDs: $FileIDs, Id: $Id, InDate: $InDate, Notes: $Notes, OutDate: $OutDate, State: $State, TranslationRequestID: $TranslationRequestID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a PagedResponse of TranslationSetAttribute objects
#
# GET /api/v2/TranslationSets/{ID}/Attributes
# operationId: TranslationSets_GetTranslationSetAttributes
export def "translation-sets-attributes GetTranslationSetAttributes" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
  --name: string
]: nothing -> record<Entities: table<ID: int, Name: string, TranslationSetID: int, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a TranslationSetAttribute object
#
# POST /api/v2/TranslationSets/{ID}/Attributes
# operationId: TranslationSets_PostTranslationSetAttribute
export def "translation-sets-attributes PostTranslationSetAttribute" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-ID: int # The ID of this attribute. (format: int32)
  Name: string # The name of this Attribute.
  --TranslationSetID: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --Value: string # The value of this Attribute
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Attributes")
  let body = {ID: $body_ID, Name: $Name, TranslationSetID: $TranslationSetID, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# POST /api/v2/TranslationSets/{ID}/Attributes/Batch
# operationId: TranslationSets_PostTranslationSetAttributes
export def "translation-sets-attributes-batch PostTranslationSetAttributes" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Attributes/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the information needed to translate a string in a translation set
#
# GET /api/v2/TranslationSets/{ID}/SourceStrings
# operationId: TranslationSets_GetSourceStrings
export def "translation-sets-source-strings GetSourceStrings" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<DescriptionForTranslator: string, LanguageID: int, StringID: string, StringValue: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/SourceStrings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the statistics for translation sets such as the language ids and count of string definitions.
#
# GET /api/v2/TranslationSets/{ID}/Statistics
# operationId: TranslationSets_GetStatistics
export def "translation-sets-statistics GetStatistics" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<LanguageIDs: list<int>, StringCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Statistics")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a PagedResponse of TranslationSetString objects
#
# GET /api/v2/TranslationSets/{ID}/Strings
# operationId: TranslationSets_GetTranslationSetStrings
export def "translation-sets-strings GetTranslationSetStrings" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<LanguageID: int, StringID: string, StringValue: string, TranslationSetId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Strings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSets/{ID}/Strings
# operationId: TranslationSets_UpdateTranslationSetStrings
export def "translation-sets-strings UpdateTranslationSetStrings" [
  ID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/TranslationSets/($ID)/Strings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_GetSubscriptions
export def "update-group-client-relationships GetSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --ClientID: string # Optional. Filter by Client ID
  --UpdateGroupID: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --Active: oneof<nothing, bool> # Optional. Filter by Active
]: nothing -> record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "Active" $Active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a subscription
#
# POST /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_PostSubscription
export def "update-group-client-relationships PostSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Active: oneof<nothing, bool> # The subscription status.  The status is active by default.
  ClientID: string # Read Only after creation. The client id of the subscriber.
  --LastCheckin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --RelationshipID: string # Read Only after creation. The relationship id.  A relationship id will be assigned if not provided on creation.
  UpdateGroupID: string # Read Only after creation. The update group to subscribe to.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships")
  let body = {Active: $Active, ClientID: $ClientID, LastCheckin: $LastCheckin, RelationshipID: $RelationshipID, UpdateGroupID: $UpdateGroupID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEPRECATED. Set client subscription status for an update group.
#
# PUT /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_PutSubscriptionByClientIDUpdateGroupID
export def "update-group-client-relationships PutSubscriptionByClientIDUpdateGroupID" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientID: string # The Client ID.  This can be a client ID that has not been registered yet.
  --UpdateGroupID: string # The Update Group ID
  --Active: oneof<nothing, bool> # Subscribe the client to the Update Group.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "Active" $Active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subscription by RelationshipID
#
# GET /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# operationId: UpdateGroupClientRelationships_GetSubscription
export def "update-group-client-relationships GetSubscription" [
  RelationshipID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroupClientRelationships/($RelationshipID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Subscription
#
# PUT /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# operationId: UpdateGroupClientRelationships_PutSubscription
export def "update-group-client-relationships PutSubscription" [
  RelationshipID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Active: oneof<nothing, bool> # The subscription status.  The status is active by default.
  ClientID: string # Read Only after creation. The client id of the subscriber.
  --LastCheckin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --body-RelationshipID: string # Read Only after creation. The relationship id.  A relationship id will be assigned if not provided on creation.
  UpdateGroupID: string # Read Only after creation. The update group to subscribe to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroupClientRelationships/($RelationshipID)")
  let body = {Active: $Active, ClientID: $ClientID, LastCheckin: $LastCheckin, RelationshipID: $body_RelationshipID, UpdateGroupID: $UpdateGroupID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Update Group Subscriptions
#
# GET /api/v2/UpdateGroupSubscriptions
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscriptions
export def "update-group-subscriptions GetUpdateGroupSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --UpdateGroupID: string # Optional. Filter by Update Group ID.
  --PackageTypeID: string # Optional. Filter by Package Type ID.
  --ClientID: string # Optional. Filter by Client ID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $UpdateGroupID "scalar") (serialize-qp "PackageTypeID" $PackageTypeID "scalar") (serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an Update Group Subscription
#
# POST /api/v2/UpdateGroupSubscriptions
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscription
export def "update-group-subscriptions PostUpdateGroupSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  ClientID: string # The ClientID.
  --Include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  PackageTypeID: string # The PackageType to set subscription status for
  UpdateGroupID: string # The Update Group this subscription is relevant for.
  --UpdateGroupSubscriptionID: int # The Update Group Subscription ID.  This ID will be automatically assigned when creating an Update Group Subscription. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions")
  let body = {ClientID: $ClientID, Include: $Include, PackageTypeID: $PackageTypeID, UpdateGroupID: $UpdateGroupID, UpdateGroupSubscriptionID: $UpdateGroupSubscriptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# POST /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscriptions
export def "update-group-subscriptions-batch PostUpdateGroupSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No Documentation Found.
#
# PUT /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscriptions
export def "update-group-subscriptions-batch PutUpdateGroupSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions/Batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Update Group Subscription
#
# DELETE /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_DeleteUpdateGroupSubscription
export def "update-group-subscriptions DeleteUpdateGroupSubscription" [
  UpdateGroupSubscriptionID: int
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
  let full_url = (build-url $base $"/api/v2/UpdateGroupSubscriptions/($UpdateGroupSubscriptionID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Update Group Subscription
#
# GET /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscription
export def "update-group-subscriptions GetUpdateGroupSubscription" [
  UpdateGroupSubscriptionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroupSubscriptions/($UpdateGroupSubscriptionID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Update Group Subscription
#
# PUT /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscription
export def "update-group-subscriptions PutUpdateGroupSubscription" [
  UpdateGroupSubscriptionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ClientID: string # The ClientID.
  --Include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  PackageTypeID: string # The PackageType to set subscription status for
  UpdateGroupID: string # The Update Group this subscription is relevant for.
  --body-UpdateGroupSubscriptionID: int # The Update Group Subscription ID.  This ID will be automatically assigned when creating an Update Group Subscription. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroupSubscriptions/($UpdateGroupSubscriptionID)")
  let body = {ClientID: $ClientID, Include: $Include, PackageTypeID: $PackageTypeID, UpdateGroupID: $UpdateGroupID, UpdateGroupSubscriptionID: $body_UpdateGroupSubscriptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of Update Groups.  Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/UpdateGroups
# operationId: UpdateGroups_Get
export def "update-groups Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --userID: int # Optional. The user ID to sort update groups by the user's access (format: int32)
]: nothing -> record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new Update Group.  The report field is a string that has a dot based request for a specific piece of submitted data.
#
# POST /api/v2/UpdateGroups
# operationId: UpdateGroups_Post
export def "update-groups Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  Description: string # The description of the update group
  --ID: string
  --InventoryFrequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --InventoryPackage: string # The Package ID of the package used for inventory
  --LocalizedDescription: string # Optional. The StringID used to localize the description of the update group
  --LocalizedName: string # Optional. The StringID used to localize the name of the update group
  Priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --ReportField: string # A field to return in the status report for this update group.             Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}.  (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  UpdateType: string # The update type name
  --ValidatingField: string # A field used for validation in the status report for this update group.             Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}.  (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --ValueToValidate: string # The value to validate the ValidationField against.
  --Version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroups")
  let body = {Description: $Description, ID: $ID, InventoryFrequency: $InventoryFrequency, InventoryPackage: $InventoryPackage, LocalizedDescription: $LocalizedDescription, LocalizedName: $LocalizedName, Priority: $Priority, ReportField: $ReportField, UpdateType: $UpdateType, ValidatingField: $ValidatingField, ValueToValidate: $ValueToValidate, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Update Group.
#
# DELETE /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Delete
export def "update-groups Delete" [
  ID: string
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
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($ID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Update Group by ID.
#
# GET /api/v2/UpdateGroups/{ID}
export def "update-groups get" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($ID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an Update Group.
#
# PUT /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Put
export def "update-groups Put" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Description: string # The description of the update group
  --body-ID: string
  --InventoryFrequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --InventoryPackage: string # The Package ID of the package used for inventory
  --LocalizedDescription: string # Optional. The StringID used to localize the description of the update group
  --LocalizedName: string # Optional. The StringID used to localize the name of the update group
  Priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --ReportField: string # A field to return in the status report for this update group.             Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}.  (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  UpdateType: string # The update type name
  --ValidatingField: string # A field used for validation in the status report for this update group.             Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}.  (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --ValueToValidate: string # The value to validate the ValidationField against.
  --Version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($ID)")
  let body = {Description: $Description, ID: $body_ID, InventoryFrequency: $InventoryFrequency, InventoryPackage: $InventoryPackage, LocalizedDescription: $LocalizedDescription, LocalizedName: $LocalizedName, Priority: $Priority, ReportField: $ReportField, UpdateType: $UpdateType, ValidatingField: $ValidatingField, ValueToValidate: $ValueToValidate, Version: $Version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/UpdateGroups/{ID}/Bundles
# operationId: UpdateGroups_GetUpdateGroupBundles
export def "update-groups-bundles GetUpdateGroupBundles" [
  ID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --IncludeInactive: oneof<nothing, bool> # Include Inactive Bundles (true|false)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeInactive" $IncludeInactive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($ID)/Bundles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an update group a user could see.
#
# DELETE /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_RemoveUpdateGroupUser
export def "update-groups-users RemoveUpdateGroupUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an updateGroup that a user can see.
#
# POST /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_AddUpdateGroupUser
export def "update-groups-users AddUpdateGroupUser" [
  id: string
  userID: int
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
  let full_url = (build-url $base $"/api/v2/UpdateGroups/($id)/Users/($userID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks the Client ID into the Update System.
#
# GET /api/v2/UpdateSystem
# operationId: UpdateSystem_GetCheckin
export def "update-system GetCheckin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ClientID: string # The Client ID to check-in.  If this is a new client ID it will be added to Clients.
  --Preview: oneof<nothing, bool> # Get Pkgs w\o updating Datetimes(true|false)
  --RunAllInventories: oneof<nothing, bool> # Force return inventories. Defaults to false.
]: nothing -> record<Packages: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, RemovePackages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $ClientID "scalar") (serialize-qp "Preview" $Preview "scalar") (serialize-qp "RunAllInventories" $RunAllInventories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateSystem" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get UserContentDefinitions
#
# GET /api/v2/UserContentDefinitions
# operationId: UserContentDefinitions_GetUserContentDefinitions
export def "user-content-definitions GetUserContentDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --userID: int # Optional. Filter by UserID. (format: int32)
  --contentDefinitionID: int # Optional. Filter by ContentDefinitionID (format: int32)
]: nothing -> record<Entities: table<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $userID "scalar") (serialize-qp "contentDefinitionID" $contentDefinitionID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UserContentDefinitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a UserContentDefinition
#
# POST /api/v2/UserContentDefinitions
# operationId: UserContentDefinitions_PostUserContentDefinition
export def "user-content-definitions PostUserContentDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ContentDefinitionID: int # The ID of the ContentDefinition. (format: int32)
  --UserContentDefinitionID: int # Read Only. The ID of the User to ContentDefinition relationship. (format: int32)
  --UserID: int # The ID of the user. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UserContentDefinitions")
  let body = {ContentDefinitionID: $ContentDefinitionID, UserContentDefinitionID: $UserContentDefinitionID, UserID: $UserID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a UserContentDefinition
#
# DELETE /api/v2/UserContentDefinitions/{userContentDefinitionID}
# operationId: UserContentDefinitions_DeleteUserContentDefinition
export def "user-content-definitions DeleteUserContentDefinition" [
  userContentDefinitionID: int
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
  let full_url = (build-url $base $"/api/v2/UserContentDefinitions/($userContentDefinitionID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a UserContentDefinition by ID
#
# GET /api/v2/UserContentDefinitions/{userContentDefinitionID}
# operationId: UserContentDefinitions_GetUserContentDefinition
export def "user-content-definitions GetUserContentDefinition" [
  userContentDefinitionID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/UserContentDefinitions/($userContentDefinitionID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users
#
# GET /api/v2/Users
# operationId: Users_Get
export def "users Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --username: string # Optional. Search by username. Supports beginning and ending wildcards (*).
  --email: string # Optional. Search by email. Supports beginning and ending wildcards (*).
  --name: string # Optional. Search by name. Supports beginning and ending wildcards (*).
  --hasRole: string # Optional. Return only users having the provided role name.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "hasRole" $hasRole "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /api/v2/Users
# operationId: Users_Post
export def "users Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ChangePassword: string # Never Returned.  When changing a user's password, this field must contain the new password.
  --Email: string # The user's email address
  --Name: string # The user's name
  --Password: string # Never Returned.  Required when creating a new user or updating a user.  When changing a user's password this field must contain the current password.
  --UserID: int # The user ID (format: int32)
  --Username: string # The username used for authentication
]: any -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users")
  let body = {ChangePassword: $ChangePassword, Email: $Email, Name: $Name, Password: $Password, UserID: $UserID, Username: $Username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the current user
#
# GET /api/v2/Users/Current
# operationId: Users_GetCurrentUser
export def "users-current GetCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users/Current")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api/v2/Users/Current
# operationId: Users_PutCurrentUser
export def "users-current PutCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChangePassword: string # Never Returned.  When changing a user's password, this field must contain the new password.
  --Email: string # The user's email address
  --Name: string # The user's name
  --Password: string # Never Returned.  Required when creating a new user or updating a user.  When changing a user's password this field must contain the current password.
  --UserID: int # The user ID (format: int32)
  --Username: string # The username used for authentication
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users/Current")
  let body = {ChangePassword: $ChangePassword, Email: $Email, Name: $Name, Password: $Password, UserID: $UserID, Username: $Username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a user's permissions
#
# GET /api/v2/Users/Current/Permissions
export def "users-current-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Permission" $Permission "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users/Current/Permissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the current user's roles
#
# GET /api/v2/Users/Current/Roles
# operationId: UserPermissions_GetCurrentUserRoles
export def "users-current-roles GetCurrentUserRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Role" $Role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users/Current/Roles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /api/v2/Users/{id}
# operationId: Users_Delete
export def "users Delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific user
#
# GET /api/v2/Users/{id}
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Users/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api/v2/Users/{id}
# operationId: Users_Put
export def "users Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChangePassword: string # Never Returned.  When changing a user's password, this field must contain the new password.
  --Email: string # The user's email address
  --Name: string # The user's name
  --Password: string # Never Returned.  Required when creating a new user or updating a user.  When changing a user's password this field must contain the current password.
  --UserID: int # The user ID (format: int32)
  --Username: string # The username used for authentication
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Users/($id)")
  let body = {ChangePassword: $ChangePassword, Email: $Email, Name: $Name, Password: $Password, UserID: $UserID, Username: $Username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a user's permissions
#
# GET /api/v2/Users/{id}/Permissions
# operationId: UserPermissions_GetPermissions
export def "users-permissions GetPermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Permission" $Permission "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Users/($id)/Permissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's roles
#
# GET /api/v2/Users/{id}/Roles
# operationId: UserPermissions_GetRoles
export def "users-roles GetRoles" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Role" $Role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Users/($id)/Roles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user's roles
#
# PUT /api/v2/Users/{id}/Roles
# operationId: UserPermissions_Put
export def "users-roles Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Users/($id)/Roles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets voucher history data
#
# GET /api/v2/VoucherHistory
# operationId: VoucherHistory_GetVoucherHistory
export def "voucher-history GetVoucherHistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --VoucherCode: string # Optional. Filter history data by Voucher Code.
  --ChangedBefore: string # Optional. Filter history data where changes occured before provided date. (format: date-time)
  --ChangedAfter: string # Optional. Filter history data where changes occured after provided date. (format: date-time)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "VoucherCode" $VoucherCode "scalar") (serialize-qp "ChangedBefore" $ChangedBefore "scalar") (serialize-qp "ChangedAfter" $ChangedAfter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/VoucherHistory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of vouchers
#
# GET /api/v2/Vouchers
# operationId: Vouchers_Get
export def "vouchers Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Type: string@Type-completer # Optional. Filter vouchers by Type
  --DealerCode: string # Optional. Filter vouchers by DealerCode
  --LicenseTo: string # Optional. Filter vouchers by LicenseTo. Wildcard supported (*).
  --Purpose: string # Optional. Filter vouchers by Purpose. Wildcard supported (*).
  --OrderNumber: string # Optional. Filter vouchers by OrderNumber
  --Email: string # Optional. Filter vouchers by Email. Wildcard supported (*).
  --ModifiedBy: string # Optional. Filter vouchers by ModifiedBy
  --CreatedAfter: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --CreatedBefore: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --PunchedAfter: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --PunchedBefore: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --Punched: oneof<nothing, bool> # Optional. Filter vouchers by Punched status
  --ExpirationAfter: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --ExpirationBefore: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --Deleted: string@Deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Type" $Type "scalar") (serialize-qp "DealerCode" $DealerCode "scalar") (serialize-qp "LicenseTo" $LicenseTo "scalar") (serialize-qp "Purpose" $Purpose "scalar") (serialize-qp "OrderNumber" $OrderNumber "scalar") (serialize-qp "Email" $Email "scalar") (serialize-qp "ModifiedBy" $ModifiedBy "scalar") (serialize-qp "CreatedAfter" $CreatedAfter "scalar") (serialize-qp "CreatedBefore" $CreatedBefore "scalar") (serialize-qp "PunchedAfter" $PunchedAfter "scalar") (serialize-qp "PunchedBefore" $PunchedBefore "scalar") (serialize-qp "Punched" $Punched "scalar") (serialize-qp "ExpirationAfter" $ExpirationAfter "scalar") (serialize-qp "ExpirationBefore" $ExpirationBefore "scalar") (serialize-qp "Deleted" $Deleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Vouchers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a voucher
#
# POST /api/v2/Vouchers
# operationId: Vouchers_Post
export def "vouchers Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CreatedDate: string # Read-Only. The date the voucher was created. (format: date-time)
  --DealerCode: string # The dealer code the voucher is assigned to.  Required for commercial and right to repair vouchers.
  --Deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --Email: string # Required for internal vouchers.
  --ExpirationDate: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --LicenseTo: string # Required for Internal Vouchers
  --ModifiedBy: string # Read-Only. The user that made the last modification to the voucher.
  --OrderNumber: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --Punched: oneof<nothing, bool> # True if voucher has aleady been used.  False if the voucher has not been used.
  --PunchedDate: string # Read-Only. The date the voucher was punched. (format: date-time)
  --Purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --Type: string@Type-completer # The type of voucher. Commercial is the default if not specified.
  --VoucherCode: string # The voucher code.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Vouchers")
  let body = {CreatedDate: $CreatedDate, DealerCode: $DealerCode, Deleted: $Deleted, Email: $Email, ExpirationDate: $ExpirationDate, LicenseTo: $LicenseTo, ModifiedBy: $ModifiedBy, OrderNumber: $OrderNumber, Punched: $Punched, PunchedDate: $PunchedDate, Purpose: $Purpose, Type: $Type, VoucherCode: $VoucherCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a voucher
#
# DELETE /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Delete
export def "vouchers Delete" [
  VoucherCode: string
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
  let full_url = (build-url $base $"/api/v2/Vouchers/($VoucherCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a voucher
#
# GET /api/v2/Vouchers/{VoucherCode}
export def "vouchers get" [
  VoucherCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Deleted: string@Deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
]: nothing -> record<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Deleted" $Deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Vouchers/($VoucherCode)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a voucher
#
# PUT /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Put
export def "vouchers Put" [
  VoucherCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CreatedDate: string # Read-Only. The date the voucher was created. (format: date-time)
  --DealerCode: string # The dealer code the voucher is assigned to.  Required for commercial and right to repair vouchers.
  --Deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --Email: string # Required for internal vouchers.
  --ExpirationDate: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --LicenseTo: string # Required for Internal Vouchers
  --ModifiedBy: string # Read-Only. The user that made the last modification to the voucher.
  --OrderNumber: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --Punched: oneof<nothing, bool> # True if voucher has aleady been used.  False if the voucher has not been used.
  --PunchedDate: string # Read-Only. The date the voucher was punched. (format: date-time)
  --Purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --Type: string@Type-completer # The type of voucher. Commercial is the default if not specified.
  --body-VoucherCode: string # The voucher code.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/Vouchers/($VoucherCode)")
  let body = {CreatedDate: $CreatedDate, DealerCode: $DealerCode, Deleted: $Deleted, Email: $Email, ExpirationDate: $ExpirationDate, LicenseTo: $LicenseTo, ModifiedBy: $ModifiedBy, OrderNumber: $OrderNumber, Punched: $Punched, PunchedDate: $PunchedDate, Purpose: $Purpose, Type: $Type, VoucherCode: $body_VoucherCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a voucher's history.
#
# GET /api/v2/Vouchers/{VoucherCode}/VoucherHistory
# operationId: Vouchers_GetVoucherHistory
export def "vouchers-voucher-history GetVoucherHistory" [
  VoucherCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/Vouchers/($VoucherCode)/VoucherHistory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Activities
#
# GET /api/v2/activities
# operationId: Activities_GetActivities
export def "activities GetActivities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --isIncludeDeleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> record<Entities: table<ActivityID: int, Deleted: bool, Name: string, Parameters: list, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isIncludeDeleted" $isIncludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/activities" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Activity
#
# POST /api/v2/activities
# operationId: Activities_PostActivity
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activities PostActivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ActivityID: int # The ID of the activity (format: int32)
  --Deleted: oneof<nothing, bool>
  --Name: string # The name of the activity
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/activities")
  let body = {ActivityID: $ActivityID, Deleted: $Deleted, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark the delete flag for the Activity
#
# DELETE /api/v2/activities/{activityID}
# operationId: Activities_DeleteActivity
export def "activities DeleteActivity" [
  activityID: int
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
  let full_url = (build-url $base $"/api/v2/activities/($activityID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Activity by ID
#
# GET /api/v2/activities/{activityID}
# operationId: Activities_GetActivity
export def "activities GetActivity" [
  activityID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isIncludeDeleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> record<ActivityID: int, Deleted: bool, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIncludeDeleted" $isIncludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/activities/($activityID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Activity
#
# PUT /api/v2/activities/{activityID}
# operationId: Activities_PutActivity
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activities PutActivity" [
  activityID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ActivityID: int # The ID of the activity (format: int32)
  --Deleted: oneof<nothing, bool>
  --Name: string # The name of the activity
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activities/($activityID)")
  let body = {ActivityID: $ActivityID, Deleted: $Deleted, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ActivityRuns
#
# GET /api/v2/activityRuns
# operationId: ActivityRuns_GetActivityRuns
export def "activity-runs GetActivityRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --status: string@status-completer # Optional. Filter activity runs by status.  Value should be a comma separated list of status to include.             If not specified, the default status filter is “InProgress”.
]: nothing -> record<Entities: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/activityRuns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an ActivityRun by ID
#
# GET /api/v2/activityRuns/{activityRunID}
# operationId: ActivityRuns_GetActivityRun
export def "activity-runs GetActivityRun" [
  activityRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activityRuns/($activityRunID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}
# operationId: ActivityRuns_PutActivityRun
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
# --Status shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activity-runs PutActivityRun" [
  activityRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ActivityRunID: int # The identifier for the ActivityRun (format: int32)
  --EndDate: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --JobActivityID: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --JobRunID: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --StartDate: string # Read Only. The UTC date and time when the activity started (format: date-time)
  Status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activityRuns/($activityRunID)")
  let body = {ActivityRunID: $ActivityRunID, EndDate: $EndDate, JobActivityID: $JobActivityID, JobRunID: $JobRunID, StartDate: $StartDate, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the ActivityRunStatus of an ActivityRun
#
# GET /api/v2/activityRuns/{activityRunID}/status
# operationId: ActivityRuns_GetActivityRunStatus
export def "activity-runs-status GetActivityRunStatus" [
  activityRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activityRuns/($activityRunID)/status")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the ActivityRunStatus of an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}/status
# operationId: ActivityRuns_PutActivityRunStatus
export def "activity-runs-status PutActivityRunStatus" [
  activityRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CurrentStep: int # The activity step currently executing, indicated by numeric order (format: int32)
  --Status: string@Status-completer-2 # The status of the ActivityRun
  --StepProgress: int # The percent progress from the currently executing step.  This value shall be null if progress is not available (format: int32)
  --StepStatus: string # The status text from the currently executing step
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activityRuns/($activityRunID)/status")
  let body = {CurrentStep: $CurrentStep, Status: $Status, StepProgress: $StepProgress, StepStatus: $StepStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Agents
#
# GET /api/v2/agents
# operationId: Agents_GetAgents
export def "agents GetAgents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record, StepConfigurations: list, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/agents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Agent
#
# POST /api/v2/agents
# operationId: Agents_PostAgent
# --Status shape: {LastStatusUpdate?: string, Online: bool}
# --StepConfigurations item shape: {Configurations?: list, StepImplementationID: string}
export def "agents PostAgent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AgentID: int # The id of the Agent (format: int32)
  KeepAliveInterval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  MachineName: string # The machine name of the computer the agent is running on
  Status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  UserID: int # The UserID of the Agent (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents")
  let body = {AgentID: $AgentID, KeepAliveInterval: $KeepAliveInterval, MachineName: $MachineName, Status: $Status, UserID: $UserID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Agent associated with the current user
#
# GET /api/v2/agents/Current
# operationId: Agents_GetCurrentAgentAsync
export def "agents-current GetCurrentAgentAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents/Current")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the ActivityRun of Agent associated with the current user
#
# GET /api/v2/agents/Current/ActivityRun
# operationId: Agents_GetCurrentAgentActivityRun
export def "agents-current-activity-run GetCurrentAgentActivityRun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents/Current/ActivityRun")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Agent
#
# DELETE /api/v2/agents/{agentID}
# operationId: Agents_DeleteAgent
export def "agents DeleteAgent" [
  agentID: int
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
  let full_url = (build-url $base $"/api/v2/agents/($agentID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Agent
#
# GET /api/v2/agents/{agentID}
# operationId: Agents_GetAgentAsync
export def "agents GetAgentAsync" [
  agentID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/agents/($agentID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Agent
#
# PUT /api/v2/agents/{agentID}
# operationId: Agents_PutAgent
# --Status shape: {LastStatusUpdate?: string, Online: bool}
# --StepConfigurations item shape: {Configurations?: list, StepImplementationID: string}
export def "agents PutAgent" [
  agentID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AgentID: int # The id of the Agent (format: int32)
  KeepAliveInterval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  MachineName: string # The machine name of the computer the agent is running on
  Status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  UserID: int # The UserID of the Agent (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/agents/($agentID)")
  let body = {AgentID: $AgentID, KeepAliveInterval: $KeepAliveInterval, MachineName: $MachineName, Status: $Status, UserID: $UserID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an Agent's ActivityRun
#
# GET /api/v2/agents/{agentID}/ActivityRun
# operationId: Agents_GetAgentActivityRun
export def "agents-activity-run GetAgentActivityRun" [
  agentID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/agents/($agentID)/ActivityRun")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the ActivityRun assigned to the Agent.
#
# PUT /api/v2/agents/{agentID}/ActivityRun
# operationId: Agents_PutAgentActivityRun
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
# --Status shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "agents-activity-run PutAgentActivityRun" [
  agentID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ActivityRunID: int # The identifier for the ActivityRun (format: int32)
  --EndDate: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --JobActivityID: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --JobRunID: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --StartDate: string # Read Only. The UTC date and time when the activity started (format: date-time)
  Status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/agents/($agentID)/ActivityRun")
  let body = {ActivityRunID: $ActivityRunID, EndDate: $EndDate, JobActivityID: $JobActivityID, JobRunID: $JobRunID, StartDate: $StartDate, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an Agent
#
# PUT /api/v2/agents/{agentID}/Status
# operationId: Agents_PutAgentStatus
export def "agents-status PutAgentStatus" [
  agentID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LastStatusUpdate: string # ReadOnly. The UTC date and time of the last status update (format: date-time)
  --Online: oneof<nothing, bool> # Indicates if the agent is online
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/agents/($agentID)/Status")
  let body = {LastStatusUpdate: $LastStatusUpdate, Online: $Online} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get JobRuns
#
# GET /api/v2/jobRuns
# operationId: JobRuns_GetJobRuns
export def "job-runs GetJobRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --includeActivityRunDetails: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details.  Defaults to false.
]: nothing -> record<Entities: table<ActivityRuns: list, EndDate: string, JobID: int, JobRunID: int, Parameters: list, StartDate: string, Status: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeActivityRunDetails" $includeActivityRunDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/jobRuns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a JobRun
#
# POST /api/v2/jobRuns
# operationId: JobRuns_PostJobRun
# --ActivityRuns item shape: {ActivityRunID?: int, EndDate?: string, JobActivityID?: int, JobRunID?: int, StartDate?: string, Status: record}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
export def "job-runs PostJobRun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EndDate: string # The UTC date and time when the job completed (format: date-time)
  --JobID: int # The ID of the job that defines the run (format: int32)
  --JobRunID: int # The ID of this JobRun (format: int32)
  --StartDate: string # The UTC date and time when the job started (format: date-time)
  --Status: string@Status-completer-2 # The status of this JobRun
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/jobRuns")
  let body = {EndDate: $EndDate, JobID: $JobID, JobRunID: $JobRunID, StartDate: $StartDate, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a JobRun
#
# DELETE /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_DeleteJobRun
export def "job-runs DeleteJobRun" [
  jobRunID: int
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
  let full_url = (build-url $base $"/api/v2/jobRuns/($jobRunID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a JobRun by ID
#
# GET /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_GetJobRun
export def "job-runs GetJobRun" [
  jobRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --includeActivityRunDetails: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details.  Defaults to false.
]: nothing -> record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeActivityRunDetails" $includeActivityRunDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/jobRuns/($jobRunID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a JobRun
#
# PUT /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_PutJobRun
# --ActivityRuns item shape: {ActivityRunID?: int, EndDate?: string, JobActivityID?: int, JobRunID?: int, StartDate?: string, Status: record}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
export def "job-runs PutJobRun" [
  jobRunID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # The UTC date and time when the job completed (format: date-time)
  --JobID: int # The ID of the job that defines the run (format: int32)
  --JobRunID: int # The ID of this JobRun (format: int32)
  --StartDate: string # The UTC date and time when the job started (format: date-time)
  --Status: string@Status-completer-2 # The status of this JobRun
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/jobRuns/($jobRunID)")
  let body = {EndDate: $EndDate, JobID: $JobID, JobRunID: $JobRunID, StartDate: $StartDate, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Jobs
#
# GET /api/v2/jobs
# operationId: Jobs_GetJobs
export def "jobs GetJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --isIncludeDeleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> record<Entities: table<Activities: list, Deleted: bool, JobID: int, Name: string, Parameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isIncludeDeleted" $isIncludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/jobs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Job
#
# POST /api/v2/jobs
# operationId: Jobs_PostJob
# --Activities item shape: {ActivityID?: int, JobActivityID?: int, JobID?: int, RunOrder?: int}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "jobs PostJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --JobID: int # The ID of the job (format: int32)
  --Name: string # The name of the job
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/jobs")
  let body = {Deleted: $Deleted, JobID: $JobID, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark the delete flag for the Job
#
# DELETE /api/v2/jobs/{jobID}
# operationId: Jobs_DeleteJob
export def "jobs DeleteJob" [
  jobID: int
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
  let full_url = (build-url $base $"/api/v2/jobs/($jobID)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Job by ID
#
# GET /api/v2/jobs/{jobID}
# operationId: Jobs_GetJob
export def "jobs GetJob" [
  jobID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isIncludeDeleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> record<Activities: table<ActivityID: int, JobActivityID: int, JobID: int, ParameterMappings: list, RunOrder: int>, Deleted: bool, JobID: int, Name: string, Parameters: table<Direction: string, Name: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIncludeDeleted" $isIncludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/jobs/($jobID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Job
#
# PUT /api/v2/jobs/{jobID}
# operationId: Jobs_PutJob
# --Activities item shape: {ActivityID?: int, JobActivityID?: int, JobID?: int, RunOrder?: int}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "jobs PutJob" [
  jobID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --JobID: int # The ID of the job (format: int32)
  --Name: string # The name of the job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/jobs/($jobID)")
  let body = {Deleted: $Deleted, JobID: $JobID, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Steps
#
# GET /api/v2/steps
# operationId: Steps_GetSteps
export def "steps GetSteps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --limit: int # Optional. The page limit.  If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset.  If not specified, the default page offset is 0. (format: int32)
  --includeDeleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> record<Entities: table<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: list, StepID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/steps" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Step
#
# POST /api/v2/steps
# operationId: Steps_PostStep
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "steps PostStep" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ConfigRequired: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --Deleted: oneof<nothing, bool> # Read Only.  Indicates if the record is deleted.
  --Description: string # A description of the step to be presented to a user
  ImplementationID: string # The implementation ID used to lookup the step implementation when it is executed
  Name: string # The name of the step
  --StepID: int # The ID of the step (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/steps")
  let body = {ConfigRequired: $ConfigRequired, Deleted: $Deleted, Description: $Description, ImplementationID: $ImplementationID, Name: $Name, StepID: $StepID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Step by ID
#
# GET /api/v2/steps/{stepID}
# operationId: Steps_GetStep
export def "steps GetStep" [
  stepID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isIncludeDeleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> record<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, StepID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIncludeDeleted" $isIncludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/steps/($stepID)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Step
#
# PUT /api/v2/steps/{stepID}
# operationId: Steps_PutStep
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "steps PutStep" [
  stepID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ConfigRequired: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --Deleted: oneof<nothing, bool> # Read Only.  Indicates if the record is deleted.
  --Description: string # A description of the step to be presented to a user
  ImplementationID: string # The implementation ID used to lookup the step implementation when it is executed
  Name: string # The name of the step
  --StepID: int # The ID of the step (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/steps/($stepID)")
  let body = {ConfigRequired: $ConfigRequired, Deleted: $Deleted, Description: $Description, ImplementationID: $ImplementationID, Name: $Name, StepID: $StepID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
