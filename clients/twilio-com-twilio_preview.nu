# Auto-generated client for Twilio - Preview v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_preview/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_PREVIEW_TOKEN

const BASE_URL = "https://preview.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_PREVIEW_TOKEN | default "" }
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

def base-url-completer [] { ["https://preview.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Status-completer [] { ["canceled" "failed" "opened" "signed" "signing"] }
def Status-completer-1 [] { ["action-required" "carrier-processing" "completed" "failed" "pending-loa" "pending-verification" "received" "testing" "verified"] }
def SmsFallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def SmsMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def StatusCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def VerificationType-completer [] { ["phone-bill" "phone-call"] }
def Order-completer [] { ["asc" "desc"] }
def Bounds-completer [] { ["exclusive" "inclusive"] }
def CommandsCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def VoiceFallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def VoiceMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deployed-devices-fleets ListDeployedDevicesFleet" } } | get name | first)
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

# Retrieve a list of all Fleets belonging to your account.
#
# GET /DeployedDevices/Fleets
# operationId: ListDeployedDevicesFleet
export def "deployed-devices-fleets ListDeployedDevicesFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<fleets: table<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DeployedDevices/Fleets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Fleet for scoping of deployed devices within your account.
#
# POST /DeployedDevices/Fleets
# operationId: CreateDeployedDevicesFleet
export def "deployed-devices-fleets CreateDeployedDevicesFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/DeployedDevices/Fleets")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Certificate credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates
# operationId: ListDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates ListDeployedDevicesCertificate" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceSid: string # Filters the resulting list of Certificates by a unique string identifier of an authenticated Device.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<certificates: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "DeviceSid" $DeviceSid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enroll a new Certificate credential to the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates
# operationId: CreateDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates CreateDeployedDevicesCertificate" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  CertificateData: string # Provides a URL encoded representation of the public certificate in PEM format.
  --DeviceSid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --FriendlyName: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Certificates")
  let body = {CertificateData: $CertificateData, DeviceSid: $DeviceSid, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unregister a specific Certificate credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: DeleteDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates DeleteDeployedDevicesCertificate" [
  FleetSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Certificates/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch information about a specific Certificate credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: FetchDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates FetchDeployedDevicesCertificate" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Certificates/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the given properties of a specific Certificate credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: UpdateDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates UpdateDeployedDevicesCertificate" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceSid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --FriendlyName: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Certificates/($Sid)")
  let body = {DeviceSid: $DeviceSid, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Deployments belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments
# operationId: ListDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments ListDeployedDevicesDeployment" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<deployments: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Deployment in the Fleet, optionally giving it a friendly name and linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments
# operationId: CreateDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments CreateDeployedDevicesDeployment" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # Provides a human readable descriptive text for this Deployment, up to 256 characters long.
  --SyncServiceSid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Deployments")
  let body = {FriendlyName: $FriendlyName, SyncServiceSid: $SyncServiceSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Deployment from the Fleet, leaving associated devices effectively undeployed.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: DeleteDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments DeleteDeployedDevicesDeployment" [
  FleetSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Deployments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch information about a specific Deployment in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: FetchDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments FetchDeployedDevicesDeployment" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Deployments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the given properties of a specific Deployment credential in the Fleet, giving it a friendly name or linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: UpdateDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments UpdateDeployedDevicesDeployment" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # Provides a human readable descriptive text for this Deployment, up to 64 characters long
  --SyncServiceSid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Deployments/($Sid)")
  let body = {FriendlyName: $FriendlyName, SyncServiceSid: $SyncServiceSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Devices belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices
# operationId: ListDeployedDevicesDevice
export def "deployed-devices-fleets-devices ListDeployedDevicesDevice" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeploymentSid: string # Filters the resulting list of Devices by a unique string identifier of the Deployment they are associated with.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<devices: table<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "DeploymentSid" $DeploymentSid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Device in the Fleet, optionally giving it a unique name, friendly name, and assigning to a Deployment and/or human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices
# operationId: CreateDeployedDevicesDevice
export def "deployed-devices-fleets-devices CreateDeployedDevicesDevice" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeploymentSid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --Enabled: oneof<nothing, bool>
  --FriendlyName: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --Identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
  --UniqueName: string # Provides a unique and addressable name to be assigned to this Device, to be used in addition to SID, up to 128 characters long.
]: any -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Devices")
  let body = {DeploymentSid: $DeploymentSid, Enabled: $Enabled, FriendlyName: $FriendlyName, Identity: $Identity, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Device from the Fleet, also removing it from associated Deployments.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: DeleteDeployedDevicesDevice
export def "deployed-devices-fleets-devices DeleteDeployedDevicesDevice" [
  FleetSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Devices/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch information about a specific Device in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: FetchDeployedDevicesDevice
export def "deployed-devices-fleets-devices FetchDeployedDevicesDevice" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Devices/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the given properties of a specific Device in the Fleet, giving it a friendly name, assigning to a Deployment, or a human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: UpdateDeployedDevicesDevice
export def "deployed-devices-fleets-devices UpdateDeployedDevicesDevice" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeploymentSid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --Enabled: oneof<nothing, bool>
  --FriendlyName: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --Identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
]: any -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Devices/($Sid)")
  let body = {DeploymentSid: $DeploymentSid, Enabled: $Enabled, FriendlyName: $FriendlyName, Identity: $Identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Keys credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys
# operationId: ListDeployedDevicesKey
export def "deployed-devices-fleets-keys ListDeployedDevicesKey" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceSid: string # Filters the resulting list of Keys by a unique string identifier of an authenticated Device.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<keys: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "DeviceSid" $DeviceSid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Key credential in the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys
# operationId: CreateDeployedDevicesKey
export def "deployed-devices-fleets-keys CreateDeployedDevicesKey" [
  FleetSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceSid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --FriendlyName: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Keys")
  let body = {DeviceSid: $DeviceSid, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Key credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: DeleteDeployedDevicesKey
export def "deployed-devices-fleets-keys DeleteDeployedDevicesKey" [
  FleetSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Keys/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch information about a specific Key credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: FetchDeployedDevicesKey
export def "deployed-devices-fleets-keys FetchDeployedDevicesKey" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Keys/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the given properties of a specific Key credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: UpdateDeployedDevicesKey
export def "deployed-devices-fleets-keys UpdateDeployedDevicesKey" [
  FleetSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceSid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --FriendlyName: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($FleetSid)/Keys/($Sid)")
  let body = {DeviceSid: $DeviceSid, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Fleet from your account, also destroys all nested resources: Devices, Deployments, Certificates, Keys.
#
# DELETE /DeployedDevices/Fleets/{Sid}
# operationId: DeleteDeployedDevicesFleet
export def "deployed-devices-fleets DeleteDeployedDevicesFleet" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch information about a specific Fleet in your account.
#
# GET /DeployedDevices/Fleets/{Sid}
# operationId: FetchDeployedDevicesFleet
export def "deployed-devices-fleets FetchDeployedDevicesFleet" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the friendly name property of a specific Fleet in your account.
#
# POST /DeployedDevices/Fleets/{Sid}
# operationId: UpdateDeployedDevicesFleet
export def "deployed-devices-fleets UpdateDeployedDevicesFleet" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DefaultDeploymentSid: string # Provides a string identifier of a Deployment that is going to be used as a default one for this Fleet.
  --FriendlyName: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/DeployedDevices/Fleets/($Sid)")
  let body = {DefaultDeploymentSid: $DefaultDeploymentSid, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of AuthorizationDocuments belonging to the account initiating the request.
#
# GET /HostedNumbers/AuthorizationDocuments
# operationId: ListHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents ListHostedNumbersAuthorizationDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Email: string # Email that this AuthorizationDocument will be sent to for signing.
  --Status: string@Status-completer # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<items: table<address_sid: string, cc_emails: list, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Email" $Email "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/HostedNumbers/AuthorizationDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an AuthorizationDocument for authorizing the hosting of phone number capabilities on Twilio's platform.
#
# POST /HostedNumbers/AuthorizationDocuments
# operationId: CreateHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents CreateHostedNumbersAuthorizationDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  AddressSid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --CcEmails: list # Email recipients who will be informed when an Authorization Document has been sent and signed.
  ContactPhoneNumber: string # The contact phone number of the person authorized to sign the Authorization Document.
  ContactTitle: string # The title of the person authorized to sign the Authorization Document for this phone number.
  Email: string # Email that this AuthorizationDocument will be sent to for signing.
  HostedNumberOrderSids: list # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
]: any -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/HostedNumbers/AuthorizationDocuments")
  let body = {AddressSid: $AddressSid, CcEmails: $CcEmails, ContactPhoneNumber: $ContactPhoneNumber, ContactTitle: $ContactTitle, Email: $Email, HostedNumberOrderSids: $HostedNumberOrderSids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch a specific AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{Sid}
# operationId: FetchHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents FetchHostedNumbersAuthorizationDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/HostedNumbers/AuthorizationDocuments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific AuthorizationDocument.
#
# POST /HostedNumbers/AuthorizationDocuments/{Sid}
# operationId: UpdateHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents UpdateHostedNumbersAuthorizationDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AddressSid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --CcEmails: list # Email recipients who will be informed when an Authorization Document has been sent and signed
  --ContactPhoneNumber: string # The contact phone number of the person authorized to sign the Authorization Document.
  --ContactTitle: string # The title of the person authorized to sign the Authorization Document for this phone number.
  --Email: string # Email that this AuthorizationDocument will be sent to for signing.
  --HostedNumberOrderSids: list # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
  --Status: string@Status-completer
]: any -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/HostedNumbers/AuthorizationDocuments/($Sid)")
  let body = {AddressSid: $AddressSid, CcEmails: $CcEmails, ContactPhoneNumber: $ContactPhoneNumber, ContactTitle: $ContactTitle, Email: $Email, HostedNumberOrderSids: $HostedNumberOrderSids, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of dependent HostedNumberOrders belonging to the AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{SigningDocumentSid}/DependentHostedNumberOrders
# operationId: ListHostedNumbersDependentHostedNumberOrder
export def "hosted-numbers-authorization-documents-dependent-hosted-number-orders ListHostedNumbersDependentHostedNumberOrder" [
  SigningDocumentSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer-1 # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --PhoneNumber: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --IncomingPhoneNumberSid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --FriendlyName: string # A human readable description of this resource, up to 64 characters.
  --UniqueName: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "IncomingPhoneNumberSid" $IncomingPhoneNumberSid "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "UniqueName" $UniqueName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/HostedNumbers/AuthorizationDocuments/($SigningDocumentSid)/DependentHostedNumberOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of HostedNumberOrders belonging to the account initiating the request.
#
# GET /HostedNumbers/HostedNumberOrders
# operationId: ListHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders ListHostedNumbersHostedNumberOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer-1 # The Status of this HostedNumberOrder. One of `received`, `pending-verification`, `verified`, `pending-loa`, `carrier-processing`, `testing`, `completed`, `failed`, or `action-required`.
  --PhoneNumber: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --IncomingPhoneNumberSid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --FriendlyName: string # A human readable description of this resource, up to 64 characters.
  --UniqueName: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "IncomingPhoneNumberSid" $IncomingPhoneNumberSid "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "UniqueName" $UniqueName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/HostedNumbers/HostedNumberOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Host a phone number's capability on Twilio's platform.
#
# POST /HostedNumbers/HostedNumberOrders
# operationId: CreateHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders CreateHostedNumbersHostedNumberOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AccountSid: string # This defaults to the AccountSid of the authorization the user is using. This can be provided to specify a subaccount to add the HostedNumberOrder to.
  --AddressSid: string # Optional. A 34 character string that uniquely identifies the Address resource that represents the address of the owner of this phone number.
  --CcEmails: list # Optional. A list of emails that the LOA document for this HostedNumberOrder will be carbon copied to.
  --Email: string # Optional. Email of the owner of this phone number that is being hosted.
  --FriendlyName: string # A 64 character string that is a human readable text that describes this resource.
  PhoneNumber: string # The number to host in [+E.164](https://en.wikipedia.org/wiki/E.164) format (format: phone-number)
  --SmsApplicationSid: string # Optional. The 34 character sid of the application Twilio should use to handle SMS messages sent to this number. If a `SmsApplicationSid` is present, Twilio will ignore all of the SMS urls above and use those set on the application.
  --SmsCapability: oneof<nothing, bool> # Used to specify that the SMS capability will be hosted on Twilio's platform.
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method that should be used to request the SmsFallbackUrl. Must be either `GET` or `POST`. This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --SmsFallbackUrl: string # A URL that Twilio will request if an error occurs requesting or executing the TwiML defined by SmsUrl. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method that should be used to request the SmsUrl. Must be either `GET` or `POST`.  This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --SmsUrl: string # The URL that Twilio should request when somebody sends an SMS to the phone number. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # Optional. The Status Callback Method attached to the IncomingPhoneNumber resource. (format: http-method)
  --StatusCallbackUrl: string # Optional. The Status Callback URL attached to the IncomingPhoneNumber resource. (format: uri)
  --UniqueName: string # Optional. Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --VerificationDocumentSid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --VerificationType: string@VerificationType-completer
]: any -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/HostedNumbers/HostedNumberOrders")
  let body = {AccountSid: $AccountSid, AddressSid: $AddressSid, CcEmails: $CcEmails, Email: $Email, FriendlyName: $FriendlyName, PhoneNumber: $PhoneNumber, SmsApplicationSid: $SmsApplicationSid, SmsCapability: $SmsCapability, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, StatusCallbackMethod: $StatusCallbackMethod, StatusCallbackUrl: $StatusCallbackUrl, UniqueName: $UniqueName, VerificationDocumentSid: $VerificationDocumentSid, VerificationType: $VerificationType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Cancel the HostedNumberOrder (only available when the status is in `received`).
#
# DELETE /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: DeleteHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders DeleteHostedNumbersHostedNumberOrder" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/HostedNumbers/HostedNumberOrders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific HostedNumberOrder.
#
# GET /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: FetchHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders FetchHostedNumbersHostedNumberOrder" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/HostedNumbers/HostedNumberOrders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific HostedNumberOrder.
#
# POST /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: UpdateHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders UpdateHostedNumbersHostedNumberOrder" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallDelay: int # The number of seconds, between 0 and 60, to delay before initiating the verification call. Defaults to 0.
  --CcEmails: list # Optional. A list of emails that LOA document for this HostedNumberOrder will be carbon copied to.
  --Email: string # Email of the owner of this phone number that is being hosted.
  --Extension: string # Digits to dial after connecting the verification call.
  --FriendlyName: string # A 64 character string that is a human readable text that describes this resource.
  --Status: string@Status-completer-1
  --UniqueName: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --VerificationCode: string # A verification code that is given to the user via a phone call to the phone number that is being hosted.
  --VerificationDocumentSid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --VerificationType: string@VerificationType-completer
]: any -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/HostedNumbers/HostedNumberOrders/($Sid)")
  let body = {CallDelay: $CallDelay, CcEmails: $CcEmails, Email: $Email, Extension: $Extension, FriendlyName: $FriendlyName, Status: $Status, UniqueName: $UniqueName, VerificationCode: $VerificationCode, VerificationDocumentSid: $VerificationDocumentSid, VerificationType: $VerificationType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /Sync/Services
#
# operationId: ListSyncService
export def "sync-services ListSyncService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Sync/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services
#
# operationId: CreateSyncService
export def "sync-services CreateSyncService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AclEnabled: oneof<nothing, bool>
  --FriendlyName: string
  --ReachabilityWebhooksEnabled: oneof<nothing, bool>
  --WebhookUrl: string # format: uri
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/Sync/Services")
  let body = {AclEnabled: $AclEnabled, FriendlyName: $FriendlyName, ReachabilityWebhooksEnabled: $ReachabilityWebhooksEnabled, WebhookUrl: $WebhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /Sync/Services/{ServiceSid}/Documents
#
# operationId: ListSyncDocument
export def "sync-services-documents ListSyncDocument" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Documents
#
# operationId: CreateSyncDocument
export def "sync-services-documents CreateSyncDocument" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Data: any
  --UniqueName: string
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents")
  let body = {Data: $Data, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Permissions applying to a Sync Document.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions
# operationId: ListSyncDocumentPermission
export def "sync-services-documents-permissions ListSyncDocumentPermission" [
  ServiceSid: string
  DocumentSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($DocumentSid)/Permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Sync Document Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: DeleteSyncDocumentPermission
export def "sync-services-documents-permissions DeleteSyncDocumentPermission" [
  ServiceSid: string
  DocumentSid: string
  Identity: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($DocumentSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Sync Document Permission.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: FetchSyncDocumentPermission
export def "sync-services-documents-permissions FetchSyncDocumentPermission" [
  ServiceSid: string
  DocumentSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($DocumentSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an identity's access to a specific Sync Document.
#
# POST /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: UpdateSyncDocumentPermission
export def "sync-services-documents-permissions UpdateSyncDocumentPermission" [
  ServiceSid: string
  DocumentSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Document.
  --Read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Document.
  --Write: oneof<nothing, bool> # Boolean flag specifying whether the identity can update the Sync Document.
]: any -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($DocumentSid)/Permissions/($Identity)")
  let body = {Manage: $Manage, Read: $Read, Write: $Write} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: DeleteSyncDocument
export def "sync-services-documents DeleteSyncDocument" [
  ServiceSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: FetchSyncDocument
export def "sync-services-documents FetchSyncDocument" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: UpdateSyncDocument
export def "sync-services-documents UpdateSyncDocument" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  Data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Documents/($Sid)")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /Sync/Services/{ServiceSid}/Lists
#
# operationId: ListSyncSyncList
export def "sync-services-lists ListSyncSyncList" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<lists: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Lists
#
# operationId: CreateSyncSyncList
export def "sync-services-lists CreateSyncSyncList" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UniqueName: string
]: any -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists")
  let body = {UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: ListSyncSyncListItem
export def "sync-services-lists-items ListSyncSyncListItem" [
  ServiceSid: string
  ListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Order: string@Order-completer
  --From: string
  --Bounds: string@Bounds-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "From" $From "scalar") (serialize-qp "Bounds" $Bounds "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: CreateSyncSyncListItem
export def "sync-services-lists-items CreateSyncSyncListItem" [
  ServiceSid: string
  ListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Items")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: DeleteSyncSyncListItem
export def "sync-services-lists-items DeleteSyncSyncListItem" [
  ServiceSid: string
  ListSid: string
  Index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Items/($Index)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: FetchSyncSyncListItem
export def "sync-services-lists-items FetchSyncSyncListItem" [
  ServiceSid: string
  ListSid: string
  Index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Items/($Index)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: UpdateSyncSyncListItem
export def "sync-services-lists-items UpdateSyncSyncListItem" [
  ServiceSid: string
  ListSid: string
  Index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  Data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Items/($Index)")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Permissions applying to a Sync List.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions
# operationId: ListSyncSyncListPermission
export def "sync-services-lists-permissions ListSyncSyncListPermission" [
  ServiceSid: string
  ListSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Sync List Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncListPermission
export def "sync-services-lists-permissions DeleteSyncSyncListPermission" [
  ServiceSid: string
  ListSid: string
  Identity: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Sync List Permission.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: FetchSyncSyncListPermission
export def "sync-services-lists-permissions FetchSyncSyncListPermission" [
  ServiceSid: string
  ListSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an identity's access to a specific Sync List.
#
# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: UpdateSyncSyncListPermission
export def "sync-services-lists-permissions UpdateSyncSyncListPermission" [
  ServiceSid: string
  ListSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync List.
  --Read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync List.
  --Write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync List.
]: any -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($ListSid)/Permissions/($Identity)")
  let body = {Manage: $Manage, Read: $Read, Write: $Write} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: DeleteSyncSyncList
export def "sync-services-lists DeleteSyncSyncList" [
  ServiceSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: FetchSyncSyncList
export def "sync-services-lists FetchSyncSyncList" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Lists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Maps
#
# operationId: ListSyncSyncMap
export def "sync-services-maps ListSyncSyncMap" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<maps: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Maps
#
# operationId: CreateSyncSyncMap
export def "sync-services-maps CreateSyncSyncMap" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UniqueName: string
]: any -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps")
  let body = {UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: ListSyncSyncMapItem
export def "sync-services-maps-items ListSyncSyncMapItem" [
  ServiceSid: string
  MapSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Order: string@Order-completer
  --From: string
  --Bounds: string@Bounds-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "From" $From "scalar") (serialize-qp "Bounds" $Bounds "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: CreateSyncSyncMapItem
export def "sync-services-maps-items CreateSyncSyncMapItem" [
  ServiceSid: string
  MapSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Data: any
  Key: string
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Items")
  let body = {Data: $Data, Key: $Key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: DeleteSyncSyncMapItem
export def "sync-services-maps-items DeleteSyncSyncMapItem" [
  ServiceSid: string
  MapSid: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Items/($Key)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: FetchSyncSyncMapItem
export def "sync-services-maps-items FetchSyncSyncMapItem" [
  ServiceSid: string
  MapSid: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Items/($Key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: UpdateSyncSyncMapItem
export def "sync-services-maps-items UpdateSyncSyncMapItem" [
  ServiceSid: string
  MapSid: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  Data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Items/($Key)")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Permissions applying to a Sync Map.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions
# operationId: ListSyncSyncMapPermission
export def "sync-services-maps-permissions ListSyncSyncMapPermission" [
  ServiceSid: string
  MapSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Sync Map Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncMapPermission
export def "sync-services-maps-permissions DeleteSyncSyncMapPermission" [
  ServiceSid: string
  MapSid: string
  Identity: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Sync Map Permission.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: FetchSyncSyncMapPermission
export def "sync-services-maps-permissions FetchSyncSyncMapPermission" [
  ServiceSid: string
  MapSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Permissions/($Identity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an identity's access to a specific Sync Map.
#
# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: UpdateSyncSyncMapPermission
export def "sync-services-maps-permissions UpdateSyncSyncMapPermission" [
  ServiceSid: string
  MapSid: string
  Identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Map.
  --Read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Map.
  --Write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync Map.
]: any -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($MapSid)/Permissions/($Identity)")
  let body = {Manage: $Manage, Read: $Read, Write: $Write} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: DeleteSyncSyncMap
export def "sync-services-maps DeleteSyncSyncMap" [
  ServiceSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: FetchSyncSyncMap
export def "sync-services-maps FetchSyncSyncMap" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($ServiceSid)/Maps/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /Sync/Services/{Sid}
#
# operationId: DeleteSyncService
export def "sync-services DeleteSyncService" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /Sync/Services/{Sid}
#
# operationId: FetchSyncService
export def "sync-services FetchSyncService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Sync/Services/{Sid}
#
# operationId: UpdateSyncService
export def "sync-services UpdateSyncService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AclEnabled: oneof<nothing, bool>
  --FriendlyName: string
  --ReachabilityWebhooksEnabled: oneof<nothing, bool>
  --WebhookUrl: string # format: uri
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/Sync/Services/($Sid)")
  let body = {AclEnabled: $AclEnabled, FriendlyName: $FriendlyName, ReachabilityWebhooksEnabled: $ReachabilityWebhooksEnabled, WebhookUrl: $WebhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Add-ons currently available to be installed.
#
# GET /marketplace/AvailableAddOns
# operationId: ListMarketplaceAvailableAddOn
export def "marketplace-available-add-ons ListMarketplaceAvailableAddOn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<available_add_ons: table<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketplace/AvailableAddOns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of Extensions for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions
# operationId: ListMarketplaceAvailableAddOnExtension
export def "marketplace-available-add-ons-extensions ListMarketplaceAvailableAddOnExtension" [
  AvailableAddOnSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<extensions: table<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketplace/AvailableAddOns/($AvailableAddOnSid)/Extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Extension for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions/{Sid}
# operationId: FetchMarketplaceAvailableAddOnExtension
export def "marketplace-available-add-ons-extensions FetchMarketplaceAvailableAddOnExtension" [
  AvailableAddOnSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/AvailableAddOns/($AvailableAddOnSid)/Extensions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Add-on currently available to be installed.
#
# GET /marketplace/AvailableAddOns/{Sid}
# operationId: FetchMarketplaceAvailableAddOn
export def "marketplace-available-add-ons FetchMarketplaceAvailableAddOn" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/AvailableAddOns/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of Add-ons currently installed on this Account.
#
# GET /marketplace/InstalledAddOns
# operationId: ListMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons ListMarketplaceInstalledAddOn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<installed_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketplace/InstalledAddOns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install an Add-on for the Account specified.
#
# POST /marketplace/InstalledAddOns
# operationId: CreateMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons CreateMarketplaceInstalledAddOn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AcceptTermsOfService: oneof<nothing, bool> # Whether the Terms of Service were accepted.
  AvailableAddOnSid: string # The SID of the AvaliableAddOn to install.
  --Configuration: any # The JSON object that represents the configuration of the new Add-on being installed.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/marketplace/InstalledAddOns")
  let body = {AcceptTermsOfService: $AcceptTermsOfService, AvailableAddOnSid: $AvailableAddOnSid, Configuration: $Configuration, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Extensions for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions
# operationId: ListMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions ListMarketplaceInstalledAddOnExtension" [
  InstalledAddOnSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<extensions: table<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($InstalledAddOnSid)/Extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Extension for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# operationId: FetchMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions FetchMarketplaceInstalledAddOnExtension" [
  InstalledAddOnSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($InstalledAddOnSid)/Extensions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Extension for an Add-on installation.
#
# POST /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# operationId: UpdateMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions UpdateMarketplaceInstalledAddOnExtension" [
  InstalledAddOnSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Enabled: oneof<nothing, bool> # Whether the Extension should be invoked.
]: any -> record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($InstalledAddOnSid)/Extensions/($Sid)")
  let body = {Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Add-on installation from your account
#
# DELETE /marketplace/InstalledAddOns/{Sid}
# operationId: DeleteMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons DeleteMarketplaceInstalledAddOn" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Add-on currently installed on this Account.
#
# GET /marketplace/InstalledAddOns/{Sid}
# operationId: FetchMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons FetchMarketplaceInstalledAddOn" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Add-on installation for the Account specified.
#
# POST /marketplace/InstalledAddOns/{Sid}
# operationId: UpdateMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons UpdateMarketplaceInstalledAddOn" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Configuration: any # Valid JSON object that conform to the configuration schema exposed by the associated AvailableAddOn resource. This is only required by Add-ons that need to be configured
  --UniqueName: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/marketplace/InstalledAddOns/($Sid)")
  let body = {Configuration: $Configuration, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants
#
# operationId: ListUnderstandAssistant
export def "understand-assistants ListUnderstandAssistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/understand/Assistants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants
#
# operationId: CreateUnderstandAssistant
export def "understand-assistants CreateUnderstandAssistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackEvents: string # Space-separated list of callback events that will trigger callbacks.
  --CallbackUrl: string # A user-provided URL to send event callbacks to. (format: uri)
  --FallbackActions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --FriendlyName: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --InitiationActions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --LogQueries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --StyleSheet: any # The JSON object that holds the style sheet for the assistant
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/understand/Assistants")
  let body = {CallbackEvents: $CallbackEvents, CallbackUrl: $CallbackUrl, FallbackActions: $FallbackActions, FriendlyName: $FriendlyName, InitiationActions: $InitiationActions, LogQueries: $LogQueries, StyleSheet: $StyleSheet, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/Dialogues/{Sid}
#
# operationId: FetchUnderstandDialogue
export def "understand-assistants-dialogues FetchUnderstandDialogue" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Dialogues/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/FallbackActions
#
# operationId: FetchUnderstandAssistantFallbackActions
export def "understand-assistants-fallback-actions FetchUnderstandAssistantFallbackActions" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FallbackActions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/FallbackActions
#
# operationId: UpdateUnderstandAssistantFallbackActions
export def "understand-assistants-fallback-actions UpdateUnderstandAssistantFallbackActions" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FallbackActions: any
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FallbackActions")
  let body = {FallbackActions: $FallbackActions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes
#
# operationId: ListUnderstandFieldType
export def "understand-assistants-field-types ListUnderstandFieldType" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes
#
# operationId: CreateUnderstandFieldType
export def "understand-assistants-field-types CreateUnderstandFieldType" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: ListUnderstandFieldValue
export def "understand-assistants-field-types-field-values ListUnderstandFieldValue" [
  AssistantSid: string
  FieldTypeSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Language: string # An ISO language-country string of the value. For example: *en-US*
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Language" $Language "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($FieldTypeSid)/FieldValues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: CreateUnderstandFieldValue
export def "understand-assistants-field-types-field-values CreateUnderstandFieldValue" [
  AssistantSid: string
  FieldTypeSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Language: string # An ISO language-country string of the value.
  --SynonymOf: string # A value that indicates this field value is a synonym of. Empty if the value is not a synonym.
  Value: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($FieldTypeSid)/FieldValues")
  let body = {Language: $Language, SynonymOf: $SynonymOf, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: DeleteUnderstandFieldValue
export def "understand-assistants-field-types-field-values DeleteUnderstandFieldValue" [
  AssistantSid: string
  FieldTypeSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($FieldTypeSid)/FieldValues/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: FetchUnderstandFieldValue
export def "understand-assistants-field-types-field-values FetchUnderstandFieldValue" [
  AssistantSid: string
  FieldTypeSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($FieldTypeSid)/FieldValues/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: DeleteUnderstandFieldType
export def "understand-assistants-field-types DeleteUnderstandFieldType" [
  AssistantSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: FetchUnderstandFieldType
export def "understand-assistants-field-types FetchUnderstandFieldType" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: UpdateUnderstandFieldType
export def "understand-assistants-field-types UpdateUnderstandFieldType" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/FieldTypes/($Sid)")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/InitiationActions
#
# operationId: FetchUnderstandAssistantInitiationActions
export def "understand-assistants-initiation-actions FetchUnderstandAssistantInitiationActions" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/InitiationActions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/InitiationActions
#
# operationId: UpdateUnderstandAssistantInitiationActions
export def "understand-assistants-initiation-actions UpdateUnderstandAssistantInitiationActions" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --InitiationActions: any
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/InitiationActions")
  let body = {InitiationActions: $InitiationActions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: ListUnderstandModelBuild
export def "understand-assistants-model-builds ListUnderstandModelBuild" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/ModelBuilds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: CreateUnderstandModelBuild
export def "understand-assistants-model-builds CreateUnderstandModelBuild" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StatusCallback: string # format: uri
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/ModelBuilds")
  let body = {StatusCallback: $StatusCallback, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: DeleteUnderstandModelBuild
export def "understand-assistants-model-builds DeleteUnderstandModelBuild" [
  AssistantSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/ModelBuilds/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: FetchUnderstandModelBuild
export def "understand-assistants-model-builds FetchUnderstandModelBuild" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/ModelBuilds/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: UpdateUnderstandModelBuild
export def "understand-assistants-model-builds UpdateUnderstandModelBuild" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/ModelBuilds/($Sid)")
  let body = {UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/Queries
#
# operationId: ListUnderstandQuery
export def "understand-assistants-queries ListUnderstandQuery" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Language: string # An ISO language-country string of the sample.
  --ModelBuild: string # The Model Build Sid or unique name of the Model Build to be queried.
  --Status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Language" $Language "scalar") (serialize-qp "ModelBuild" $ModelBuild "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Queries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Queries
#
# operationId: CreateUnderstandQuery
export def "understand-assistants-queries CreateUnderstandQuery" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Field: string # Constraints the query to a given Field with an task. Useful when you know the Field you are expecting. It accepts one field in the format *task-unique-name-1*:*field-unique-name*
  Language: string # An ISO language-country string of the sample.
  --ModelBuild: string # The Model Build Sid or unique name of the Model Build to be queried.
  Query: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. It can be up to 2048 characters long.
  --Tasks: string # Constraints the query to a set of tasks. Useful when you need to constrain the paths the user can take. Tasks should be comma separated *task-unique-name-1*, *task-unique-name-2*
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Queries")
  let body = {Field: $Field, Language: $Language, ModelBuild: $ModelBuild, Query: $Query, Tasks: $Tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: DeleteUnderstandQuery
export def "understand-assistants-queries DeleteUnderstandQuery" [
  AssistantSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Queries/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: FetchUnderstandQuery
export def "understand-assistants-queries FetchUnderstandQuery" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Queries/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: UpdateUnderstandQuery
export def "understand-assistants-queries UpdateUnderstandQuery" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SampleSid: string # An optional reference to the Sample created from this query.
  --Status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Queries/($Sid)")
  let body = {SampleSid: $SampleSid, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns Style sheet JSON object for this Assistant
#
# GET /understand/Assistants/{AssistantSid}/StyleSheet
# operationId: FetchUnderstandStyleSheet
export def "understand-assistants-style-sheet FetchUnderstandStyleSheet" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/StyleSheet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the style sheet for an assistant identified by {AssistantSid} or {AssistantUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/StyleSheet
# operationId: UpdateUnderstandStyleSheet
export def "understand-assistants-style-sheet UpdateUnderstandStyleSheet" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StyleSheet: any # The JSON Style sheet string
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/StyleSheet")
  let body = {StyleSheet: $StyleSheet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/Tasks
#
# operationId: ListUnderstandTask
export def "understand-assistants-tasks ListUnderstandTask" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Tasks
#
# operationId: CreateUnderstandTask
export def "understand-assistants-tasks CreateUnderstandTask" [
  AssistantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --ActionsUrl: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --FriendlyName: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks")
  let body = {Actions: $Actions, ActionsUrl: $ActionsUrl, FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: DeleteUnderstandTask
export def "understand-assistants-tasks DeleteUnderstandTask" [
  AssistantSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: FetchUnderstandTask
export def "understand-assistants-tasks FetchUnderstandTask" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: UpdateUnderstandTask
export def "understand-assistants-tasks UpdateUnderstandTask" [
  AssistantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --ActionsUrl: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --FriendlyName: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($Sid)")
  let body = {Actions: $Actions, ActionsUrl: $ActionsUrl, FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns JSON actions for this Task.
#
# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: FetchUnderstandTaskActions
export def "understand-assistants-tasks-actions FetchUnderstandTaskActions" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the actions of an Task identified by {TaskSid} or {TaskUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: UpdateUnderstandTaskActions
export def "understand-assistants-tasks-actions UpdateUnderstandTaskActions" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Actions: any # The JSON actions that instruct the Assistant how to perform this task.
]: any -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Actions")
  let body = {Actions: $Actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: ListUnderstandField
export def "understand-assistants-tasks-fields ListUnderstandField" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: CreateUnderstandField
export def "understand-assistants-tasks-fields CreateUnderstandField" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  FieldType: string # The unique name or sid of the FieldType. It can be any [Built-in Field Type](https://www.twilio.com/docs/assistant/api/built-in-field-types) or the unique_name or the Field Type sid of a custom Field Type.
  UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Fields")
  let body = {FieldType: $FieldType, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: DeleteUnderstandField
export def "understand-assistants-tasks-fields DeleteUnderstandField" [
  AssistantSid: string
  TaskSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Fields/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: FetchUnderstandField
export def "understand-assistants-tasks-fields FetchUnderstandField" [
  AssistantSid: string
  TaskSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Fields/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: ListUnderstandSample
export def "understand-assistants-tasks-samples ListUnderstandSample" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Language: string # An ISO language-country string of the sample.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Language" $Language "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Samples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: CreateUnderstandSample
export def "understand-assistants-tasks-samples CreateUnderstandSample" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Language: string # An ISO language-country string of the sample.
  --SourceChannel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  TaggedText: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Samples")
  let body = {Language: $Language, SourceChannel: $SourceChannel, TaggedText: $TaggedText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: DeleteUnderstandSample
export def "understand-assistants-tasks-samples DeleteUnderstandSample" [
  AssistantSid: string
  TaskSid: string
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Samples/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: FetchUnderstandSample
export def "understand-assistants-tasks-samples FetchUnderstandSample" [
  AssistantSid: string
  TaskSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Samples/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: UpdateUnderstandSample
export def "understand-assistants-tasks-samples UpdateUnderstandSample" [
  AssistantSid: string
  TaskSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Language: string # An ISO language-country string of the sample.
  --SourceChannel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  --TaggedText: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Samples/($Sid)")
  let body = {Language: $Language, SourceChannel: $SourceChannel, TaggedText: $TaggedText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics
#
# operationId: FetchUnderstandTaskStatistics
export def "understand-assistants-tasks-statistics FetchUnderstandTaskStatistics" [
  AssistantSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($AssistantSid)/Tasks/($TaskSid)/Statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /understand/Assistants/{Sid}
#
# operationId: DeleteUnderstandAssistant
export def "understand-assistants DeleteUnderstandAssistant" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /understand/Assistants/{Sid}
#
# operationId: FetchUnderstandAssistant
export def "understand-assistants FetchUnderstandAssistant" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /understand/Assistants/{Sid}
#
# operationId: UpdateUnderstandAssistant
export def "understand-assistants UpdateUnderstandAssistant" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackEvents: string # Space-separated list of callback events that will trigger callbacks.
  --CallbackUrl: string # A user-provided URL to send event callbacks to. (format: uri)
  --FallbackActions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --FriendlyName: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --InitiationActions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --LogQueries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --StyleSheet: any # The JSON object that holds the style sheet for the assistant
  --UniqueName: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/understand/Assistants/($Sid)")
  let body = {CallbackEvents: $CallbackEvents, CallbackUrl: $CallbackUrl, FallbackActions: $FallbackActions, FriendlyName: $FriendlyName, InitiationActions: $InitiationActions, LogQueries: $LogQueries, StyleSheet: $StyleSheet, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /wireless/Commands
#
# operationId: ListWirelessCommand
export def "wireless-commands ListWirelessCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Device: string
  --Sim: string
  --Status: string
  --Direction: string
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<commands: table<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Device" $Device "scalar") (serialize-qp "Sim" $Sim "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "Direction" $Direction "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/Commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /wireless/Commands
#
# operationId: CreateWirelessCommand
export def "wireless-commands CreateWirelessCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackMethod: string
  --CallbackUrl: string # format: uri
  Command: string
  --CommandMode: string
  --Device: string
  --IncludeSid: string
  --Sim: string
]: any -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/wireless/Commands")
  let body = {CallbackMethod: $CallbackMethod, CallbackUrl: $CallbackUrl, Command: $Command, CommandMode: $CommandMode, Device: $Device, IncludeSid: $IncludeSid, Sim: $Sim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /wireless/Commands/{Sid}
#
# operationId: FetchWirelessCommand
export def "wireless-commands FetchWirelessCommand" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/Commands/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /wireless/RatePlans
#
# operationId: ListWirelessRatePlan
export def "wireless-rate-plans ListWirelessRatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_plans: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/RatePlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /wireless/RatePlans
#
# operationId: CreateWirelessRatePlan
export def "wireless-rate-plans CreateWirelessRatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CommandsEnabled: oneof<nothing, bool>
  --DataEnabled: oneof<nothing, bool>
  --DataLimit: int
  --DataMetering: string
  --FriendlyName: string
  --InternationalRoaming: list
  --MessagingEnabled: oneof<nothing, bool>
  --NationalRoamingEnabled: oneof<nothing, bool>
  --UniqueName: string
  --VoiceEnabled: oneof<nothing, bool>
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/wireless/RatePlans")
  let body = {CommandsEnabled: $CommandsEnabled, DataEnabled: $DataEnabled, DataLimit: $DataLimit, DataMetering: $DataMetering, FriendlyName: $FriendlyName, InternationalRoaming: $InternationalRoaming, MessagingEnabled: $MessagingEnabled, NationalRoamingEnabled: $NationalRoamingEnabled, UniqueName: $UniqueName, VoiceEnabled: $VoiceEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /wireless/RatePlans/{Sid}
#
# operationId: DeleteWirelessRatePlan
export def "wireless-rate-plans DeleteWirelessRatePlan" [
  Sid: string
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
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/RatePlans/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /wireless/RatePlans/{Sid}
#
# operationId: FetchWirelessRatePlan
export def "wireless-rate-plans FetchWirelessRatePlan" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/RatePlans/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /wireless/RatePlans/{Sid}
#
# operationId: UpdateWirelessRatePlan
export def "wireless-rate-plans UpdateWirelessRatePlan" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string
  --UniqueName: string
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/RatePlans/($Sid)")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /wireless/Sims
#
# operationId: ListWirelessSim
export def "wireless-sims ListWirelessSim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string
  --Iccid: string
  --RatePlan: string
  --EId: string
  --SimRegistrationCode: string
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "Iccid" $Iccid "scalar") (serialize-qp "RatePlan" $RatePlan "scalar") (serialize-qp "EId" $EId "scalar") (serialize-qp "SimRegistrationCode" $SimRegistrationCode "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/Sims" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /wireless/Sims/{Sid}
#
# operationId: FetchWirelessSim
export def "wireless-sims FetchWirelessSim" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/Sims/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /wireless/Sims/{Sid}
#
# operationId: UpdateWirelessSim
export def "wireless-sims UpdateWirelessSim" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackMethod: string
  --CallbackUrl: string # format: uri
  --CommandsCallbackMethod: string@CommandsCallbackMethod-completer # format: http-method
  --CommandsCallbackUrl: string # format: uri
  --FriendlyName: string
  --RatePlan: string
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # format: http-method
  --SmsFallbackUrl: string # format: uri
  --SmsMethod: string@SmsMethod-completer # format: http-method
  --SmsUrl: string # format: uri
  --Status: string
  --UniqueName: string
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # format: http-method
  --VoiceFallbackUrl: string # format: uri
  --VoiceMethod: string@VoiceMethod-completer # format: http-method
  --VoiceUrl: string # format: uri
]: any -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base $"/wireless/Sims/($Sid)")
  let body = {CallbackMethod: $CallbackMethod, CallbackUrl: $CallbackUrl, CommandsCallbackMethod: $CommandsCallbackMethod, CommandsCallbackUrl: $CommandsCallbackUrl, FriendlyName: $FriendlyName, RatePlan: $RatePlan, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, Status: $Status, UniqueName: $UniqueName, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /wireless/Sims/{SimSid}/Usage
#
# operationId: FetchWirelessUsage
export def "wireless-sims-usage FetchWirelessUsage" [
  SimSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --End: string
  --Start: string
]: nothing -> record<account_sid: string, commands_costs: any, commands_usage: any, data_costs: any, data_usage: any, period: any, sim_sid: string, sim_unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "End" $End "scalar") (serialize-qp "Start" $Start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless/Sims/($SimSid)/Usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
