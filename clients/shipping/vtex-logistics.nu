# Auto-generated client for Logistics API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Logistics-API/1.0/openapi.json
# Auth: --token flag or $env.LOGISTICS_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOGISTICS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames get-by-capacityType-shippingPolicyId" } } | get name | first)
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

# Search capacity reservations in time range
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames
export def "logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames get-by-capacityType-shippingPolicyId" [
  capacityType: string
  shippingPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rangeStart: string # Starting date of time range (e.g. yyyy-mm-dd)
  --rangeEnd: string # End date of time range. (e.g. yyyy-mm-dd)
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (e.g. application/vnd.vtex.availability.v1+json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rangeStart" $rangeStart "scalar") (serialize-qp "rangeEnd" $rangeEnd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/logistics-capacity/resources/carrier@($capacityType)@($shippingPolicyId)/time-frames" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get capacity reservation usage by window
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames/{windowDay}F{windowStartTime}T{windowEndTime}
export def "logistics-capacity-resources-carrier-capacity-type-shipping-policy-id-time-frames get-by-capacityType-shippingPolicyId-windowDay-windowStartTime-windowEndTime" [
  capacityType: string
  shippingPolicyId: string
  windowDay: string
  windowStartTime: string
  windowEndTime: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (e.g. application/vnd.vtex.availability.v1+json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics-capacity/resources/carrier@($capacityType)@($shippingPolicyId)/time-frames/($windowDay)F($windowStartTime)T($windowEndTime)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/adddayofweekblocked
# operationId: AddBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-adddayofweekblocked AddBlockedDeliveryWindows" [
  carrierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/carriers/($carrierId)/adddayofweekblocked")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Retrieve blocked delivery windows
#
# GET /api/logistics/pvt/configuration/carriers/{carrierId}/getdayofweekblocked
# operationId: RetrieveBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-getdayofweekblocked RetrieveBlockedDeliveryWindows" [
  carrierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/carriers/($carrierId)/getdayofweekblocked")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/removedayofweekblocked
# operationId: RemoveBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-removedayofweekblocked RemoveBlockedDeliveryWindows" [
  carrierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/carriers/($carrierId)/removedayofweekblocked")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List all  docks
#
# GET /api/logistics/pvt/configuration/docks
# operationId: AllDocks
export def "logistics-pvt-configuration-docks AllDocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/docks")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/update dock
#
# POST /api/logistics/pvt/configuration/docks
# operationId: Create/UpdateDock
export def "logistics-pvt-configuration-docks Create/UpdateDock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/docks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Delete dock
#
# DELETE /api/logistics/pvt/configuration/docks/{dockId}
# operationId: Dock
export def "logistics-pvt-configuration-docks Dock" [
  dockId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/docks/($dockId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List dock by ID
#
# GET /api/logistics/pvt/configuration/docks/{dockId}
# operationId: DockById
export def "logistics-pvt-configuration-docks DockById" [
  dockId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/docks/($dockId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/activation
# operationId: ActivateDock
export def "logistics-pvt-configuration-docks-activation ActivateDock" [
  dockId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/docks/($dockId)/activation")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/deactivation
# operationId: DeactivateDock
export def "logistics-pvt-configuration-docks-deactivation DeactivateDock" [
  dockId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/docks/($dockId)/deactivation")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/update freight values
#
# POST /api/logistics/pvt/configuration/freights/{carrierId}/values/update
# operationId: Create/UpdateFreightValues
export def "logistics-pvt-configuration-freights-values-update Create/UpdateFreightValues" [
  carrierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/freights/($carrierId)/values/update")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List freight values
#
# GET /api/logistics/pvt/configuration/freights/{carrierId}/{cep}/values
# operationId: FreightValues
export def "logistics-pvt-configuration-freights-values FreightValues" [
  carrierId: string
  cep: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/freights/($carrierId)/($cep)/values")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List paged polygons
#
# GET /api/logistics/pvt/configuration/geoshape
# operationId: PagedPolygons
export def "logistics-pvt-configuration-geoshape PagedPolygons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # e.g. {{page}}
  --perPage: string # e.g. {{perPage}}
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/configuration/geoshape" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/update polygon
#
# PUT /api/logistics/pvt/configuration/geoshape
# operationId: CreateUpdatePolygon
export def "logistics-pvt-configuration-geoshape CreateUpdatePolygon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/geoshape")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Delete polygon
#
# DELETE /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: DeletePolygon
export def "logistics-pvt-configuration-geoshape DeletePolygon" [
  polygonName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/geoshape/($polygonName)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List polygon by ID
#
# GET /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: PolygonbyId
export def "logistics-pvt-configuration-geoshape PolygonbyId" [
  polygonName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/geoshape/($polygonName)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all holidays
#
# GET /api/logistics/pvt/configuration/holidays
# operationId: AllHolidays
export def "logistics-pvt-configuration-holidays AllHolidays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/holidays")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete holiday
#
# DELETE /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Holiday
export def "logistics-pvt-configuration-holidays Holiday" [
  holidayId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/holidays/($holidayId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List holiday by ID
#
# GET /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: HolidayById
export def "logistics-pvt-configuration-holidays HolidayById" [
  holidayId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/holidays/($holidayId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/update holiday
#
# PUT /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Create/UpdateHoliday
export def "logistics-pvt-configuration-holidays Create/UpdateHoliday" [
  holidayId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/holidays/($holidayId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List all pickup points
#
# GET /api/logistics/pvt/configuration/pickuppoints
# operationId: ListAllPickupPpoints
export def "logistics-pvt-configuration-pickuppoints ListAllPickupPpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/pickuppoints")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List paged Pickup Points
#
# GET /api/logistics/pvt/configuration/pickuppoints/_search
# operationId: Getpaged
export def "logistics-pvt-configuration-pickuppoints-search Getpaged" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # e.g. {{pageNumber}}
  --pageSize: string # e.g. {{pageSize}}
  --keyword: string # e.g. 
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "keyword" $keyword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/configuration/pickuppoints/_search" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Pickup Point
#
# DELETE /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: Delete
export def "logistics-pvt-configuration-pickuppoints Delete" [
  pickupPointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/pickuppoints/($pickupPointId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Pickup Point By ID
#
# GET /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: GetById
export def "logistics-pvt-configuration-pickuppoints GetById" [
  pickupPointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/pickuppoints/($pickupPointId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/Update Pickup Point
#
# PUT /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: CreateUpdatePickupPoint
export def "logistics-pvt-configuration-pickuppoints CreateUpdatePickupPoint" [
  pickupPointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/pickuppoints/($pickupPointId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List all warehouses
#
# GET /api/logistics/pvt/configuration/warehouses
# operationId: AllWarehouses
export def "logistics-pvt-configuration-warehouses AllWarehouses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/warehouses")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/update warehouse
#
# POST /api/logistics/pvt/configuration/warehouses
# operationId: Create/UpdateWarehouse
export def "logistics-pvt-configuration-warehouses Create/UpdateWarehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/warehouses")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Remove warehouse
#
# DELETE /api/logistics/pvt/configuration/warehouses/{warehouseId}
# operationId: RemoveWarehouse
export def "logistics-pvt-configuration-warehouses RemoveWarehouse" [
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/warehouses/($warehouseId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List warehouse by ID
#
# GET /api/logistics/pvt/configuration/warehouses/{warehouseId}
# operationId: WarehouseById
export def "logistics-pvt-configuration-warehouses WarehouseById" [
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/warehouses/($warehouseId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/activation
# operationId: ActivateWarehouse
export def "logistics-pvt-configuration-warehouses-activation ActivateWarehouse" [
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/warehouses/($warehouseId)/activation")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/deactivation
# operationId: DeactivateWarehouse
export def "logistics-pvt-configuration-warehouses-deactivation DeactivateWarehouse" [
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/configuration/warehouses/($warehouseId)/deactivation")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List inventory with dispatched reservations
#
# GET /api/logistics/pvt/inventory/items/{itemId}/warehouses/{warehouseId}/dispatched
# operationId: Getinventorywithdispatchedreservations
export def "logistics-pvt-inventory-items-warehouses-dispatched Getinventorywithdispatchedreservations" [
  itemId: string
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dispatchedReservationsQuantity: int, isUnlimitedQuantity: bool, quantity: int, skuId: string, totalReservedQuantity: int, warehouseId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($itemId)/warehouses/($warehouseId)/dispatched")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List inventory per dock
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}
# operationId: Inventoryperdock
export def "logistics-pvt-inventory-items-docks Inventoryperdock" [
  skuId: string
  dockId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/docks/($dockId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List inventory per dock and warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}/warehouses/{warehouseId}
# operationId: Inventoryperdockandwarehouse
export def "logistics-pvt-inventory-items-docks-warehouses Inventoryperdockandwarehouse" [
  skuId: string
  dockId: string
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/docks/($dockId)/warehouses/($warehouseId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List inventory per warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}
# operationId: Inventoryperwarehouse
export def "logistics-pvt-inventory-items-warehouses Inventoryperwarehouse" [
  skuId: string
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/warehouses/($warehouseId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List supply lots
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots
# operationId: GetSupplyLots
export def "logistics-pvt-inventory-items-warehouses-supply-lots GetSupplyLots" [
  skuId: string
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Type of the content being sent. (e.g. application/json; charset=utf-8)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/warehouses/($warehouseId)/supplyLots")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save supply lot
#
# PUT /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}
# operationId: SaveSupplyLot
export def "logistics-pvt-inventory-items-warehouses-supply-lots SaveSupplyLot" [
  skuId: string
  warehouseId: string
  supplyLotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/warehouses/($warehouseId)/supplyLots/($supplyLotId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Transfer supply lot
#
# POST /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}/transfer
# operationId: TransferSupplyLot
export def "logistics-pvt-inventory-items-warehouses-supply-lots-transfer TransferSupplyLot" [
  skuId: string
  warehouseId: string
  supplyLotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/items/($skuId)/warehouses/($warehouseId)/supplyLots/($supplyLotId)/transfer")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create reservation
#
# POST /api/logistics/pvt/inventory/reservations
# operationId: CreateReservation
export def "logistics-pvt-inventory-reservations CreateReservation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --Content-Type: string # Type of the content being sent.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/inventory/reservations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List reservation by ID
#
# GET /api/logistics/pvt/inventory/reservations/{reservationId}
# operationId: ReservationById
export def "logistics-pvt-inventory-reservations ReservationById" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/reservations/($reservationId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acknowledgment reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/acknowledge
# operationId: AcknowledgmentReservation
export def "logistics-pvt-inventory-reservations-acknowledge AcknowledgmentReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/reservations/($reservationId)/acknowledge")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/cancel
# operationId: CancelReservation
export def "logistics-pvt-inventory-reservations-cancel CancelReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/reservations/($reservationId)/cancel")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/confirm
# operationId: ConfirmReservation
export def "logistics-pvt-inventory-reservations-confirm ConfirmReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/reservations/($reservationId)/confirm")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List reservation by warehouse and SKU
#
# GET /api/logistics/pvt/inventory/reservations/{warehouseId}/{skuId}
# operationId: ReservationbyWarehouseandSku
export def "logistics-pvt-inventory-reservations ReservationbyWarehouseandSku" [
  warehouseId: string
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/reservations/($warehouseId)/($skuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List inventory by SKU
#
# GET /api/logistics/pvt/inventory/skus/{skuId}
# operationId: InventoryBySku
export def "logistics-pvt-inventory-skus InventoryBySku" [
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/skus/($skuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update inventory by SKU and warehouse
#
# PUT /api/logistics/pvt/inventory/skus/{skuId}/warehouses/{warehouseId}
# operationId: UpdateInventoryBySkuandWarehouse
export def "logistics-pvt-inventory-skus-warehouses UpdateInventoryBySkuandWarehouse" [
  skuId: string
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --Content-Type: string # Type of the content being sent.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/inventory/skus/($skuId)/warehouses/($warehouseId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List shipping policies
#
# GET /api/logistics/pvt/shipping-policies
export def "logistics-pvt-shipping-policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Desired number of pages to retrieve information from your Shipping Policies. (e.g. page)
  --perPage: string # Desired number of items per page, to retrieve information from your Shipping Policies. (e.g. perPage)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/shipping-policies" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shipping policy
#
# POST /api/logistics/pvt/shipping-policies
# --businessHourSettings shape: {carrierBusinessHours: list, isOpenOutsideBusinessHours: bool}
# --carrierSchedule item shape: {dayOfWeek?: int, timeLimit?: string}
# --cubicWeightSettings shape: {minimunAcceptableVolumetricWeight: float, volumetricFactor: float}
# --deliveryScheduleSettings shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
# --maxDimension shape: {largestMeasure: float, maxMeasureSum: float}
# --modalSettings shape: {modals: list, useOnlyItemsWithDefinedModal: bool}
# --pickupPointsSettings shape: {pickupPointIds: list, pickupPointTags: list, sellers: list}
# --weekendAndHolidays shape: {holiday: bool, saturday: bool, sunday: bool}
export def "logistics-pvt-shipping-policies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
  businessHourSettings: record # Business hour configuration. (e.g. {carrierBusinessHours: [{closingTime: 18:59:59, dayOfWeek: 0, openingTime: 09:00:00}], isOpenOutsideBusinessHours: true}) — shape: {carrierBusinessHours: list, isOpenOutsideBusinessHours: bool}
  --carrierSchedule: list # Schedule sent by the carrier, to configure Shipping policy — item shape: {dayOfWeek?: int, timeLimit?: string}
  cubicWeightSettings: record # Measure that accounts package's volume, and not only weight. (e.g. {minimunAcceptableVolumetricWeight: 5, volumetricFactor: 3}) — shape: {minimunAcceptableVolumetricWeight: float, volumetricFactor: float}
  deliveryScheduleSettings: record # Settings for the Scheduled Delivery feature. (e.g. {dayOfWeekForDelivery: [{dayOfWeek: 2, deliveryRanges: [{endTime: 12:00:00, listPrice: 5, startTime: 08:00:00}, {endTime: 18:00:00, listPrice: 10, startTime: 12:01:00}]}], maxRangeDelivery: 5, useDeliverySchedule: true}) — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  id: string # ID of the shipping policy. (e.g. 123)
  --isActive: oneof<nothing, bool> # Indicates whether shipping policy is active or not. (e.g. false)
  maxDimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 15, maxMeasureSum: 25}) — shape: {largestMeasure: float, maxMeasureSum: float}
  maximumValueAceptable: float # Maximum value accepted by the carrier, to realize the shipping. (e.g. 0)
  minimumValueAceptable: float # Minimum value accepted by the carrier, to realize the shipping. (e.g. 0)
  modalSettings: record # Configurations for the [modal](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125), which is the attachement of a specific product to a carrier specialized in delivering that type of product. (e.g. {modals: [Modal1], useOnlyItemsWithDefinedModal: false}) — shape: {modals: list, useOnlyItemsWithDefinedModal: bool}
  name: string # Name of the shipping policy. (e.g. Normal)
  numberOfItemsPerShipment: int # Capacity of your store's logistics of shipment, determines number of items permitted per shipment. (e.g. 5)
  pickupPointsSettings: record # Configuration for Pickup Points. (e.g. {pickupPointIds: [null], pickupPointTags: [null], sellers: [cosmetics2]}) — shape: {pickupPointIds: list, pickupPointTags: list, sellers: list}
  shippingMethod: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation (e.g. Normal)
  weekendAndHolidays: record # If the shipping policy includes deliveries on weekends and holidays. (e.g. {holiday: false, saturday: false, sunday: false}) — shape: {holiday: bool, saturday: bool, sunday: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/shipping-policies")
  let body = {businessHourSettings: $businessHourSettings, carrierSchedule: $carrierSchedule, cubicWeightSettings: $cubicWeightSettings, deliveryScheduleSettings: $deliveryScheduleSettings, id: $id, isActive: $isActive, maxDimension: $maxDimension, maximumValueAceptable: $maximumValueAceptable, minimumValueAceptable: $minimumValueAceptable, modalSettings: $modalSettings, name: $name, numberOfItemsPerShipment: $numberOfItemsPerShipment, pickupPointsSettings: $pickupPointsSettings, shippingMethod: $shippingMethod, weekendAndHolidays: $weekendAndHolidays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete shipping policies by ID
#
# DELETE /api/logistics/pvt/shipping-policies/{id}
export def "logistics-pvt-shipping-policies delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/shipping-policies/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve shipping policy by ID
#
# GET /api/logistics/pvt/shipping-policies/{id}
export def "logistics-pvt-shipping-policies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/shipping-policies/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shipping policy
#
# PUT /api/logistics/pvt/shipping-policies/{id}
# --deliveryScheduleSettings shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
# --maxDimension shape: {largestMeasure: float, maxMeasureSum: float}
export def "logistics-pvt-shipping-policies put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --Content-Type: string # Type of the content being sent
  --deliveryOnWeekends: oneof<nothing, bool> # If the shipping policy (carrier) delivers on weekends (e.g. false)
  --deliveryScheduleSettings: record # Settings for the Scheduled Delivery feature. — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  --isActive: oneof<nothing, bool> # If the shipping policy is active or not. (e.g. true)
  maxDimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 10, maxMeasureSum: 30}) — shape: {largestMeasure: float, maxMeasureSum: float}
  name: string # Name of the shipping policy (e.g. Correios PAC)
  shippingMethod: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation. (e.g. Normal)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/logistics/pvt/shipping-policies/($id)")
  let body = {deliveryOnWeekends: $deliveryOnWeekends, deliveryScheduleSettings: $deliveryScheduleSettings, isActive: $isActive, maxDimension: $maxDimension, name: $name, shippingMethod: $shippingMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate SLA
#
# POST /api/logistics/pvt/shipping/calculate
# operationId: CalculateSLA
export def "logistics-pvt-shipping-calculate CalculateSLA" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/shipping/calculate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}
