# Auto-generated client for Loadsmart API v1.0.0
# Source: https://raw.githubusercontent.com/api-evangelist/loadsmart/main/openapi/loadsmart-shipperguide-openapi.yml
# Auth: --token flag or $env.LOADSMART_API_TOKEN

const BASE_URL = "https://api.loadsmart.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOADSMART_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.loadsmart.com" "https://api.sandbox.loadsmart.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def document-type-completer [] { ["authority" "insurance" "w9"] }
def verification-channel-completer [] { ["email" "sms"] }
def type-completer [] { ["shipment:carrier-updated" "shipment:check-in-delivery" "shipment:check-in-pickup" "shipment:check-out-delivery" "shipment:check-out-pickup" "shipment:en-route-to-pickup" "shipment:incident"] }
def type-completer-1 [] { ["carrier-invoice" "other" "proof-of-delivery"] }
def equipment-type-completer [] { ["BLK" "CON" "CUR" "DDP" "DRV" "FBE" "IMC" "LTL" "OTH" "RFR" "SDK" "STK" "TNK"] }
def event-completer [] { ["load_cancelled" "load_carrier_bounced" "offer_created" "offer_removed"] }
def status-completer [] { ["accepted" "awarded" "pending" "refused" "timed_out"] }
def equipment-type-completer-1 [] { ["BLK" "CON" "CUR" "DDP" "DRV" "FBE" "IMC" "OTH" "RFR" "SDK" "STK" "TNK"] }
def type-completer-2 [] { ["bid:accepted" "bid:awarded" "bid:expired" "bid:refused" "bid:timed_out"] }
def type-completer-3 [] { ["carrier:status:changed"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "carrier-search get" } } | get name | first)
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

# Search a carrier
#
# GET /api/v2/carrier/search
export def "carrier-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mc: string # format: integer
  --dot: string # format: integer
]: nothing -> record<id: string, name: string, mc: string, dot: string, eligible: any, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mc" $mc "scalar") (serialize-qp "dot" $dot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/carrier/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of integrations
#
# GET /api/v2/carrier/integrations
export def "carrier-integrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string>, count: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Integration for a Carrier
#
# POST /api/v2/carrier/integration-request
# --owner shape: {first_name: string, last_name: string, email: string, phone_number?: string, phone_number_extension?: string}
export def "carrier-integration-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  carrier_id: string # Carrier UUID
  --owner: record # Company main contact information. — shape: {first_name: string, last_name: string, email: string, phone_number?: string, phone_number_extension?: string}
]: any -> record<id: string, account_id: string, carrier: record<id: string, mc: string, dot: string, name: string, eligible: any, status: string>, status: string, documents: table<type: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/integration-request")
  let body = {carrier_id: $carrier_id, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Carrier Integration Request status
#
# GET /api/v2/carrier/integration-request
export def "carrier-integration-request list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, carrier_id: string, mc: string, dot: string, name: string, status: string>, count: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/integration-request")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail Carrier Integration Request status
#
# GET /api/v2/carrier/integration-request/{id}
export def "carrier-integration-request get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, carrier: record<id: string, mc: string, dot: string, name: string, eligible: any, status: string>, status: string, documents: table<type: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/carrier/integration-request/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload document
#
# POST /api/v2/carrier/documents
export def "carrier-documents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --document-type: string@document-type-completer # Type of document: `w9`: Form W9 `insurance`: Certificate of Insurance `authority`: Letter of Authority
  --document: string # format: binary
]: any -> record<document_url: string, type: string, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/documents")
  let body = {document_type: $document_type, document: $document} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List drivers
#
# GET /api/v2/carrier/drivers
export def "carrier-drivers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, name: string, phone_number: string, sms_enabled: bool, location: record>, count: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/drivers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create driver
#
# POST /api/v2/carrier/drivers
export def "carrier-drivers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Driver's full name
  --phone-number: string # Phone number following the format [E.164](https://www.itu.int/rec/T-REC-E.164/) (nullable)
  --sms-enabled: oneof<nothing, bool> # If this driver can receive Loadsmart text messages (default: true)
]: any -> record<data: record<id: string, name: string, phone_number: string, sms_enabled: bool, location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/carrier/drivers")
  let body = {name: $name, phone_number: $phone_number, sms_enabled: $sms_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve driver
#
# GET /api/v2/carrier/{driver_id}
export def "carrier get" [
  driver_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, name: string, phone_number: string, sms_enabled: bool, location: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/carrier/($driver_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update driver
#
# PUT /api/v2/carrier/{driver_id}
export def "carrier put" [
  driver_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Driver's full name
  --phone-number: string # Phone number following the format [E.164](https://www.itu.int/rec/T-REC-E.164/) (nullable)
  --sms-enabled: oneof<nothing, bool> # If this driver can receive Loadsmart text messages (default: true)
]: any -> record<data: record<id: string, name: string, phone_number: string, sms_enabled: bool, location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/carrier/($driver_id)")
  let body = {name: $name, phone_number: $phone_number, sms_enabled: $sms_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a driver
#
# DELETE /api/v2/carrier/{driver_id}
export def "carrier delete" [
  driver_id: any
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
  let full_url = (build-url $base $"/api/v2/carrier/($driver_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set empty location
#
# POST /api/v2/shipments/{shipment_id}/empty_location
export def "shipments-empty-location post" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  city: string # Truck empty location's city
  state: string # Truck empty location's state
  zipcode: string # Truck empty location's zipcode (first five digits)
  available_date: string # The date and time the truck is going to be available (UTC) (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/empty_location")
  let body = {city: $city, state: $state, zipcode: $zipcode, available_date: $available_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Driver
#
# POST /api/v2/shipments/{shipment_id}/assign_driver
export def "shipments-assign-driver post" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --driver-id: string # Unique identifier for the driver.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/assign_driver")
  let body = {driver_id: $driver_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create shipper
#
# POST /api/v2/shippers
# --account shape: {email: string, first_name?: string, last_name?: string, phone_number?: string, verification_channel?: "email"|"sms"}
export def "shippers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  company_name: string # Company name
  --account: record # shape: {email: string, first_name?: string, last_name?: string, phone_number?: string, verification_channel?: "email"|"sms"}
]: any -> record<data: record<id: string, company_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/shippers")
  let body = {company_name: $company_name, account: $account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update shipper
#
# PATCH /api/v2/shippers/{shipper_id}
export def "shippers patch" [
  shipper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  company_name: string # Company name
]: any -> record<data: record<id: string, company_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/($shipper_id)")
  let body = {company_name: $company_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create account
#
# POST /api/v2/shippers/accounts
export def "shippers-accounts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipper_id: string # Unique identifier for the shipper who this user belongs to (format: uuid)
  email: string # User's email address (format: email)
  --first-name: string # User's first name
  --last-name: string # User's last name
  --phone-number: string # Phone number following the format [E.164](https://www.itu.int/rec/T-REC-E.164/) (nullable)
  --verification-channel: string@verification-channel-completer # Channel selected to send the verification code
  --password: string # Password the user will use to log into Loadsmart's website or in OAuth requests
]: any -> record<data: record<id: string, shipper_id: string, email: string, first_name: string, last_name: string, phone_number: string, verification_channel: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/shippers/accounts")
  let body = {shipper_id: $shipper_id, email: $email, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, verification_channel: $verification_channel, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve account
#
# GET /api/v2/shippers/accounts/{account_id}
export def "shippers-accounts get" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, shipper_id: string, email: string, first_name: string, last_name: string, phone_number: string, verification_channel: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update account
#
# PATCH /api/v2/shippers/accounts/{account_id}
export def "shippers-accounts patch" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipper_id: string # Unique identifier for the shipper who this user belongs to (format: uuid)
  email: string # User's email address (format: email)
  --first-name: string # User's first name
  --last-name: string # User's last name
  --phone-number: string # Phone number following the format [E.164](https://www.itu.int/rec/T-REC-E.164/) (nullable)
  --verification-channel: string@verification-channel-completer # Channel selected to send the verification code
  --password: string # Password the user will use to log into Loadsmart's website or in OAuth requests
]: any -> record<data: record<id: string, shipper_id: string, email: string, first_name: string, last_name: string, phone_number: string, verification_channel: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/accounts/($account_id)")
  let body = {shipper_id: $shipper_id, email: $email, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, verification_channel: $verification_channel, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create shipper billing info
#
# POST /api/v2/shippers/{shipper_id}/info
export def "shippers-info post" [
  shipper_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  billing_name: string
  billing_address: string
  billing_city: string
  billing_zip_code: string
  billing_country: string
  billing_state: string
  --tax-id: string
  contact_name: string
  contact_email: string
  contact_phone: string
  terms: int
  notes: string
]: any -> record<data: record<billing_name: string, billing_address: string, billing_city: string, billing_zip_code: string, billing_country: string, billing_state: string, tax_id: string, contact_name: string, contact_email: string, contact_phone: string, terms: int, notes: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/($shipper_id)/info")
  let body = {billing_name: $billing_name, billing_address: $billing_address, billing_city: $billing_city, billing_zip_code: $billing_zip_code, billing_country: $billing_country, billing_state: $billing_state, tax_id: $tax_id, contact_name: $contact_name, contact_email: $contact_email, contact_phone: $contact_phone, terms: $terms, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Shipper Accounting Info
#
# GET /api/v2/shippers/{shipper_id}/info
export def "shippers-info get" [
  shipper_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<billing_name: string, billing_address: string, billing_city: string, billing_zip_code: string, billing_country: string, billing_state: string, tax_id: string, contact_name: string, contact_email: string, contact_phone: string, terms: int, notes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/($shipper_id)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shipper billing info
#
# PUT /api/v2/shippers/{shipper_id}/info
export def "shippers-info put" [
  shipper_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  billing_name: string
  billing_address: string
  billing_city: string
  billing_zip_code: string
  billing_country: string
  billing_state: string
  --tax-id: string
  contact_name: string
  contact_email: string
  contact_phone: string
  terms: int
  notes: string
]: any -> record<data: record<billing_name: string, billing_address: string, billing_city: string, billing_zip_code: string, billing_country: string, billing_state: string, tax_id: string, contact_name: string, contact_email: string, contact_phone: string, terms: int, notes: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shippers/($shipper_id)/info")
  let body = {billing_name: $billing_name, billing_address: $billing_address, billing_city: $billing_city, billing_zip_code: $billing_zip_code, billing_country: $billing_country, billing_state: $billing_state, tax_id: $tax_id, contact_name: $contact_name, contact_email: $contact_email, contact_phone: $contact_phone, terms: $terms, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a shipment
#
# DELETE /api/v2/shipments/{shipment_id}
export def "shipments delete" [
  shipment_id: any
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
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve details from a shipment
#
# GET /api/v2/shipments/{shipment_id}
export def "shipments get" [
  shipment_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, ref_number: string, bol_number: string, purchase_order_numbers: list<string>, stops: table<stop_index: float, address: string, city: string, state: string, zipcode: string>, requirements: record<hazmat: bool, tarp: record<size: float, type: string>, dunnage: bool, beer: bool, teams: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show interest in a shipment.
#
# POST /api/v2/shipments/{shipment_id}/interested
export def "shipments-interested post" [
  shipment_id: string
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
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/interested")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shipment event
#
# POST /api/v2/shipments/{shipment_id}/events
export def "shipments-events post" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Event type
  --event-date: string # The date and time of the event (if not informed, current date is used) (format: date-time)
  --stop-index: int # Corresponds to the number of the stop, being 0-based for pickup
  --details: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/events")
  let body = {type: $type, event_date: $event_date, stop_index: $stop_index, details: $details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List shipment events.
#
# GET /api/v2/shipments/{shipment_id}/events
export def "shipments-events get" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # format: int32
  --limit: int # format: int32
  --type: string
]: nothing -> record<data: list<any>, previous: string, next: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shipment action log entry
#
# POST /api/v2/shipments/{shipment_id}/action-logs
export def "shipments-action-logs post" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string # Action text to record for this shipment (max 255 characters).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/action-logs")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Confirm stop appointment
#
# PUT /api/v2/shipments/{shipment_id}/stops/{stop_id}/confirm_appointment
export def "shipments-stops-confirm-appointment put" [
  shipment_id: string
  stop_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: oneof<nothing, bool> # If it is confirmed
  --window-start: string # A datetime that represents the start of a time window for this appointment. In UTC time. (format: date-time)
  --window-end: string # A datetime that represents the end of a time window for this appointment. In UTC time. (format: date-time)
  --scheduler-appt-id: string # An ID that represents this appointment. (format: uuid)
  --confirmation-number: string # A number that identifies this appointment.
  --contact-name: string # The contact name responsible for this appointment.
]: any -> record<data: record<confirmed: bool, window_start: string, window_end: string, scheduler_appt_id: string, confirmation_number: string, contact_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipments/($shipment_id)/stops/($stop_id)/confirm_appointment")
  let body = {confirmed: $confirmed, window_start: $window_start, window_end: $window_end, scheduler_appt_id: $scheduler_appt_id, confirmation_number: $confirmation_number, contact_name: $contact_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create shipment document
#
# POST /api/v2/shipment-documents
export def "shipment-documents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipment: string # The shipment UUID or Loadsmart ref number.
  file_obj: any # The shipment pdf file.
  file_name: string # The file name.
  type: string@type-completer-1 # The file type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/shipment-documents")
  let body = {shipment: $shipment, file_obj: $file_obj, file_name: $file_name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List shipment documents
#
# GET /api/v2/shipment-documents/?shipment=${shipment}
export def "shipment-documents-shipment-shipment get" [
  shipment_uuid_or_loadsmart_ref_number: string
  shipment: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: int, shipment: string, shipment_loadsmart_ref_number: string, created_at: string, type: any, file_name: string, url: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/shipment-documents/?shipment=$($shipment)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create quote request
#
# POST /api/v2/quotes-request
# --requirements shape: {hazmat?: bool, tarp?: record, dunnage?: bool, beer?: bool, teams?: bool}
# --items item shape: {items_count: any, length: any, width: any, height: any, classification: "50"|"55"|"60"|"65"|"70"|"77.5"|"85"|"92.5"|"100"|"110"|"125"|"150"|"175"|"200"|"250"|"300"|"400"|"500", nmfc_code?: string, package_type: "std_pallets"|"pallets_non_std"|"bags"|"bales"|"boxes"|"bunches"|"carpets"|"coils"|"crates"|"cylinders"|"drums"|"pails"|"reels"|"rolls"|"tubes_pipes"|"loose"|"ubox", hazmat: bool, hazmat_class?: "explosive_non_specified"|"mass_explosive"|"projection_explosive"|"minor_fire_explosive"|"minor_explosive"|"insensitive_mass_explosive"|"insensitive_minor_explosive"|"gas_non_specified"|"flammable_gas"|"non_flammable_non_poisonous_or_oxygen_gas"|"poison_gas"|"flammable_liquid"|"solid_non_specified"|"flammable_solid"|"spontaneously_combustible_solid"|"dangerous_when_wet"|"oxidizer_non_specified"|"oxidizer"|"organic_peroxide"|"poison"|"radioactive", un_number?: string, stackable: bool, description: string, weight: any}
export def "quotes-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipment_mode: any
  equipments: any
  --total-width: float # The load total width expressed in 'ft'
  --total-length: float # The load total length expressed in 'ft'
  --total-height: float # The load total height expressed in 'ft'
  --requirements: record # Requirements that needs to be fulfilled in order to transport the load (nullable) — shape: {hazmat?: bool, tarp?: record, dunnage?: bool, beer?: bool, teams?: bool}
  --customer-reference: string # Internal client's reference, such as an ID, of the load
  --accessorials: list # Accessorials are extra charges/services that exist outside the 'normal' standard operating procedure. They are upcharged by the Carriers, and are qualifiers for Carrier Eligibility. FTL loads do not accept accessorials on the quote request.
  stops: list # Points of interest where the truck makes a stop to either pickup or deliver a shipment. Usually a quote has one pickup stop and one delivery stop, but in some cases there will be multiple delivery stops.
  --items: list # A list of actual packages that will be moved within the load. One quote - that later will become a shipment - may have none or many Items. These Items will have a lot of different attributes related to it, but specially Dimensions, Weight, Freight Class among some others — item shape: {items_count: any, length: any, width: any, height: any, classification: "50"|"55"|"60"|"65"|"70"|"77.5"|"85"|"92.5"|"100"|"110"|"125"|"150"|"175"|"200"|"250"|"300"|"400"|"500", nmfc_code?: string, package_type: "std_pallets"|"pallets_non_std"|"bags"|"bales"|"boxes"|"bunches"|"carpets"|"coils"|"crates"|"cylinders"|"drums"|"pails"|"reels"|"rolls"|"tubes_pipes"|"loose"|"ubox", hazmat: bool, hazmat_class?: "explosive_non_specified"|"mass_explosive"|"projection_explosive"|"minor_fire_explosive"|"minor_explosive"|"insensitive_mass_explosive"|"insensitive_minor_explosive"|"gas_non_specified"|"flammable_gas"|"non_flammable_non_poisonous_or_oxygen_gas"|"poison_gas"|"flammable_liquid"|"solid_non_specified"|"flammable_solid"|"spontaneously_combustible_solid"|"dangerous_when_wet"|"oxidizer_non_specified"|"oxidizer"|"organic_peroxide"|"poison"|"radioactive", un_number?: string, stackable: bool, description: string, weight: any}
  --properties: record # General information about the load. This is an open JSON field that allows passing special properties with meaning on the customer context, such as the order numbers, must_arrive_by_date, priority and others.
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/quotes-request")
  let body = {shipment_mode: $shipment_mode, equipments: $equipments, total_width: $total_width, total_length: $total_length, total_height: $total_height, requirements: $requirements, customer_reference: $customer_reference, accessorials: $accessorials, stops: $stops, items: $items, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve details from a quote request
#
# GET /api/v2/quotes-request/{uuid}
export def "quotes-request get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, status: string, reject_reason: string, mileage: float, quotes: list<record>, items: list<record>, stops: list<any>, suggested_mode: string, equipments: list<record>, total_width: float, total_length: float, total_height: float, requirements: record<hazmat: bool, tarp: record, dunnage: bool, beer: bool, teams: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/quotes-request/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search offers
#
# GET /api/v2/load-offers/offers
export def "load-offers-offers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alcohol: string # format: boolean
  --equipment-type: string@equipment-type-completer
  --start-date: string # format: YYYY-MM-DD
  --end-date: string # format: YYYY-MM-DD
  --origin-lat: float
  --origin-lon: float
  --origin-radius: float # format: integer
  --destination-lat: float
  --destination-lon: float
  --destination-radius: float # format: integer
  --mc: string
  --dot: string
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, price: float, load: record, actions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alcohol" $alcohol "scalar") (serialize-qp "equipment_type" $equipment_type "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "origin_lat" $origin_lat "scalar") (serialize-qp "origin_lon" $origin_lon "scalar") (serialize-qp "origin_radius" $origin_radius "scalar") (serialize-qp "destination_lat" $destination_lat "scalar") (serialize-qp "destination_lon" $destination_lon "scalar") (serialize-qp "destination_radius" $destination_radius "scalar") (serialize-qp "mc" $mc "scalar") (serialize-qp "dot" $dot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/load-offers/offers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve offer
#
# GET /api/v2/load-offers/offers/{offer_id}
export def "load-offers-offers get" [
  offer_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offer-id: string # format: uuid
]: nothing -> record<id: string, price: float, load: record<equipment_type: string, commodity: string, weight: float, dimensions: record<weight: float, height: float, width: float>, distance: float, stops: list<record>, requirements: record<beer: bool, chemicals: bool, ctpat: bool, food_grade: bool, frozen: bool, hazmat: bool, hvhr: bool, pharmaceuticals: bool, produce: bool, teams: bool, tsa: bool, twic: bool, vented_vans: bool>, ref_number: string>, actions: record<redirect_url: string, accept_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offer_id" $offer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/load-offers/offers/($offer_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept an offer
#
# POST /api/v2/load-offers/offers/{offer_id}/accept
export def "load-offers-offers-accept post" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/offers/($offer_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search related offers
#
# GET /api/v2/load-offers/offers/{offer_id}/related
export def "load-offers-offers-related get" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relation: string
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, price: float, relation: string, load: record, actions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "relation" $relation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/load-offers/offers/($offer_id)/related" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List loads
#
# GET /api/v2/load-offers/loads/
export def "load-offers-loads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, active_offer: record, carrier: record, equipment_type: string, commodity: string, weight: float, dimensions: record, distance: float, stops: list, requirements: record, ref_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/load-offers/loads/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a load
#
# GET /api/v2/load-offers/loads/{load_id}
export def "load-offers-loads get" [
  load_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, active_offer: record<id: string, price: float>, carrier: record<id: string, dot: string, mc: string>, equipment_type: string, commodity: string, weight: float, dimensions: record<weight: float, height: float, width: float>, distance: float, stops: table<type: string, address: string, city: string, state: string, country: string, latitude: float, longitude: float, zipcode: string, window_start: string, window_end: string, window_timezone: string, requirements: list, facility_info: record>, requirements: record<beer: bool, chemicals: bool, ctpat: bool, food_grade: bool, frozen: bool, hazmat: bool, hvhr: bool, pharmaceuticals: bool, produce: bool, teams: bool, tsa: bool, twic: bool, vented_vans: bool>, ref_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/loads/($load_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Drop a load
#
# DELETE /api/v2/load-offers/loads/{load_id}
export def "load-offers-loads delete" [
  load_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reason: string # Reason for dropping the load
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/loads/($load_id)")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download ratecon
#
# GET /api/v2/load-offers/loads/{load_id}/rate_confirmation
export def "load-offers-loads-rate-confirmation get" [
  load_id: string
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
  let full_url = (build-url $base $"/api/v2/load-offers/loads/($load_id)/rate_confirmation")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search related offers
#
# GET /api/v2/load-offers/loads/{load_id}/related-offers
export def "load-offers-loads-related-offers get" [
  load_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relation: string
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, price: float, relation: string, load: record, actions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "relation" $relation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/load-offers/loads/($load_id)/related-offers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /api/v2/load-offers/webhooks
export def "load-offers-webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, url: string, event: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/load-offers/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register webhooks
#
# POST /api/v2/load-offers/webhooks
export def "load-offers-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # URL to be called when proper event happens
  event: string@event-completer # Action that will trigger the endpoint
]: any -> record<id: string, url: string, event: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/load-offers/webhooks")
  let body = {url: $body_url, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve webhook
#
# GET /api/v2/load-offers/webhooks/{uuid}
export def "load-offers-webhooks get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, event: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/webhooks/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /api/v2/load-offers/webhooks/{uuid}
export def "load-offers-webhooks put" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # URL to be called when proper event happens
  event: string@event-completer # Action that will trigger the endpoint
]: any -> record<id: string, url: string, event: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/webhooks/($uuid)")
  let body = {url: $body_url, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /api/v2/load-offers/webhooks/{uuid}
export def "load-offers-webhooks delete" [
  uuid: string
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
  let full_url = (build-url $base $"/api/v2/load-offers/webhooks/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Bids
#
# GET /api/v2/load-offers/bids
export def "load-offers-bids list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # The status of the bid
]: nothing -> record<count: float, next: string, previous: string, results: table<id: string, offer_id: string, price: string, created_at: any, expires_at: any, expired_at: any, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/load-offers/bids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Bid
#
# POST /api/v2/load-offers/bids
export def "load-offers-bids post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offer-id: string # Offer unique identifier (UUID). (format: uuid)
  --price: string # Bid Price (USD)
]: any -> record<id: string, offer_id: string, price: string, created_at: any, expires_at: any, expired_at: any, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/load-offers/bids")
  let body = {offer_id: $offer_id, price: $price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Bid
#
# GET /api/v2/load-offers/bids/{bid_id}
export def "load-offers-bids get" [
  bid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, offer_id: string, price: string, created_at: any, expires_at: any, expired_at: any, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/bids/($bid_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Bid
#
# POST /api/v2/load-offers/bids/{bid_id}/accept
export def "load-offers-bids-accept post" [
  bid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/load-offers/bids/($bid_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Load Events
#
# GET /api/v2/loads/{load_id}/events
export def "loads-events get" [
  load_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: float, next: string, previous: string, data: table<id: string, action: string, created: string, load_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/loads/($load_id)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tender
#
# POST /api/v2/loads/tender
# --contacts item shape: {name: string, email?: string, phone_number?: string}
# --purchase_order_numbers item shape: {po_number?: string}
# --requirements shape: {promotion_load?: bool, emergency_response?: bool, hazmat?: bool, beer?: bool, twic?: bool, ctpat?: bool, teams?: bool, food_grade?: bool, frozen?: bool, produce?: bool, pharmaceuticals?: bool, chemicals?: bool, tsa?: bool, hvhr?: bool, vented_vans?: bool}
# --bill_to shape: {company_name?: string, address1?: string, address2?: string, city?: string, zipcode?: string, state?: string, country?: string}
export def "loads-tender post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: any # default: FTL
  equipment_type: string@equipment-type-completer-1 # Equipment required to transport the shipment. Recognized equipments are:   - DRV: Dry Van   - FBE: Flatbed   - RFR: Reefer   - CON: Conestoga   - CUR: Curtainside   - DDP: Double Drop   - IMC: Intermodal   - SDK: Step Deck   - STK: Straight truck   - BLK: Bulk   - TNK: Tanker   - OTH: Other equipment not explicited listed
  customer_ref: string # Internal client's reference, such as an ID, of the tender
  --quote-id: string # Reference for the quote that should be used to book the load
  --commodity: string # Name of the commodity that will be shipped
  --body-source: string # Field used to indicate the context where the tender request was made (in a contract, routing guide process or spot bid, for example)
  --weight: any # The total weight, in pounds, of the shipment. Acceptable values must be positive numbers with up to 2 decimal digits. Any other type will cause a validation error. Note that the minimum value is 1 and the maximum value depends on the chosen equipment_type: 45000 for DRV, 43000 for RFR and 50000 for FBE. If the weight is not provided, it is set to the maximum allowed for the equipment_type.
  stops: list # Points of interest where the truck makes a stop to either pickup or deliver a shipment. Usually a tender has one pickup stop and one delivery stop, but in some cases there will be multiple delivery stops.
  --contacts: list # At least name or phone number should be provided for each contact. — item shape: {name: string, email?: string, phone_number?: string}
  --purchase-order-numbers: list # Purchase Order Numbers for the load — item shape: {po_number?: string}
  --properties: record # General information about the load. This is an open JSON field that allows passing special properties with meaning on the customer context, such as the order numbers, must_arrive_by_date, and others.
  --requirements: record # An object with any specific requirement for this tender — shape: {promotion_load?: bool, emergency_response?: bool, hazmat?: bool, beer?: bool, twic?: bool, ctpat?: bool, teams?: bool, food_grade?: bool, frozen?: bool, produce?: bool, pharmaceuticals?: bool, chemicals?: bool, tsa?: bool, hvhr?: bool, vented_vans?: bool}
  --bill-to: record # An object with billing information — shape: {company_name?: string, address1?: string, address2?: string, city?: string, zipcode?: string, state?: string, country?: string}
  --bol-number: string # the bill of lading number for the tender
]: any -> record<data: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/loads/tender")
  let body = {mode: $mode, equipment_type: $equipment_type, customer_ref: $customer_ref, quote_id: $quote_id, commodity: $commodity, source: $body_source, weight: $weight, stops: $stops, contacts: $contacts, purchase_order_numbers: $purchase_order_numbers, properties: $properties, requirements: $requirements, bill_to: $bill_to, bol_number: $bol_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Estimate distance and duration
#
# GET /api/v2/routes/estimate-trip-duration
export def "routes-estimate-trip-duration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --origin: string # Address (complete or partial) for the origin
  --destination: string # Address (complete or partial) for the destination
]: nothing -> record<data: record<duration: string, miles: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/routes/estimate-trip-duration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create capacity
#
# POST /api/v2/capacity
export def "capacity post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/capacity")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Capacity
#
# DELETE /api/v2/capacity/{capacity_ref_number}
export def "capacity delete" [
  ref_number: string
  capacity_ref_number: any
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
  let full_url = (build-url $base $"/api/v2/capacity/($capacity_ref_number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhooks
#
# GET /api/v2/webhooks/url
export def "webhooks-url list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: float, next: string, previous: string, results: table<uuid: string, events: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/webhooks/url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register webhooks
#
# POST /api/v2/webhooks/url
export def "webhooks-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list
  --body-url: string # URL to post the webhooks (format: URL)
]: any -> record<uuid: string, events: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/webhooks/url")
  let body = {events: $events, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve webhook
#
# GET /api/v2/webhooks/url/{uuid}
export def "webhooks-url get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, events: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/webhooks/url/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /api/v2/webhooks/url/{uuid}
export def "webhooks-url put" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list
  --body-url: string # URL to post the webhooks (format: URL)
]: any -> record<uuid: string, events: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/webhooks/url/($uuid)")
  let body = {events: $events, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /api/v2/webhooks/url/{uuid}
export def "webhooks-url delete" [
  uuid: string
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
  let full_url = (build-url $base $"/api/v2/webhooks/url/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quote Events
#
# POST /quote-webhooks
# --details shape: {event?: record, shipment?: record, shipper?: record}
export def "quote-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details: record # shape: {event?: record, shipment?: record, shipper?: record}
  --created-at: string # The date and time of the event. (format: date-time)
  --type: string # Event type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quote-webhooks")
  let body = {details: $details, created_at: $created_at, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Shipment Events
#
# POST /shipment-webhooks
# --details shape: {shipment?: record, shipper?: record, event?: record}
export def "shipment-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details: record # shape: {shipment?: record, shipper?: record, event?: record}
  --shipment-id: string # The shipment identifier (format: uuid)
  --created-at: string # The date and time of the event creation (format: date-time)
  --type: string # Event type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipment-webhooks")
  let body = {details: $details, shipment_id: $shipment_id, created_at: $created_at, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Events
#
# POST /load-webhooks
# --details shape: {shipment?: record, load?: record, shipper?: record}
export def "load-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details: record # shape: {shipment?: record, load?: record, shipper?: record}
  --created-at: string # The date and time of the event. (format: date-time)
  --type: string # Event type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/load-webhooks")
  let body = {details: $details, created_at: $created_at, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bid Events
#
# POST /bid-webhooks
# --details shape: {id?: string, offer_id?: string, price?: string, created_at?: any, expires_at?: any, expired_at?: any, status?: "pending"|"awarded"|"accepted"|"timed_out"|"refused"}
export def "bid-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details: record # shape: {id?: string, offer_id?: string, price?: string, created_at?: any, expires_at?: any, expired_at?: any, status?: "pending"|"awarded"|"accepted"|"timed_out"|"refused"}
  --created-at: string # The date and time of the event. (format: date-time)
  --type: string@type-completer-2 # Event type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bid-webhooks")
  let body = {details: $details, created_at: $created_at, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Carrier Events
#
# POST /carrier-webhooks
# --details shape: {id?: string, mc?: string, dot?: string, name?: string, eligible?: any, status?: "New"|"Pending"|"Ready"|"Inactive", previous_status?: "New"|"Pending"|"Ready"|"Inactive"}
export def "carrier-webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details: record # shape: {id?: string, mc?: string, dot?: string, name?: string, eligible?: any, status?: "New"|"Pending"|"Ready"|"Inactive", previous_status?: "New"|"Pending"|"Ready"|"Inactive"}
  --created-at: string # The date and time of the event. (format: date-time)
  --type: string@type-completer-3 # Event type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier-webhooks")
  let body = {details: $details, created_at: $created_at, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Integration Request Events
#
# POST /integration-request
# --details shape: {id?: string, carrier_id?: string, mc?: string, dot?: string, name?: string, status?: "pending"|"accepted"|"rejected"}
export def "integration-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-at: string # The date and time of the event. (format: date-time)
  --type: string # Event type
  --details: record # shape: {id?: string, carrier_id?: string, mc?: string, dot?: string, name?: string, status?: "pending"|"accepted"|"rejected"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration-request")
  let body = {created_at: $created_at, type: $type, details: $details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve shipment scores
#
# GET /api/v2/shipmentscores
export def "shipmentscores get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for shipment scores (format: date)
  --end-date: string # End date for shipment scores (format: date)
  --shipper-uuid: any # Filter shipment scores by shipper
]: nothing -> record<data: table<shipment_uuid: any, shipment_ref: string, source: string, pickup_city: string, pickup_state: string, delivery_city: string, delivery_state: string, otp: bool, otd: bool, audited: bool, delivered_at: any, carrier_name: string, carrier_uuid: any, overridden: string, shipper_uuid: any>, count: float, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "shipper_uuid" $shipper_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/shipmentscores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
