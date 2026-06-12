# Auto-generated client for Opendock Nova API Documentation vv4.144.0 - 39b4253
# Source: https://raw.githubusercontent.com/api-evangelist/loadsmart/main/openapi/loadsmart-opendock-openapi.yml
# Auth: --token flag or $env.OPENDOCK_NOVA_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://neutron.opendock.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENDOCK_NOVA_API_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://neutron.opendock.com" "https://neutron.staging.opendock.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def refNumberValidationVersion-completer [] { ["V1" "V2"] }
def role-completer [] { ["role_admin" "role_attendant" "role_base" "role_carrier" "role_carrier_admin" "role_operator" "role_owner" "role_spectator" "role_yard_driver"] }
def type-completer [] { ["type_broker" "type_carrier" "type_carrier_broker" "type_forwarder"] }
def direction-completer [] { ["Inbound" "Inbound/Outbound" "Outbound"] }
def operation-completer [] { ["Drop" "Live" "Other"] }
def equipmentType-completer [] { ["Dry Van" "Flatbed" "Other" "Reefer"] }
def transportationMode-completer [] { ["FTL" "Other" "PTL"] }
def type-completer-1 [] { ["action" "bigstr" "bool" "combobox" "date" "doc" "dropdown" "dropdownmultiselect" "email" "int" "multidoc" "phone" "str" "timestamp"] }
def app-completer [] { ["all" "api" "carrier" "driver" "warehouse"] }
def category-completer [] { ["appointmentCreated" "appointmentStatusArrived" "appointmentStatusCompleted" "assetVisitCreated" "manualTrigger"] }
def feature-completer [] { ["Book Load Type" "Inbound Claim" "Outbound Claim" "appointment-completed" "asset container details" "check-in" "check-in additional asset details" "check-out"] }
def entityName-completer [] { ["dock" "loadtype" "warehouse"] }
def entityName-completer-1 [] { ["appointment" "assetcontainer" "assetvisit"] }
def status-completer [] { ["Arrived" "Cancelled" "Completed" "InProgress" "NoShow" "Requested" "Scheduled"] }
def type-completer-2 [] { ["Reserve" "Standard"] }
def startingStatus-completer [] { ["Requested" "Scheduled"] }
def visitType-completer [] { ["Drop" "DropHook" "Live" "LiveLoad" "LiveUnload" "PickUp" "Unknown"] }
def type-completer-3 [] { ["Chassis" "Container" "Other" "Oversized" "Reefer" "Trailer"] }
def state-completer [] { ["Empty" "Full" "Partially Loaded"] }
def eventType-completer [] { ["Arrived" "Departed" "Inoperable" "Loading" "Loading Complete" "Missing" "Ready for Pickup" "Unloading" "Unloading Complete"] }
def relatedEntity-completer [] { ["Appointment" "AssetContainer" "AssetContainerEvent" "AssetObservation" "AssetVisit" "AssetVisitEvent" "Bol" "Comment" "Company" "CustomFormData" "Dock" "Document" "Field" "Flow" "Form" "FormField" "Gate" "LoadType" "LoadTypeGroup" "MessageThread" "MessageThreadEvent" "MessageThreadMessage" "NotificationConfig" "Org" "OrgCarrierSettings" "Site" "Spot" "SpotArea" "SpotAssignment" "SpotReserve" "Trigger" "UnitLimit" "UnitLimitCount" "User" "VehicleObservation" "Warehouse" "WarehouseFeature" "WarehouseGroup" "YardTask" "YardTaskCheck" "YardTaskCheckAssetContainer" "YardTaskEvent" "YardTaskMove"] }
def type-completer-4 [] { ["docking" "parking"] }
def entityName-completer-2 [] { ["YardTask"] }
def departType-completer [] { ["All" "AssetContainer" "AssetVisit"] }
def dateField-completer [] { ["checkInDate" "checkOutDate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "general get" } } | get name | first)
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

# Shows a greeting message.
#
# GET /
# operationId: AppController_getBase
export def "general get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shows the current Nova version.
#
# GET /version
# operationId: AppController_getVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<major: float, minor: float, patch: float, commit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets public environment data for the app.
#
# GET /app-environment
# operationId: AppController_getAppEnvironment
export def "app-environment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<S3_BUCKET: string, S3_BASE: string, S3_DOWNLOAD_URL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app-environment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Warehouse
#
# GET /warehouse/{id}
# operationId: getOneBaseWarehouseControllerWarehouse
export def "warehouse get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: table<semanticLabelId: record, type: string>, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list<string>, amenities: list<string>, ppeRequirements: list<string>, intervalTrimForCarriers: float, customBookingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/warehouse/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Warehouse
#
# PATCH /warehouse/{id}
# operationId: updateOneBaseWarehouseControllerWarehouse
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
# --customApptFieldsTemplate item shape: {semanticLabelId?: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action"}
export def "warehouse updateOneBaseWarehouseControllerWarehouse" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --name: string
  --facilityNumber: string
  --country: string
  --timezone: string
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
  --contactName: record
  --phone: string
  --email: record
  --notes: record
  --instructions: record
  --customApptFieldsTemplate: list # item shape: {semanticLabelId?: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action"}
  --refNumberValidationVersion: string@refNumberValidationVersion-completer
  --refNumberValidationUrl: string
  --refNumberValidationPasscode: string
  --settings: record
  --allowCarrierScheduling: oneof<nothing, bool>
  --ccEmails: list
  --amenities: list # e.g. [Lumper services, Drivers restroom, Overnight parking, Free Wi-Fi]
  --ppeRequirements: list # e.g. [Face Mask, Safety Glasses, Hard Hat, Safety Boots, Gloves, High Visibility Vest, Long Pants, Long Sleeves, No Smoking, Hair and Beard Net]
  --intervalTrimForCarriers: float
  --customBookingUrl: string
  --street: string
  --city: string
  --state: string
  --zip: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: table<semanticLabelId: record, type: string>, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list<string>, amenities: list<string>, ppeRequirements: list<string>, intervalTrimForCarriers: float, customBookingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse/($id)")
  let body = {tags: $tags, name: $name, facilityNumber: $facilityNumber, country: $country, timezone: $timezone, schedule: $schedule, contactName: $contactName, phone: $phone, email: $email, notes: $notes, instructions: $instructions, customApptFieldsTemplate: $customApptFieldsTemplate, refNumberValidationVersion: $refNumberValidationVersion, refNumberValidationUrl: $refNumberValidationUrl, refNumberValidationPasscode: $refNumberValidationPasscode, settings: $settings, allowCarrierScheduling: $allowCarrierScheduling, ccEmails: $ccEmails, amenities: $amenities, ppeRequirements: $ppeRequirements, intervalTrimForCarriers: $intervalTrimForCarriers, customBookingUrl: $customBookingUrl, street: $street, city: $city, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single Warehouse
#
# DELETE /warehouse/{id}
# operationId: deleteOneBaseWarehouseControllerWarehouse
export def "warehouse delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: table<semanticLabelId: record, type: string>, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list<string>, amenities: list<string>, ppeRequirements: list<string>, intervalTrimForCarriers: float, customBookingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve multiple Warehouses
#
# GET /warehouse
# operationId: getManyBaseWarehouseControllerWarehouse
export def "warehouse list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: list, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list, amenities: list, ppeRequirements: list, intervalTrimForCarriers: float, customBookingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/warehouse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Warehouse
#
# POST /warehouse
# operationId: createOneBaseWarehouseControllerWarehouse
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
# --customApptFieldsTemplate item shape: {semanticLabelId?: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action"}
export def "warehouse createOneBaseWarehouseControllerWarehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  --facilityNumber: string
  --country: string
  --timezone: string
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
  --contactName: record
  --phone: string
  --email: record
  --notes: record
  --instructions: record
  --customApptFieldsTemplate: list # item shape: {semanticLabelId?: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action"}
  --refNumberValidationVersion: string@refNumberValidationVersion-completer
  --refNumberValidationUrl: string
  --refNumberValidationPasscode: string
  --settings: record
  --allowCarrierScheduling: oneof<nothing, bool>
  --ccEmails: list
  --amenities: list # e.g. [Lumper services, Drivers restroom, Overnight parking, Free Wi-Fi]
  --ppeRequirements: list # e.g. [Face Mask, Safety Glasses, Hard Hat, Safety Boots, Gloves, High Visibility Vest, Long Pants, Long Sleeves, No Smoking, Hair and Beard Net]
  --intervalTrimForCarriers: float
  --customBookingUrl: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: table<semanticLabelId: record, type: string>, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list<string>, amenities: list<string>, ppeRequirements: list<string>, intervalTrimForCarriers: float, customBookingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/warehouse")
  let body = {tags: $tags, name: $name, facilityNumber: $facilityNumber, country: $country, timezone: $timezone, schedule: $schedule, contactName: $contactName, phone: $phone, email: $email, notes: $notes, instructions: $instructions, customApptFieldsTemplate: $customApptFieldsTemplate, refNumberValidationVersion: $refNumberValidationVersion, refNumberValidationUrl: $refNumberValidationUrl, refNumberValidationPasscode: $refNumberValidationPasscode, settings: $settings, allowCarrierScheduling: $allowCarrierScheduling, ccEmails: $ccEmails, amenities: $amenities, ppeRequirements: $ppeRequirements, intervalTrimForCarriers: $intervalTrimForCarriers, customBookingUrl: $customBookingUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update custom forms for load types
#
# PATCH /warehouse/{id}/custom-forms
# operationId: WarehouseController_updateLoadTypesCustomForms
export def "warehouse-custom-forms updateLoadTypesCustomForms" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --loadTypeIds: list # The list of load type ids that this form will be used for (e.g. [a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5])
  --formName: string # The name of the form (e.g. Load Type Form)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse/($id)/custom-forms")
  let body = {loadTypeIds: $loadTypeIds, formName: $formName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create custom forms for load types
#
# POST /warehouse/{id}/custom-forms
# operationId: WarehouseController_createLoadTypesCustomForms
export def "warehouse-custom-forms createLoadTypesCustomForms" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  loadTypeIds: list # The list of load type ids that this form will be used for (e.g. [a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5])
  formName: string # The name of the form (e.g. Load Type Form)
  --formDescription: string # Extra description of the form (e.g. This form is used to collect information about the load type)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse/($id)/custom-forms")
  let body = {loadTypeIds: $loadTypeIds, formName: $formName, formDescription: $formDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get open hours for set of docks in the warehouse
#
# POST /warehouse/{id}/get-hours-of-operation
# operationId: WarehouseController_getHOOPs
export def "warehouse-get-hours-of-operation post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  start: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
  end: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
]: any -> table<openIntervals: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse/($id)/get-hours-of-operation")
  let body = {start: $start, end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /user/invite
#
# operationId: UserController_invite
export def "user-invite invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/invite")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single User
#
# GET /user/{id}
# operationId: getOneBaseUserControllerUser
export def "user get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single User
#
# DELETE /user/{id}
# operationId: deleteOneBaseUserControllerUser
export def "user delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single User
#
# PATCH /user/{id}
# operationId: updateOneBaseUserControllerUser
# --orgCarrierSettings item shape: {org?: record, orgId?: string, user?: record, userId?: string, favoriteWarehouseIds?: list}
export def "user updateOneBaseUserControllerUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --email: string
  --firstName: string
  --lastName: string
  --phone: string
  --role: string@role-completer
  --orgCarrierSettings: list # item shape: {org?: record, orgId?: string, user?: record, userId?: string, favoriteWarehouseIds?: list}
  --orgId: string
  --warehouseAccessList: any
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let body = {tags: $tags, email: $email, firstName: $firstName, lastName: $lastName, phone: $phone, role: $role, orgCarrierSettings: $orgCarrierSettings, orgId: $orgId, warehouseAccessList: $warehouseAccessList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Users
#
# GET /user
# operationId: getManyBaseUserControllerUser
export def "user list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: list, company: any, orgCarrierSettings: list, org: any, warehouseAccessList: any, tcConfirmedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /user/email-available/{email}
#
# operationId: UserController_isEmailAvailable
export def "user-email-available isEmailAvailable" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/email-available/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /user/change-password
#
# operationId: UserController_changePassword
export def "user-change-password changePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/change-password")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /user/accept-tc
#
# operationId: UserController_acceptTC
export def "user-accept-tc acceptTC" [
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
  let full_url = (build-url $base "/user/accept-tc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve multiple Users
#
# GET /carrier
# operationId: getManyBaseCarrierControllerUser
export def "carrier list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --onlyIncludeFavorites: oneof<nothing, bool> # Filters returned carriers to only include "Favorite" carriers.
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: list, company: any, orgCarrierSettings: list, org: any, warehouseAccessList: any, tcConfirmedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyIncludeFavorites" $onlyIncludeFavorites "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/carrier" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single User
#
# POST /carrier
# operationId: createOneBaseCarrierControllerUser
export def "carrier createOneBaseCarrierControllerUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone: string
  --orgCarrierSettings: record
  --tags: record
]: any -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: list, company: any, orgCarrierSettings: list, org: any, warehouseAccessList: any, tcConfirmedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier")
  let body = {phone: $phone, orgCarrierSettings: $orgCarrierSettings, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /carrier/booked
#
# operationId: CarrierController_getManyBooked
export def "carrier-booked get" [
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
  let full_url = (build-url $base "/carrier/booked")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /carrier/{id}/org-carrier-settings
#
# DEPRECATED
# operationId: CarrierController_getOrgCarrierSettingsOrg
@deprecated
export def "carrier-org-carrier-settings get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/carrier/($id)/org-carrier-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /carrier/{id}/org-carrier-settings
#
# DEPRECATED
# operationId: CarrierController_updateOrgCarrierSettings
@deprecated
export def "carrier-org-carrier-settings updateOrgCarrierSettings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/carrier/($id)/org-carrier-settings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /carrier/org-carrier-settings/{id}
#
# DEPRECATED
# operationId: CarrierController_getOrgCarrierSettingsCarrier
@deprecated
export def "carrier-org-carrier-settings get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/carrier/org-carrier-settings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /carrier/preview
#
# operationId: CarrierController_getCarrierPreviewToken
export def "carrier-preview post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier/preview")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /carrier/settings
#
# operationId: CarrierController_getCarrierSettings
export def "carrier-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /carrier/settings/favorite-warehouses
#
# operationId: CarrierController_getFavoriteWarehouses
export def "carrier-settings-favorite-warehouses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier/settings/favorite-warehouses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /carrier/settings/favorite-warehouses
#
# operationId: CarrierController_addFavoriteWarehouse
export def "carrier-settings-favorite-warehouses addFavoriteWarehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier/settings/favorite-warehouses")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /carrier/settings/favorite-warehouses
#
# operationId: CarrierController_removeFavoriteWarehouse
export def "carrier-settings-favorite-warehouses removeFavoriteWarehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier/settings/favorite-warehouses")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single User
#
# GET /carrier/{id}
# operationId: getOneBaseCarrierControllerUser
export def "carrier get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, role: string, appointments: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, status: string, user: any, userId: record, loadType: any, loadTypeId: string, dock: any, org: any, orgId: string, end: string, eta: string, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: string, recurringParent: any, recurringChildren: any, recurringPattern: record, reschedules: list, muteNotifications: bool, isCheckedInByCarrier: bool>, company: any, orgCarrierSettings: list<any>, org: any, warehouseAccessList: any, tcConfirmedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/carrier/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Org
#
# GET /org/{id}
# operationId: getOneBaseOrgControllerOrg
export def "org get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, warehouses: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: list, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list, amenities: list, ppeRequirements: list, intervalTrimForCarriers: float, customBookingUrl: string>, reportSearches: record, customTags: list<string>, samlConfig: record, orgType: string, expiresAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/org/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Org
#
# PATCH /org/{id}
# operationId: updateOneBaseOrgControllerOrg
export def "org updateOneBaseOrgControllerOrg" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --name: string
  --settings: record
  --favoriteCarrierIds: list
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, warehouses: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, country: string, timezone: string, docks: any, loadTypes: any, org: any, orgId: string, contactName: string, phone: string, email: string, notes: string, instructions: string, customApptFieldsTemplate: list, refNumberValidationVersion: string, refNumberValidationUrl: string, refNumberValidationPasscode: string, settings: record, allowCarrierScheduling: bool, geolocation: record, ccEmails: list, amenities: list, ppeRequirements: list, intervalTrimForCarriers: float, customBookingUrl: string>, reportSearches: record, customTags: list<string>, samlConfig: record, orgType: string, expiresAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/($id)")
  let body = {tags: $tags, name: $name, settings: $settings, favoriteCarrierIds: $favoriteCarrierIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /org/{orgId}/report-search
#
# operationId: OrgController_createReportSearch
export def "org-report-search createReportSearch" [
  orgId: any
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
  let full_url = (build-url $base $"/org/($orgId)/report-search")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /org/{orgId}/report-search
#
# operationId: OrgController_getAllReportSearches
export def "org-report-search get" [
  orgId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/($orgId)/report-search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /org/{orgId}/report-search/{reportSearchKey}
#
# operationId: OrgController_updateReportSearch
export def "org-report-search updateReportSearch" [
  reportSearchKey: string
  orgId: any
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
  let full_url = (build-url $base $"/org/($orgId)/report-search/($reportSearchKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /org/{orgId}/report-search/{reportSearchKey}
#
# operationId: OrgController_deleteReportSearch
export def "org-report-search delete" [
  reportSearchKey: string
  orgId: any
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
  let full_url = (build-url $base $"/org/($orgId)/report-search/($reportSearchKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /org/{orgId}/favorite-carriers
#
# operationId: OrgController_updateFavoriteCarriers
export def "org-favorite-carriers updateFavoriteCarriers" [
  orgId: string
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
  let full_url = (build-url $base $"/org/($orgId)/favorite-carriers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /org/{id}/custom-tags
#
# operationId: OrgController_updateCustomTags
export def "org-custom-tags updateCustomTags" [
  id: string
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
  let full_url = (build-url $base $"/org/($id)/custom-tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Companies
#
# GET /company
# operationId: getManyBaseCompanyControllerCompany
export def "company list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/company" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Company
#
# POST /company
# operationId: createOneBaseCompanyControllerCompany
export def "company createOneBaseCompanyControllerCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --scac: string
  --mc: string
  --usdot: string
  --type: string@type-completer
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/company")
  let body = {tags: $tags, scac: $scac, mc: $mc, usdot: $usdot, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single Company
#
# GET /company/{id}
# operationId: getOneBaseCompanyControllerCompany
export def "company get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/company/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /auth/login
#
# operationId: AuthController_login
export def "auth-login login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email address (e.g. user@example.com)
  password: string # User password (e.g. P@ssw0rd!)
]: any -> record<access_token: string, expires_in: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /auth/refresh
#
# operationId: AuthController_refresh
export def "auth-refresh refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_token: string, expires_in: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /auth/profile
#
# operationId: AuthController_getProfile
export def "auth-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, email: string, firstName: string, lastName: string, phone: record, extension: record, isEmailVerified: bool, role: string, companyId: record, orgId: record, warehouseAccessList: list<string>, invalidLoginAttempts: record, tcConfirmedAt: record, lastLoginAt: record, passwordResetRequired: bool, passwordResetEmailSentAt: record, orgIsActive: bool, orgName: string, orgCreateDateTime: string, orgType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /auth/me
#
# operationId: AuthController_getProfile
export def "auth-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, email: string, firstName: string, lastName: string, phone: record, extension: record, isEmailVerified: bool, role: string, companyId: record, orgId: record, warehouseAccessList: list<string>, invalidLoginAttempts: record, tcConfirmedAt: record, lastLoginAt: record, passwordResetRequired: bool, passwordResetEmailSentAt: record, orgIsActive: bool, orgName: string, orgCreateDateTime: string, orgType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Dock
#
# POST /dock
# operationId: createOneBaseDockControllerDock
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
export def "dock createOneBaseDockControllerDock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --doorNumber: string
  --instructions: string
  --minCarrierLeadTime-hr: float
  --minCarrierLeadTimeForUpdates-hr: float
  --maxCarrierLeadTime-hr: float
  --ccEmails: list
  --allowCarrierScheduling: oneof<nothing, bool>
  --allowOverBooking: oneof<nothing, bool>
  --sortOrder: float
  --settings: record
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, org: record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, warehouses: list<record>, reportSearches: record, customTags: list<string>, samlConfig: record, orgType: string, expiresAt: string>, orgId: string, loadTypeIds: list<string>, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list<string>, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dock")
  let body = {tags: $tags, doorNumber: $doorNumber, instructions: $instructions, minCarrierLeadTime_hr: $minCarrierLeadTime_hr, minCarrierLeadTimeForUpdates_hr: $minCarrierLeadTimeForUpdates_hr, maxCarrierLeadTime_hr: $maxCarrierLeadTime_hr, ccEmails: $ccEmails, allowCarrierScheduling: $allowCarrierScheduling, allowOverBooking: $allowOverBooking, sortOrder: $sortOrder, settings: $settings, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Docks
#
# GET /dock
# operationId: getManyBaseDockControllerDock
export def "dock list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, org: record, orgId: string, loadTypeIds: list, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Dock
#
# PATCH /dock/{id}
# operationId: updateOneBaseDockControllerDock
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
export def "dock updateOneBaseDockControllerDock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --doorNumber: string
  --instructions: string
  --minCarrierLeadTime-hr: float
  --minCarrierLeadTimeForUpdates-hr: float
  --maxCarrierLeadTime-hr: float
  --ccEmails: list
  --allowCarrierScheduling: oneof<nothing, bool>
  --allowOverBooking: oneof<nothing, bool>
  --sortOrder: float
  --settings: record
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
  --name: string
  --warehouseId: string
  --loadTypeIds: list
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, org: record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, warehouses: list<record>, reportSearches: record, customTags: list<string>, samlConfig: record, orgType: string, expiresAt: string>, orgId: string, loadTypeIds: list<string>, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list<string>, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)")
  let body = {tags: $tags, doorNumber: $doorNumber, instructions: $instructions, minCarrierLeadTime_hr: $minCarrierLeadTime_hr, minCarrierLeadTimeForUpdates_hr: $minCarrierLeadTimeForUpdates_hr, maxCarrierLeadTime_hr: $maxCarrierLeadTime_hr, ccEmails: $ccEmails, allowCarrierScheduling: $allowCarrierScheduling, allowOverBooking: $allowOverBooking, sortOrder: $sortOrder, settings: $settings, schedule: $schedule, name: $name, warehouseId: $warehouseId, loadTypeIds: $loadTypeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single Dock
#
# DELETE /dock/{id}
# operationId: deleteOneBaseDockControllerDock
export def "dock delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hardDelete: oneof<nothing, bool>
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>, org: record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, warehouses: list<record>, reportSearches: record, customTags: list<string>, samlConfig: record, orgType: string, expiresAt: string>, orgId: string, loadTypeIds: list<string>, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list<string>, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)")
  let body = {hardDelete: $hardDelete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single Dock
#
# GET /dock/{id}
# operationId: getOneBaseDockControllerDock
export def "dock get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, org: record, orgId: string, loadTypeIds: list, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dock/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save the sort order of an array of docks
#
# POST /dock/sort
# operationId: DockController_updateSort
export def "dock-sort updateSort" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: string, entity: string, data: table<generatedMaps: list, raw: list, affected: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dock/sort")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /dock/{id}/compute-availability
#
# operationId: DockController_availability
export def "dock-compute-availability availability" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  start: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
  end: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)/compute-availability")
  let body = {start: $start, end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /dock/{id}/get-availability
#
# operationId: DockController_availability
export def "dock-get-availability availability" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  start: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
  end: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)/get-availability")
  let body = {start: $start, end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /dock/compute-open-dates
#
# operationId: DockController_openDates
export def "dock-compute-open-dates openDates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  start: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
  end: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
]: any -> record<openDates: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dock/compute-open-dates")
  let body = {start: $start, end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a child "Capacity Dock" linked to this Dock
#
# POST /dock/{id}/capacity
# operationId: DockController_createCapacityChildDock
export def "dock-capacity createCapacityChildDock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, org: record, orgId: string, loadTypeIds: list, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)/capacity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlinks a child "Capacity Dock" from its parent Dock
#
# DELETE /dock/{id}/capacity/{childId}
# operationId: DockController_unlinkCapacityDock
export def "dock-capacity unlinkCapacityDock" [
  id: string
  childId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, schedule: record, org: record, orgId: string, loadTypeIds: list, instructions: string, minCarrierLeadTime_hr: float, minCarrierLeadTimeForUpdates_hr: float, maxCarrierLeadTime_hr: float, ccEmails: list, allowCarrierScheduling: bool, allowOverBooking: bool, capacityParent: any, capacityChildren: any, capacityParentId: string, sortOrder: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dock/($id)/capacity/($childId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single LoadType
#
# POST /loadtype
# operationId: createOneBaseLoadTypeControllerLoadType
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
export def "loadtype createOneBaseLoadTypeControllerLoadType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --orgId: string
  --warehouseId: string
  direction: string@direction-completer
  --operation: string@operation-completer
  --equipmentType: string@equipmentType-completer
  --transportationMode: string@transportationMode-completer
  --allowCarrierScheduling: oneof<nothing, bool>
  --description: record
  --settings: record
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, org: any, orgId: string, direction: string, operation: string, equipmentType: string, transportationMode: string, allowCarrierScheduling: bool, description: string, settings: record, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/loadtype")
  let body = {tags: $tags, orgId: $orgId, warehouseId: $warehouseId, direction: $direction, operation: $operation, equipmentType: $equipmentType, transportationMode: $transportationMode, allowCarrierScheduling: $allowCarrierScheduling, description: $description, settings: $settings, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple LoadTypes
#
# GET /loadtype
# operationId: getManyBaseLoadTypeControllerLoadType
export def "loadtype list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseId: string # When set, returns Loadtypes that can be used at this Warehouse.
  --includeOrgLoadTypes: string
  --showOnlyAssignedLoadTypes: string
  --includeHierarchySettings: string
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, org: any, orgId: string, direction: string, operation: string, equipmentType: string, transportationMode: string, allowCarrierScheduling: bool, description: string, settings: record, schedule: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouseId" $warehouseId "scalar") (serialize-qp "includeOrgLoadTypes" $includeOrgLoadTypes "scalar") (serialize-qp "showOnlyAssignedLoadTypes" $showOnlyAssignedLoadTypes "scalar") (serialize-qp "includeHierarchySettings" $includeHierarchySettings "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/loadtype" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single LoadType
#
# DELETE /loadtype/{id}
# operationId: deleteOneBaseLoadTypeControllerLoadType
export def "loadtype delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, org: any, orgId: string, direction: string, operation: string, equipmentType: string, transportationMode: string, allowCarrierScheduling: bool, description: string, settings: record, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loadtype/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single LoadType
#
# GET /loadtype/{id}
# operationId: getOneBaseLoadTypeControllerLoadType
export def "loadtype get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, org: any, orgId: string, direction: string, operation: string, equipmentType: string, transportationMode: string, allowCarrierScheduling: bool, description: string, settings: record, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loadtype/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single LoadType
#
# PATCH /loadtype/{id}
# operationId: updateOneBaseLoadTypeControllerLoadType
# --schedule shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
export def "loadtype updateOneBaseLoadTypeControllerLoadType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --orgId: string
  --warehouseId: string
  --direction: string@direction-completer
  --operation: string@operation-completer
  --equipmentType: string@equipmentType-completer
  --transportationMode: string@transportationMode-completer
  --allowCarrierScheduling: oneof<nothing, bool>
  --description: record
  --settings: record
  --schedule: record # shape: {sunday: list, monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, version: float, closedIntervals: list}
  --name: string
  --duration-min: float
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, org: any, orgId: string, direction: string, operation: string, equipmentType: string, transportationMode: string, allowCarrierScheduling: bool, description: string, settings: record, schedule: record<sunday: list<record>, monday: list<record>, tuesday: list<record>, wednesday: list<record>, thursday: list<record>, friday: list<record>, saturday: list<record>, version: float, closedIntervals: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loadtype/($id)")
  let body = {tags: $tags, orgId: $orgId, warehouseId: $warehouseId, direction: $direction, operation: $operation, equipmentType: $equipmentType, transportationMode: $transportationMode, allowCarrierScheduling: $allowCarrierScheduling, description: $description, settings: $settings, schedule: $schedule, name: $name, duration_min: $duration_min} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /loadtype/{id}/get-availability
#
# operationId: LoadTypeController_availability
export def "loadtype-get-availability availability" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceAsCarrier: oneof<nothing, bool> # When passing this argument as true, the availability will consider the availability for a carrier user, default = false (e.g. true)
  start: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
  end: string # format: date-time, e.g. 2026-05-24T19:16:46.221Z
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceAsCarrier" $forceAsCarrier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loadtype/($id)/get-availability" $qp)
  let body = {start: $start, end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the appointment count grouped by warehouse
#
# GET /loadtype/{id}/appointment-count
# operationId: LoadTypeController_getAppointmentCount
export def "loadtype-appointment-count get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loadtype/($id)/appointment-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new load type group
#
# POST /loadtype-group
# operationId: LoadTypeGroupController_createLoadTypeGroup
export def "loadtype-group createLoadTypeGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/loadtype-group")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve load type groups
#
# GET /loadtype-group
# operationId: LoadTypeGroupController_getLoadTypeGroups
export def "loadtype-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/loadtype-group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing load type group
#
# PATCH /loadtype-group/{id}
# operationId: LoadTypeGroupController_updateLoadTypeGroup
export def "loadtype-group updateLoadTypeGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loadtype-group/($id)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a load type group
#
# DELETE /loadtype-group/{id}
# operationId: LoadTypeGroupController_deleteLoadTypeGroup
export def "loadtype-group delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loadtype-group/($id)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update unit limit configuration
#
# POST /unit-limit/configuration
# operationId: UnitLimitController_setUpConfiguration
export def "unit-limit-configuration setUpConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unit-limit/configuration")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve unit limit configurations
#
# GET /unit-limit/configuration
# operationId: UnitLimitController_getConfiguration
export def "unit-limit-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unit-limit/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get unit limit counts for specific configurations
#
# GET /unit-limit/count
# operationId: UnitLimitController_getCount
export def "unit-limit-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unit-limit/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate if scheduling at a given time would breach unit limits
#
# POST /unit-limit/validate
# operationId: UnitLimitController_validateUnitLimit
export def "unit-limit-validate validateUnitLimit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  warehouseId: string # The warehouse of the unit limit configuration (e.g. 550e8400-e29b-41d4-a716-446655440000)
  dockId: string # The dock of the unit limit configuration (e.g. 550e8400-e29b-41d4-a716-446655440001)
  loadTypeId: string # The load type of the unit limit configuration (e.g. 550e8400-e29b-41d4-a716-446655440002)
  start: string # Start date of the unit limit validation period (e.g. 2025-11-01)
  end: string # End date of the unit limit validation period (must be within 5 days of start date) (e.g. 2025-11-04)
  --requestedUnits: float # Number of units requested within the specified date range (e.g. 10)
]: any -> table<valid: bool, message: string, date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unit-limit/validate")
  let body = {tags: $tags, warehouseId: $warehouseId, dockId: $dockId, loadTypeId: $loadTypeId, start: $start, end: $end, requestedUnits: $requestedUnits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single Flow
#
# POST /custom-forms/flow
# operationId: createOneBaseFlowControllerFlow
export def "custom-forms-flow createOneBaseFlowControllerFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  description: string
  formFromId: string
  warehouseId: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, parentCode: string, entityTags: list<string>, tagFromFormFieldId: string, formFromId: string, formToId: string, conditionOperator: string, conditionValue: string, conditionFormFieldId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/flow")
  let body = {tags: $tags, name: $name, description: $description, formFromId: $formFromId, warehouseId: $warehouseId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Flows
#
# GET /custom-forms/flow
# operationId: getManyBaseFlowControllerFlow
export def "custom-forms-flow list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, parentCode: string, entityTags: list, tagFromFormFieldId: string, formFromId: string, formToId: string, conditionOperator: string, conditionValue: string, conditionFormFieldId: string>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/flow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Flow
#
# PATCH /custom-forms/flow/{id}
# operationId: updateOneBaseFlowControllerFlow
export def "custom-forms-flow updateOneBaseFlowControllerFlow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --name: string
  --description: string
  --formFromId: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, parentCode: string, entityTags: list<string>, tagFromFormFieldId: string, formFromId: string, formToId: string, conditionOperator: string, conditionValue: string, conditionFormFieldId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/flow/($id)")
  let body = {tags: $tags, name: $name, description: $description, formFromId: $formFromId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single Flow
#
# GET /custom-forms/flow/{id}
# operationId: getOneBaseFlowControllerFlow
export def "custom-forms-flow get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, parentCode: string, entityTags: list<string>, tagFromFormFieldId: string, formFromId: string, formToId: string, conditionOperator: string, conditionValue: string, conditionFormFieldId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/flow/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single Flow
#
# DELETE /custom-forms/flow/{id}
# operationId: deleteOneBaseFlowControllerFlow
export def "custom-forms-flow delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, parentCode: string, entityTags: list<string>, tagFromFormFieldId: string, formFromId: string, formToId: string, conditionOperator: string, conditionValue: string, conditionFormFieldId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/flow/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Form
#
# POST /custom-forms/form
# operationId: createOneBaseFormControllerForm
export def "custom-forms-form createOneBaseFormControllerForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  description: string
  warehouseId: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/form")
  let body = {tags: $tags, name: $name, description: $description, warehouseId: $warehouseId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Forms
#
# GET /custom-forms/form
# operationId: getManyBaseFormControllerForm
export def "custom-forms-form list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string, description: string>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/form" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Form
#
# PATCH /custom-forms/form/{id}
# operationId: updateOneBaseFormControllerForm
export def "custom-forms-form updateOneBaseFormControllerForm" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --name: string
  --description: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form/($id)")
  let body = {tags: $tags, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single Form
#
# GET /custom-forms/form/{id}
# operationId: getOneBaseFormControllerForm
export def "custom-forms-form get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/form/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single Form
#
# DELETE /custom-forms/form/{id}
# operationId: deleteOneBaseFormControllerForm
export def "custom-forms-form delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /custom-forms/form/sort/{id}
#
# operationId: FormController_sortFormFields
export def "custom-forms-form-sort sortFormFields" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form/sort/($id)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single Field
#
# POST /custom-forms/field
# operationId: createOneBaseFieldControllerField
export def "custom-forms-field createOneBaseFieldControllerField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  label: string
  type: string@type-completer-1 # The type of the field used at the moment of the data submission, used to render the field in the UI and validate the data on the API level
  description: string
  placeholder: string
  --extraFields: any # e.g. {dropDownValues: [Option 1, Option 2, Option 3], minLengthOrValue: 1, maxLengthOrValue: 10}
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, label: string, description: string, placeholder: string, type: string, extraFields: record, semanticLabel: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/field")
  let body = {tags: $tags, label: $label, type: $type, description: $description, placeholder: $placeholder, extraFields: $extraFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Fields
#
# GET /custom-forms/field
# operationId: getManyBaseFieldControllerField
export def "custom-forms-field list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, label: string, description: string, placeholder: string, type: string, extraFields: record, semanticLabel: record>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/field" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single Field
#
# PATCH /custom-forms/field/{id}
# operationId: updateOneBaseFieldControllerField
export def "custom-forms-field updateOneBaseFieldControllerField" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --label: string
  --type: string@type-completer-1 # The type of the field used at the moment of the data submission, used to render the field in the UI and validate the data on the API level
  --description: string
  --placeholder: string
  --extraFields: any # e.g. {dropdownOptions: [Option 1, Option 2], maxLengthOrValue: 100, minLengthOrValue: 1}
  --formId: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, label: string, description: string, placeholder: string, type: string, extraFields: record, semanticLabel: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/field/($id)")
  let body = {tags: $tags, label: $label, type: $type, description: $description, placeholder: $placeholder, extraFields: $extraFields, formId: $formId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single Field
#
# GET /custom-forms/field/{id}
# operationId: getOneBaseFieldControllerField
export def "custom-forms-field get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, label: string, description: string, placeholder: string, type: string, extraFields: record, semanticLabel: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/field/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single Field
#
# DELETE /custom-forms/field/{id}
# operationId: deleteOneBaseFieldControllerField
export def "custom-forms-field delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, label: string, description: string, placeholder: string, type: string, extraFields: record, semanticLabel: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/field/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single FormField
#
# POST /custom-forms/form-field
# operationId: createOneBaseFormFieldControllerFormField
export def "custom-forms-form-field createOneBaseFormFieldControllerFormField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  order: float # The order of the field in the form (e.g. 1)
  formId: string
  fieldId: string
  --required: oneof<nothing, bool>
  --overrideLabel: string # The label of the field for this form instance, overrides the field label (e.g. Last Name)
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, order: float, required: bool, overrideLabel: string, formId: string, fieldId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/form-field")
  let body = {tags: $tags, order: $order, formId: $formId, fieldId: $fieldId, required: $required, overrideLabel: $overrideLabel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple FormFields
#
# GET /custom-forms/form-field
# operationId: getManyBaseFormFieldControllerFormField
export def "custom-forms-form-field list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, order: float, required: bool, overrideLabel: string, formId: string, fieldId: string>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/form-field" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single FormField
#
# PATCH /custom-forms/form-field/{id}
# operationId: updateOneBaseFormFieldControllerFormField
export def "custom-forms-form-field updateOneBaseFormFieldControllerFormField" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --order: int
  --fieldId: string
  --overrideLabel: string
  --required: oneof<nothing, bool>
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, order: float, required: bool, overrideLabel: string, formId: string, fieldId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form-field/($id)")
  let body = {tags: $tags, order: $order, fieldId: $fieldId, overrideLabel: $overrideLabel, required: $required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single FormField
#
# GET /custom-forms/form-field/{id}
# operationId: getOneBaseFormFieldControllerFormField
export def "custom-forms-form-field get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, order: float, required: bool, overrideLabel: string, formId: string, fieldId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/form-field/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single FormField
#
# DELETE /custom-forms/form-field/{id}
# operationId: deleteOneBaseFormFieldControllerFormField
export def "custom-forms-form-field delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, order: float, required: bool, overrideLabel: string, formId: string, fieldId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form-field/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve multiple Triggers
#
# GET /custom-forms/trigger
# operationId: getManyBaseTriggerControllerTrigger
export def "custom-forms-trigger list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, app: string, category: string, feature: string, flowId: record, objectId: string, entityName: string, dataEntityName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/trigger" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Trigger
#
# POST /custom-forms/trigger
# operationId: createOneBaseTriggerControllerTrigger
export def "custom-forms-trigger createOneBaseTriggerControllerTrigger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  app: string@app-completer # The app that this trigger will be activated, based on the source of the request
  category: string@category-completer # The event category that this trigger will be activated on
  --flowId: record # The ID of the Flow that will be loaded when this trigger is executed (e.g. a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5)
  objectId: string # The ID of the object that this trigger belongs to, the type is dependent on the entityName (e.g. a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5)
  --feature: string@feature-completer # The feature that this trigger is related, used to group triggers by feature
  entityName: string@entityName-completer # The entity name that qualifies the objectId this trigger will be activated
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, app: string, category: string, feature: string, flowId: record, objectId: string, entityName: string, dataEntityName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/trigger")
  let body = {tags: $tags, app: $app, category: $category, flowId: $flowId, objectId: $objectId, feature: $feature, entityName: $entityName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a single Trigger
#
# PATCH /custom-forms/trigger/{id}
# operationId: updateOneBaseTriggerControllerTrigger
export def "custom-forms-trigger updateOneBaseTriggerControllerTrigger" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --app: string@app-completer # The app that this trigger will be activated, based on the source of the request
  --category: string@category-completer # The event category that this trigger will be activated on
  --flowId: record
  --objectId: string
  --entityName: string@entityName-completer # The entity name that qualifies the objectId this trigger will be activated
  --updateRelatedTriggers: oneof<nothing, bool> # If true, it will update the related triggers of the flow, with the same flow.parentCode (default: false)
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, app: string, category: string, feature: string, flowId: record, objectId: string, entityName: string, dataEntityName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/trigger/($id)")
  let body = {tags: $tags, app: $app, category: $category, flowId: $flowId, objectId: $objectId, entityName: $entityName, updateRelatedTriggers: $updateRelatedTriggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single Trigger
#
# DELETE /custom-forms/trigger/{id}
# operationId: deleteOneBaseTriggerControllerTrigger
export def "custom-forms-trigger delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, app: string, category: string, feature: string, flowId: record, objectId: string, entityName: string, dataEntityName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/trigger/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Trigger
#
# GET /custom-forms/trigger/{id}
# operationId: getOneBaseTriggerControllerTrigger
export def "custom-forms-trigger get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, app: string, category: string, feature: string, flowId: record, objectId: string, entityName: string, dataEntityName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/trigger/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single CustomFormData
#
# GET /custom-forms/form-data/{id}
# operationId: getOneBaseCustomFormDataControllerCustomFormData
export def "custom-forms-form-data get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-forms/form-data/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single CustomFormData
#
# PATCH /custom-forms/form-data/{id}
# operationId: updateOneBaseCustomFormDataControllerCustomFormData
export def "custom-forms-form-data updateOneBaseCustomFormDataControllerCustomFormData" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  value: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form-data/($id)")
  let body = {tags: $tags, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single CustomFormData
#
# DELETE /custom-forms/form-data/{id}
# operationId: deleteOneBaseCustomFormDataControllerCustomFormData
export def "custom-forms-form-data delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-forms/form-data/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve multiple CustomFormData
#
# GET /custom-forms/form-data
# operationId: getManyBaseCustomFormDataControllerCustomFormData
export def "custom-forms-form-data list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-forms/form-data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single CustomFormData
#
# POST /custom-forms/form-data
# operationId: createOneBaseCustomFormDataControllerCustomFormData
export def "custom-forms-form-data createOneBaseCustomFormDataControllerCustomFormData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  objectId: string # The ID of the object that this data belongs to, the type is dependent on the entityName (e.g. a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5)
  entityName: string@entityName-completer-1 # The entity name of the object that this data belongs to
  value: record # The value of the field, stored as string, but it gets validated as the field type by the API (e.g. John Doe)
  formFieldId: string # The ID of the form field that this data refers to (e.g. a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5)
  triggerId: string # The ID of the trigger that this data refers to (e.g. a0e1f2c3-d4e5-6f7g-8h9i-j0k1l2m3n4o5)
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/form-data")
  let body = {tags: $tags, objectId: $objectId, entityName: $entityName, value: $value, formFieldId: $formFieldId, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple CustomFormData
#
# POST /custom-forms/form-data/bulk
# operationId: createManyBaseCustomFormDataControllerCustomFormData
# --bulk item shape: {objectId: string, entityName: "appointment"|"assetvisit"|"assetcontainer", label: string, value: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action", formFieldId: record, triggerId: record, warehouseId: record}
export def "custom-forms-form-data-bulk createManyBaseCustomFormDataControllerCustomFormData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bulk: list # item shape: {objectId: string, entityName: "appointment"|"assetvisit"|"assetcontainer", label: string, value: record, type: "str"|"bigstr"|"date"|"bool"|"doc"|"multidoc"|"int"|"email"|"phone"|"dropdown"|"dropdownmultiselect"|"combobox"|"timestamp"|"action", formFieldId: record, triggerId: record, warehouseId: record}
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, objectId: string, entityName: string, label: string, value: record, type: string, formFieldId: record, triggerId: record, warehouseId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-forms/form-data/bulk")
  let body = {bulk: $bulk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple Appointments
#
# GET /appointment
# operationId: getManyBaseAppointmentControllerAppointment
export def "appointment list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list, type: string, status: string, statusTimeline: record, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list, customFields: list, notes: record, ccEmails: list, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appointment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Appointment
#
# POST /appointment
# operationId: createOneBaseAppointmentControllerAppointment
export def "appointment createOneBaseAppointmentControllerAppointment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bypassCustomFieldsValidation: oneof<nothing, bool>
  --tags: record
  --status: string@status-completer
  --userId: record
  loadTypeId: string
  dockId: string
  start: string # format: date-time
  --end: string # format: date-time
  --refNumbers: list
  --refNumber: string
  --customFields: list
  --notes: string
  --ccEmails: list
  --muteNotifications: oneof<nothing, bool>
  --metadata: record
  --units: record
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bypassCustomFieldsValidation" $bypassCustomFieldsValidation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appointment" $qp)
  let body = {tags: $tags, status: $status, userId: $userId, loadTypeId: $loadTypeId, dockId: $dockId, start: $start, end: $end, refNumbers: $refNumbers, refNumber: $refNumber, customFields: $customFields, notes: $notes, ccEmails: $ccEmails, muteNotifications: $muteNotifications, metadata: $metadata, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /appointment/requirements
#
# operationId: AppointmentController_getAppointmentRequirements
export def "appointment-requirements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --loadTypeId: string # Identifies a LoadType.
  --warehouseId: string # Identifies a Warehouse.
  --start: string # The start date of appointment creations. (format: date-time)
  --end: string # The end date of appointment creations. (format: date-time)
]: nothing -> record<notes: string, fields: record<customFields: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, customFormsData: record<type: string, required: bool, children: list, description: string>, units: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, loadTypeId: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, dockId: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, start: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, notes: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, userId: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, refNumbers: record<type: string, required: bool, example: record, acceptedValues: record, description: string>, ccEmails: record<type: string, required: bool, example: record, acceptedValues: record, description: string>>, example: record<customFields: list<record>, customFormsData: list<record>, units: float, loadTypeId: string, dockId: string, start: record, notes: string, userId: string, refNumbers: list<list>, ccEmails: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loadTypeId" $loadTypeId "scalar") (serialize-qp "warehouseId" $warehouseId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appointment/requirements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Appointment
#
# GET /appointment/{id}
# operationId: getOneBaseAppointmentControllerAppointment
export def "appointment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/appointment/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single Appointment
#
# DELETE /appointment/{id}
# operationId: deleteOneBaseAppointmentControllerAppointment
export def "appointment delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hardDelete: oneof<nothing, bool>
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)")
  let body = {hardDelete: $hardDelete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a single Appointment
#
# PATCH /appointment/{id}
# operationId: updateOneBaseAppointmentControllerAppointment
export def "appointment updateOneBaseAppointmentControllerAppointment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --status: string@status-completer
  --userId: record
  --loadTypeId: string
  --dockId: string
  --start: string # format: date-time
  --end: string # format: date-time
  --refNumbers: list
  --refNumber: string
  --customFields: list
  --notes: string
  --ccEmails: list
  --muteNotifications: oneof<nothing, bool>
  --metadata: record
  --units: record
  --type: string@type-completer-2
  --statusTimeline: record
  --isCheckedInByCarrier: oneof<nothing, bool>
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)")
  let body = {tags: $tags, status: $status, userId: $userId, loadTypeId: $loadTypeId, dockId: $dockId, start: $start, end: $end, refNumbers: $refNumbers, refNumber: $refNumber, customFields: $customFields, notes: $notes, ccEmails: $ccEmails, muteNotifications: $muteNotifications, metadata: $metadata, units: $units, type: $type, statusTimeline: $statusTimeline, isCheckedInByCarrier: $isCheckedInByCarrier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /appointment/public/{id}
#
# operationId: AppointmentController_getPublicAppointmentDetails
export def "appointment-public get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: table<name: string, type: string, label: string, description: string, placeholder: string, dropDownValues: list, hiddenFromCarrier: bool, requiredForCarrier: bool, requiredForWarehouse: bool, value: record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/public/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /appointment/{id}/set-eta
#
# operationId: AppointmentController_setEta
export def "appointment-set-eta setEta" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  eta: string # Estimated time of arrival (format: date-time, e.g. 2026-03-19T18:30:00.000Z)
  --reason: string # Reason for the ETA update (required for carriers) (e.g. on time)
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/set-eta")
  let body = {eta: $eta, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /appointment/{id}/undo-latest-status
#
# operationId: AppointmentController_undoLatestStatus
export def "appointment-undo-latest-status undoLatestStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/undo-latest-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /appointment/reserve
#
# operationId: AppointmentController_createReserve
export def "appointment-reserve createReserve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dockId: string # format: uuid, e.g. c9fbc7d2-f9c3-483c-84b4-1215682af6a3
  start: string # format: date-time, e.g. 2026-03-23T05:00:00.000Z
  --notes: string # e.g. Reserved
  --duration-min: float # Duration in minutes (default: 30) (e.g. 30)
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/appointment/reserve")
  let body = {dockId: $dockId, start: $start, notes: $notes, duration_min: $duration_min} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a Recurring Appointment Series based on this appointment
#
# POST /appointment/{id}/recurring
# operationId: AppointmentController_createRecurringAppointments
export def "appointment-recurring createRecurringAppointments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  numWeeks: float # Number of weeks to repeat pattern (e.g. 3)
  weekDays: list # e.g. [Monday]
  --copyFields: list # Copy appointment fields to the series. Copying refNumber will not work if unique ref number setting is on (e.g. [customFields])
  --customFormsDataToCopy: list # Load-type custom form data rows from the parent appointment to copy into each child. Pass the full row objects returned by the customformdata API (formFieldId, triggerId, label, type, value). Array-valued fields (multidoc, dropdownmultiselect) are serialised correctly for each child.
  --startingStatus: string@startingStatus-completer # Starting status for recurring children. Defaults to Scheduled (default: Scheduled, e.g. Requested)
]: any -> record<data: record<successes: list<record>, failures: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/recurring")
  let body = {numWeeks: $numWeeks, weekDays: $weekDays, copyFields: $copyFields, customFormsDataToCopy: $customFormsDataToCopy, startingStatus: $startingStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes this appointment and all following appointments in the recurring series, except the original appointment used to create this series.
#
# DELETE /appointment/{id}/recurring
# operationId: AppointmentController_deleteRecurringAppointments
export def "appointment-recurring delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/recurring")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /appointment/email-notification-html/{emailKey}
#
# operationId: AppointmentController_getAppointmentNotificationEmailHtml
export def "appointment-email-notification-html get" [
  emailKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseId: string
]: nothing -> record<bodyHtml: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouseId" $warehouseId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/appointment/email-notification-html/($emailKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /appointment/{id}/tag
#
# operationId: AppointmentController_addAppointmentTag
export def "appointment-tag addAppointmentTag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string # e.g. Damaged
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/tag")
  let body = {tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /appointment/{id}/tag
#
# operationId: AppointmentController_removeAppointmentTag
export def "appointment-tag removeAppointmentTag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string # e.g. Damaged
]: any -> record<data: record<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list<string>, type: string, status: string, statusTimeline: record<NoShow: record, Arrived: record, Cancelled: record, Completed: record, Requested: record, Scheduled: record, InProgress: record>, userId: record, loadTypeId: string, dockId: string, orgId: string, start: string, end: string, eta: record, refNumber: string, refNumbers: list<string>, customFields: list<record>, notes: record, ccEmails: list<string>, recurringParentId: record, recurringPattern: record, reschedules: record, confirmationNumber: string, muteNotifications: bool, isCheckedInByCarrier: bool, metadata: record<unitLimitBreached: bool, externalValidationFailed: bool, externalValidationErrorMessage: record, unitLimitOverrideReason: record, clonedFromId: record>, units: record, searchableCustomFields: record, recurringParent: record, recurringChildren: list<record>>, entity: string, action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/appointment/($id)/tag")
  let body = {tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a single AssetVisit
#
# POST /asset-visit
# operationId: createOneBaseAssetVisitControllerAssetVisit
export def "asset-visit createOneBaseAssetVisitControllerAssetVisit" [
  assetContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  warehouseId: string # format: uuid
  --appointmentId: string # format: uuid
  --licensePlate: record
  --dotNumber: record
  --companyId: string # format: uuid
  phone: string # Driver Phone number in E.164 format
  --useWhatsApp: oneof<nothing, bool> # Whether to communicate via WhatsApp
  --isPlanned: oneof<nothing, bool>
  --companyHint: string # Company name
  --visitType: string@visitType-completer # The type of the asset visit
  --driverNotes: string # Driver notes for check-in
  --driverAppointmentIdentifier: string # Appointment identifier entered by the driver for check-in
  --hasArrived: oneof<nothing, bool>
  --assetContainerDetails: list
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-visit")
  let body = {tags: $tags, warehouseId: $warehouseId, appointmentId: $appointmentId, licensePlate: $licensePlate, dotNumber: $dotNumber, companyId: $companyId, phone: $phone, useWhatsApp: $useWhatsApp, isPlanned: $isPlanned, companyHint: $companyHint, visitType: $visitType, driverNotes: $driverNotes, driverAppointmentIdentifier: $driverAppointmentIdentifier, hasArrived: $hasArrived, assetContainerDetails: $assetContainerDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple AssetVisits
#
# GET /asset-visit
# operationId: getManyBaseAssetVisitControllerAssetVisit
export def "asset-visit list" [
  assetContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludeStatuses: list # Event types to exclude. Asset visits with any event matching these types will be filtered out.
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeStatuses" $excludeStatuses "multi") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/asset-visit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single AssetVisit
#
# PATCH /asset-visit/{id}
# operationId: updateOneBaseAssetVisitControllerAssetVisit
export def "asset-visit updateOneBaseAssetVisitControllerAssetVisit" [
  id: string
  assetContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --appointmentId: string # format: uuid
  --companyId: record # format: uuid
  --licensePlate: string
  --dotNumber: string
  --companyHint: string # Free-text carrier name when no companyId is selected
  --visitType: string@visitType-completer # The type of the asset visit
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-visit/($id)")
  let body = {tags: $tags, appointmentId: $appointmentId, companyId: $companyId, licensePlate: $licensePlate, dotNumber: $dotNumber, companyHint: $companyHint, visitType: $visitType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single AssetVisit
#
# GET /asset-visit/{id}
# operationId: getOneBaseAssetVisitControllerAssetVisit
export def "asset-visit get" [
  id: string
  assetContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/asset-visit/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single AssetVisit
#
# DELETE /asset-visit/{id}
# operationId: deleteOneBaseAssetVisitControllerAssetVisit
export def "asset-visit delete" [
  id: string
  assetContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-visit/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /asset-visit/event
#
# operationId: AssetVisitController_createAssetVisitEvent
export def "asset-visit-event createAssetVisitEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-visit/event")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /asset-visit/{id}/yard-events
#
# operationId: AssetVisitController_getAssetVisitEvents
export def "asset-visit-yard-events get" [
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
  let full_url = (build-url $base $"/asset-visit/($id)/yard-events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /asset-visit/{id}/arrival-container
#
# operationId: AssetVisitController_getArrivalAssetContainerForVisit
export def "asset-visit-arrival-container get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-visit/($id)/arrival-container")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /asset-visit/{id}/check-in-acknowledgment
#
# operationId: AssetVisitController_updateCheckInAcknowledgment
export def "asset-visit-check-in-acknowledgment updateCheckInAcknowledgment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, orgId: string, warehouseId: string, appointmentId: string, secondaryAppointmentId: string, companyId: string, phone: string, isPlanned: bool, companyHint: string, driverNotes: string, driverAppointmentIdentifier: string, visitType: string, checkInAcknowledged: bool, rejectReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-visit/($id)/check-in-acknowledgment")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /asset-visit/{id}/attach/{assetContainerId}
#
# operationId: AssetVisitController_attachContainer
export def "asset-visit-attach attachContainer" [
  id: string
  assetContainerId: string
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
  let full_url = (build-url $base $"/asset-visit/($id)/attach/($assetContainerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /asset-visit/{id}/detach/{assetContainerId}
#
# operationId: AssetVisitController_detachContainer
export def "asset-visit-detach detachContainer" [
  id: string
  assetContainerId: string
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
  let full_url = (build-url $base $"/asset-visit/($id)/detach/($assetContainerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /asset-visit/link-unplanned-checkin-to-appointment
#
# operationId: AssetVisitController_linkUnplannedCheckinToAppointment
@deprecated --flag companyId
export def "asset-visit-link-unplanned-checkin-to-appointment linkUnplannedCheckinToAppointment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  appointmentId: string
  assetVisitId: string
  --companyId: string # Deprecated: company is resolved from the appointment user on the server. Optional for legacy clients only. (DEPRECATED)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-visit/link-unplanned-checkin-to-appointment")
  let body = {tags: $tags, appointmentId: $appointmentId, assetVisitId: $assetVisitId, companyId: $companyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /asset-visit/unlink-checkin-from-appointment
#
# operationId: AssetVisitController_unlinkCheckinFromAppointment
export def "asset-visit-unlink-checkin-from-appointment unlinkCheckinFromAppointment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  appointmentId: string
  assetVisitId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-visit/unlink-checkin-from-appointment")
  let body = {tags: $tags, appointmentId: $appointmentId, assetVisitId: $assetVisitId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single AssetContainer
#
# GET /asset-container/{id}
# operationId: getOneBaseAssetContainerControllerAssetContainer
export def "asset-container get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/asset-container/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single AssetContainer
#
# PATCH /asset-container/{id}
# operationId: updateOneBaseAssetContainerControllerAssetContainer
export def "asset-container updateOneBaseAssetContainerControllerAssetContainer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --assetVisitId: string # format: uuid
  --code: string
  --notes: string
  --type: string@type-completer-3 # The type of the asset container
  --dropAppointmentId: string # format: uuid
  --pickupAppointmentId: string # format: uuid
  --state: string@state-completer # The state of the asset container
  --companyId: string # format: uuid
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-container/($id)")
  let body = {tags: $tags, assetVisitId: $assetVisitId, code: $code, notes: $notes, type: $type, dropAppointmentId: $dropAppointmentId, pickupAppointmentId: $pickupAppointmentId, state: $state, companyId: $companyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single AssetContainer
#
# DELETE /asset-container/{id}
# operationId: deleteOneBaseAssetContainerControllerAssetContainer
export def "asset-container delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-container/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve multiple AssetContainers
#
# GET /asset-container
# operationId: getManyBaseAssetContainerControllerAssetContainer
export def "asset-container list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludeStatuses: list # Event types to exclude. Asset containers with any event matching these types will be filtered out.
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<count: float, total: float, page: float, pageCount: float, action: string, entity: string, data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeStatuses" $excludeStatuses "multi") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/asset-container" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single AssetContainer
#
# POST /asset-container
# operationId: createOneBaseAssetContainerControllerAssetContainer
export def "asset-container createOneBaseAssetContainerControllerAssetContainer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  assetVisitId: string # format: uuid
  code: string
  --notes: string
  type: string@type-completer-3 # The type of the asset container
  warehouseId: string # format: uuid
  --dropAppointmentId: string # format: uuid
  --pickupAppointmentId: string # format: uuid
  --state: string@state-completer # The state of the asset container
  --companyId: string # format: uuid
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, type: string, state: string, code: string, notes: string, lastLocationCheckConfirmedAt: record, assetVisitId: string, orgId: string, warehouseId: string, pickupAppointmentId: string, dropAppointmentId: string, companyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-container")
  let body = {tags: $tags, assetVisitId: $assetVisitId, code: $code, notes: $notes, type: $type, warehouseId: $warehouseId, dropAppointmentId: $dropAppointmentId, pickupAppointmentId: $pickupAppointmentId, state: $state, companyId: $companyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /asset-container/{id}/event
#
# operationId: AssetContainerController_getEvents
export def "asset-container-event get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, orgId: string, createDateTime: string, createdBy: record, assetContainerId: string, assetVisitId: record, eventType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-container/($id)/event")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /asset-container/{id}/yard-events
#
# operationId: AssetContainerController_getYardEvents
export def "asset-container-yard-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, orgId: string, createDateTime: string, createdBy: record, assetContainerId: string, assetVisitId: record, eventType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asset-container/($id)/yard-events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /asset-container/event
#
# operationId: AssetContainerController_createEvent
export def "asset-container-event createEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  eventType: string@eventType-completer
  assetContainerId: string # The id of the asset container (format: uuid)
  --assetVisitId: string # The id of the asset visit which this entity is attached to (format: uuid)
]: any -> record<id: string, orgId: string, createDateTime: string, createdBy: record, assetContainerId: string, assetVisitId: record, eventType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-container/event")
  let body = {tags: $tags, eventType: $eventType, assetContainerId: $assetContainerId, assetVisitId: $assetVisitId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /document
#
# operationId: DocumentController_list
export def "document list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # default: 0
  --limit: float # default: 100
  --relatedEntity: string@relatedEntity-completer # The type of the related entity
  --relatedId: string # The UUID of the related entity (format: uuid, e.g. 7725172f-367d-4900-9931-5832cafdcfd1)
  --expirationInSeconds: float # default: 3600
]: nothing -> record<items: list<string>, meta: record<totalRecords: float, totalPages: float, limit: float, offset: float, sorts: list<record>, page: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "relatedEntity" $relatedEntity "scalar") (serialize-qp "relatedId" $relatedId "scalar") (serialize-qp "expirationInSeconds" $expirationInSeconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/document" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a file using its ID
#
# GET /document/{id}/download
# operationId: DocumentController_download
export def "document-download download" [
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
  let full_url = (build-url $base $"/document/($id)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /storage
#
# operationId: StorageController_saveFile
export def "storage saveFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<url: string, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# POST /storage/files
#
# operationId: StorageController_saveFiles
export def "storage-files saveFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list
]: any -> table<url: string, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage/files")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve multiple Spots
#
# GET /yard/spot
# operationId: getManyBaseSpotControllerSpot
export def "yard-spot list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<entity: string, action: string, data: table<id: string, createDateTime: string, createdBy: string, lastChangedDateTime: string, lastChangedBy: string, isActive: bool, tags: list, orgId: string, warehouseId: string, code: string, type: string, spotAreaId: string, observation: string, spotAssignments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/spot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single Spot
#
# POST /yard/spot
# operationId: createOneBaseSpotControllerSpot
export def "yard-spot createOneBaseSpotControllerSpot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  code: string
  type: string@type-completer-4 # The type of the spot
  spotAreaId: string # format: uuid
  --observation: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/yard/spot")
  let body = {tags: $tags, code: $code, type: $type, spotAreaId: $spotAreaId, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate multiple spots
#
# POST /yard/spot/generate
# operationId: SpotController_generate
export def "yard-spot-generate generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  numberOfSpots: float
  startFromNumber: float
  --leadingChar: string
  type: string@type-completer-4 # The type of the spot
  spotAreaId: string # format: uuid
]: any -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/yard/spot/generate")
  let body = {tags: $tags, numberOfSpots: $numberOfSpots, startFromNumber: $startFromNumber, leadingChar: $leadingChar, type: $type, spotAreaId: $spotAreaId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a single Spot
#
# PATCH /yard/spot/{id}
# operationId: updateOneBaseSpotControllerSpot
export def "yard-spot updateOneBaseSpotControllerSpot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --code: string
  --type: string@type-completer-4 # The type of the spot
  --spotAreaId: string # format: uuid
  --observation: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)")
  let body = {tags: $tags, code: $code, type: $type, spotAreaId: $spotAreaId, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single Spot
#
# DELETE /yard/spot/{id}
# operationId: deleteOneBaseSpotControllerSpot
export def "yard-spot delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Spot
#
# GET /yard/spot/{id}
# operationId: getOneBaseSpotControllerSpot
export def "yard-spot get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/yard/spot/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk delete spots
#
# POST /yard/spot/delete/bulk
# operationId: SpotController_bulkDelete
export def "yard-spot-delete-bulk bulkDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  spotIds: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/yard/spot/delete/bulk")
  let body = {tags: $tags, spotIds: $spotIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close a spot
#
# PATCH /yard/spot/{id}/close
# operationId: SpotController_closeSpot
export def "yard-spot-close closeSpot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  reason: string
  --observation: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)/close")
  let body = {tags: $tags, reason: $reason, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Open a spot
#
# PATCH /yard/spot/{id}/open
# operationId: SpotController_openSpot
export def "yard-spot-open openSpot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  reason: string
  --observation: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, code: string, type: string, spotAreaId: string, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)/open")
  let body = {tags: $tags, reason: $reason, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle spot reserve
#
# PATCH /yard/spot/{id}/toggle-reserve
# operationId: SpotController_toggleReserveSpot
export def "yard-spot-toggle-reserve toggleReserveSpot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --objectId: string # format: uuid
  --entityName: string@entityName-completer-2 # The entity type for the reserve action
  --validUntil: string # format: date-time
  --observation: string # Optional observation for the spot reserve action
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)/toggle-reserve")
  let body = {tags: $tags, objectId: $objectId, entityName: $entityName, validUntil: $validUntil, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get spot events
#
# GET /yard/spot/{id}/events
# operationId: SpotController_getSpotEvents
export def "yard-spot-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, eventType: string, reason: string, observation: string, assetContainerId: string, assetVisitId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot/($id)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single SpotArea
#
# POST /yard/spot-area
# operationId: createOneBaseSpotAreaControllerSpotArea
export def "yard-spot-area createOneBaseSpotAreaControllerSpotArea" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  --observation: string
  warehouseId: string # format: uuid
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/yard/spot-area")
  let body = {tags: $tags, name: $name, observation: $observation, warehouseId: $warehouseId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple SpotAreas
#
# GET /yard/spot-area
# operationId: getManyBaseSpotAreaControllerSpotArea
export def "yard-spot-area list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/spot-area" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single SpotArea
#
# PATCH /yard/spot-area/{id}
# operationId: updateOneBaseSpotAreaControllerSpotArea
export def "yard-spot-area updateOneBaseSpotAreaControllerSpotArea" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --name: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-area/($id)")
  let body = {tags: $tags, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single SpotArea
#
# DELETE /yard/spot-area/{id}
# operationId: deleteOneBaseSpotAreaControllerSpotArea
export def "yard-spot-area delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-area/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single SpotArea
#
# GET /yard/spot-area/{id}
# operationId: getOneBaseSpotAreaControllerSpotArea
export def "yard-spot-area get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/yard/spot-area/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single SpotAssignment
#
# POST /yard/spot-assignment
# operationId: createOneBaseSpotAssignmentControllerSpotAssignment
export def "yard-spot-assignment createOneBaseSpotAssignmentControllerSpotAssignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --assetVisitId: string # format: uuid
  --assetContainerId: string # format: uuid
  spotId: string # format: uuid
  --observation: string
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/yard/spot-assignment")
  let body = {tags: $tags, assetVisitId: $assetVisitId, assetContainerId: $assetContainerId, spotId: $spotId, observation: $observation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple SpotAssignments
#
# GET /yard/spot-assignment
# operationId: getManyBaseSpotAssignmentControllerSpotAssignment
export def "yard-spot-assignment list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<data: table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string>, count: float, total: float, page: float, pageCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/spot-assignment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single SpotAssignment
#
# PATCH /yard/spot-assignment/{id}
# operationId: updateOneBaseSpotAssignmentControllerSpotAssignment
export def "yard-spot-assignment updateOneBaseSpotAssignmentControllerSpotAssignment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  --observation: string
  --assetVisitId: string # format: uuid
  --assetContainerId: string # format: uuid
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-assignment/($id)")
  let body = {tags: $tags, observation: $observation, assetVisitId: $assetVisitId, assetContainerId: $assetContainerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single SpotAssignment
#
# DELETE /yard/spot-assignment/{id}
# operationId: deleteOneBaseSpotAssignmentControllerSpotAssignment
export def "yard-spot-assignment delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-assignment/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single SpotAssignment
#
# GET /yard/spot-assignment/{id}
# operationId: getOneBaseSpotAssignmentControllerSpotAssignment
export def "yard-spot-assignment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/yard/spot-assignment/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Depart a spot assignment
#
# PATCH /yard/spot-assignment/{id}/depart
# operationId: SpotAssignmentController_depart
export def "yard-spot-assignment-depart depart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  departType: string@departType-completer
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-assignment/($id)/depart")
  let body = {tags: $tags, departType: $departType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reassign a spot assignment
#
# PATCH /yard/spot-assignment/{id}/reassign
# operationId: SpotAssignmentController_reassignSpot
export def "yard-spot-assignment-reassign reassignSpot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  spotId: string # format: uuid
  --reason: string
  --observation: string
  --moveContainer: oneof<nothing, bool> # When set to true, it moves only the asset container
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string, spotId: string, assetVisitId: record, assetContainerId: record, observation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/yard/spot-assignment/($id)/reassign")
  let body = {tags: $tags, spotId: $spotId, reason: $reason, observation: $observation, moveContainer: $moveContainer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get lean spot grid data optimized for grid view rendering
#
# GET /yard/view/spot-grid
# operationId: YardViewController_getSpotGrid
export def "yard-view-spot-grid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseId: string
]: nothing -> record<areas: table<id: string, name: string, warehouseId: string, orgId: string, spots: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouseId" $warehouseId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/view/spot-grid" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asset visits and containers waiting for spot assignment
#
# GET /yard/view/waiting-assets
# operationId: YardViewController_getWaitingAssets
export def "yard-view-waiting-assets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseId: string
]: nothing -> record<assets: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouseId" $warehouseId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/view/waiting-assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flattened list view rows (one row per container or truckless visit)
#
# GET /yard/view/list-rows
# operationId: YardViewController_getListViewRows
export def "yard-view-list-rows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseId: string
  --includeWaiting: oneof<nothing, bool>
]: nothing -> record<rows: table<id: string, isWaiting: bool, spot: record, spotArea: record, spotReserves: list, assetArrivedAt: string, assetContainer: record, assetVisit: record, appointment: record, dropAppointmentCompany: record, pickupAppointmentCompany: record, dropoffAppointment: record, pickupAppointment: record, openMoveTask: record, customFormData: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouseId" $warehouseId "scalar") (serialize-qp "includeWaiting" $includeWaiting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/view/list-rows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get full spot detail for drawer: spot, task, assignment, and when applicable arrival/same-appointment containers
#
# GET /yard/view/spot-detail
# operationId: YardViewController_getSpotDetail
export def "yard-view-spot-detail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spotId: string
  --warehouseId: string
]: nothing -> record<spot: record, openMoveTask: record<id: string, refNum: string, role: string, child: record<originSpot: record, destinationSpot: record, assetContainer: record>>, arrivalContainers: table<id: string, code: record, type: string, pickupAppointmentId: record, dropAppointmentId: record>, containersWithSamePickupAppointment: table<id: string, code: record, type: string, pickupAppointmentId: record, dropAppointmentId: record>, containersWithSameDropAppointment: table<id: string, code: record, type: string, pickupAppointmentId: record, dropAppointmentId: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spotId" $spotId "scalar") (serialize-qp "warehouseId" $warehouseId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/yard/view/spot-detail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single WarehouseGroup
#
# GET /warehouse-group/{id}
# operationId: getOneBaseWarehouseGroupControllerWarehouseGroup
export def "warehouse-group get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "join" $join "multi") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/warehouse-group/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single WarehouseGroup
#
# DELETE /warehouse-group/{id}
# operationId: deleteOneBaseWarehouseGroupControllerWarehouseGroup
export def "warehouse-group delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse-group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single WarehouseGroup
#
# PATCH /warehouse-group/{id}
# operationId: updateOneBaseWarehouseGroupControllerWarehouseGroup
export def "warehouse-group updateOneBaseWarehouseGroupControllerWarehouseGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  warehouseIds: list
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/warehouse-group/($id)")
  let body = {tags: $tags, name: $name, warehouseIds: $warehouseIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve multiple WarehouseGroups
#
# GET /warehouse-group
# operationId: getManyBaseWarehouseGroupControllerWarehouseGroup
export def "warehouse-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Selects resource fields. <a href="https://github.com/nestjsx/crud/wiki/Requests#select" target="_blank">Docs</a>
  --s: string # Adds search condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#search" target="_blank">Docs</a>
  --filter: list # Adds filter condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#filter" target="_blank">Docs</a>
  --or: list # Adds OR condition. <a href="https://github.com/nestjsx/crud/wiki/Requests#or" target="_blank">Docs</a>
  --qp-sort: list # Adds sort by field. <a href="https://github.com/nestjsx/crud/wiki/Requests#sort" target="_blank">Docs</a>
  --join: list # Adds relational resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#join" target="_blank">Docs</a>
  --limit: int # Limit amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#limit" target="_blank">Docs</a>
  --offset: int # Offset amount of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#offset" target="_blank">Docs</a>
  --page: int # Page portion of resources. <a href="https://github.com/nestjsx/crud/wiki/Requests#page" target="_blank">Docs</a>
  --cache: int # Reset cache (if was enabled). <a href="https://github.com/nestjsx/crud/wiki/Requests#cache" target="_blank">Docs</a>
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "s" $s "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "or" $or "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "join" $join "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cache" $cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/warehouse-group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a single WarehouseGroup
#
# POST /warehouse-group
# operationId: createOneBaseWarehouseGroupControllerWarehouseGroup
export def "warehouse-group createOneBaseWarehouseGroupControllerWarehouseGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
  name: string
  warehouseIds: list
]: any -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/warehouse-group")
  let body = {tags: $tags, name: $name, warehouseIds: $warehouseIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /saml/config
#
# operationId: SamlController_getConfig
export def "saml-config get" [
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
  let full_url = (build-url $base "/saml/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /saml/config
#
# operationId: SamlController_updateConfig
export def "saml-config updateConfig" [
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
  let full_url = (build-url $base "/saml/config")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /saml/config
#
# operationId: SamlController_resetConfig
export def "saml-config resetConfig" [
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
  let full_url = (build-url $base "/saml/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /saml/metadata-url
#
# operationId: SamlController_getSpMetadataUrl
export def "saml-metadata-url get" [
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
  let full_url = (build-url $base "/saml/metadata-url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /saml/ac/{orgId}
#
# operationId: SamlController_samlAssertionConsumer
export def "saml-ac samlAssertionConsumer" [
  orgId: any
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
  let full_url = (build-url $base $"/saml/ac/($orgId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /saml/login/{orgId}
#
# operationId: SamlController_samlLogin
export def "saml-login samlLogin" [
  orgId: any
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
  let full_url = (build-url $base $"/saml/login/($orgId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /saml/metadata/{orgId}
#
# operationId: SamlController_getSpMetadata
export def "saml-metadata get" [
  orgId: any
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
  let full_url = (build-url $base $"/saml/metadata/($orgId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /gates/{warehouseId}
#
# operationId: GatesController_listGatesByWarehouse
export def "gates listGatesByWarehouse" [
  warehouseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gates/($warehouseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /observations
#
# operationId: ObservationController_getObservations
export def "observations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/observations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /observations/{id}
#
# operationId: ObservationController_getObservation
export def "observations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, createDateTime: string, createdBy: record, lastChangedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /observations/{id}/asset-visit
#
# operationId: ObservationController_createAssetVisit
export def "observations-asset-visit createAssetVisit" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/observations/($id)/asset-visit")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /audit-log/{objectId}
#
# operationId: AuditLogController_search
export def "audit-log search" [
  objectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit-log/($objectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /settings-metadata/{entityType}
#
# operationId: SettingsMetadataController_getAll
export def "settings-metadata list" [
  entityType: any
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
  let full_url = (build-url $base $"/settings-metadata/($entityType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /settings-metadata/{entityType}/{settingKey}
#
# operationId: SettingsMetadataController_getOne
export def "settings-metadata get" [
  entityType: string
  settingKey: string
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
  let full_url = (build-url $base $"/settings-metadata/($entityType)/($settingKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /settings-metadata/validate/{entityType}
#
# operationId: SettingsMetadataController_validateSetting
export def "settings-metadata-validate validateSetting" [
  entityType: string
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
  let full_url = (build-url $base $"/settings-metadata/validate/($entityType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment volume by load type and week day
#
# GET /metrics/appointment-volume/load-type
# operationId: MetricsController_getLoadTypeVolume
export def "metrics-appointment-volume-load-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/load-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment volume by time of day
#
# GET /metrics/appointment-volume/time-of-day
# operationId: MetricsController_getTimeOfDayVolume
export def "metrics-appointment-volume-time-of-day get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/time-of-day")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment volume by date
#
# GET /metrics/appointment-volume/date
# operationId: MetricsController_getDateVolume
export def "metrics-appointment-volume-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/date")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment volume by carrier
#
# GET /metrics/appointment-volume/carrier
# operationId: MetricsController_getCarrierVolume
export def "metrics-appointment-volume-carrier get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/carrier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment duration average by load type
#
# GET /metrics/appointment-volume/average-duration-by-load-type
# operationId: MetricsController_getAverageDurationByLoadType
export def "metrics-appointment-volume-average-duration-by-load-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/average-duration-by-load-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment duration average by dock and day of week
#
# GET /metrics/appointment-volume/day-of-week
# operationId: MetricsController_getDayOfWeekVolume
export def "metrics-appointment-volume-day-of-week get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/day-of-week")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment duration average by status
#
# GET /metrics/appointment-volume/status
# operationId: MetricsController_getStatusVolume
export def "metrics-appointment-volume-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment duration average by dock and status
#
# GET /metrics/appointment-volume/status-by-dock
# operationId: MetricsController_getStatusByDockVolume
export def "metrics-appointment-volume-status-by-dock get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/appointment-volume/status-by-dock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The average time spent in each appointment status
#
# POST /metrics/appointments/status-times
# operationId: MetricsController_getStatusTimes
export def "metrics-appointments-status-times post" [
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
  let full_url = (build-url $base "/metrics/appointments/status-times")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve file link with the appointment list that matches the criteria described in the request body, 
#
# POST /metrics/appointments/excel
# operationId: MetricsController_getExcelReport
export def "metrics-appointments-excel post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emailCCs: list
  --limit: float
  --dockIds: list
  --loadTypeIds: list
  --carrierIds: list
  --tags: list
  --dateField: record
  --appointmentTypes: list
  --allCarriers: oneof<nothing, bool>
  --exportFields: list
  --skipCustomFields: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emailCCs" $emailCCs "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/appointments/excel" $qp)
  let body = {limit: $limit, dockIds: $dockIds, loadTypeIds: $loadTypeIds, carrierIds: $carrierIds, tags: $tags, dateField: $dateField, appointmentTypes: $appointmentTypes, allCarriers: $allCarriers, exportFields: $exportFields, skipCustomFields: $skipCustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve file link with the yard data list that matches the criteria described in the request body
#
# POST /metrics/yard/excel
# operationId: MetricsController_getYardExcelReport
export def "metrics-yard-excel post" [
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
  let full_url = (build-url $base "/metrics/yard/excel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve file link with the asset visits (check-ins) list that matches the criteria described in the request body
#
# POST /metrics/asset-visits/excel
# operationId: MetricsController_getAssetVisitExcelReport
export def "metrics-asset-visits-excel post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emailCCs: list
  --warehouseIds: list
  --carrierIds: list
  --statuses: list
  --fromDate: string
  --toDate: string
  --dateField: string@dateField-completer
  --exportFields: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emailCCs" $emailCCs "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/asset-visits/excel" $qp)
  let body = {warehouseIds: $warehouseIds, carrierIds: $carrierIds, statuses: $statuses, fromDate: $fromDate, toDate: $toDate, dateField: $dateField, exportFields: $exportFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve warehouse dock capacity usage information per warehouse
#
# POST /metrics/warehouse/capacity-usage
# operationId: MetricsController_getWarehouseCapacityUsage
export def "metrics-warehouse-capacity-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dockIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/warehouse/capacity-usage")
  let body = {dockIds: $dockIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve warehouse insights
#
# POST /metrics/warehouse
# operationId: MetricsController_getWarehouseMetrics
export def "metrics-warehouse post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/warehouse")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve carrier insights data with each status percentage
#
# GET /metrics/carrier/status-percentages
# operationId: MetricsController_getCarrierStatusPercentages
export def "metrics-carrier-status-percentages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/carrier/status-percentages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve dock metrics of dwell time by day of week
#
# GET /metrics/dock/dwell-time
# operationId: MetricsController_getDockDwellTime
export def "metrics-dock-dwell-time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # From date to filter
  --toDate: string # To date to filter
  --warehouseId: string # Warehouse ID to filter
  --dockId: string # Dock ID to filter
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "warehouseId" $warehouseId "scalar") (serialize-qp "dockId" $dockId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/dock/dwell-time" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment count per dock
#
# GET /metrics/counts/appointment-count-for-docks
# operationId: MetricsController_getAppointmentCountForDocks
export def "metrics-counts-appointment-count-for-docks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dockIds: string # Dock IDs array
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dockIds" $dockIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/counts/appointment-count-for-docks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment count per carrier
#
# GET /metrics/counts/appointment-count-for-carrier
# operationId: MetricsController_getAppointmentCountForCarrier
export def "metrics-counts-appointment-count-for-carrier get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrierId: string # Carrier ID
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrierId" $carrierId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/counts/appointment-count-for-carrier" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appointment count by status for current carrier
#
# GET /metrics/counts/appointment-count-for-carrier/status
# operationId: MetricsController_getAppointmentCountByStatusForCarrier
export def "metrics-counts-appointment-count-for-carrier-status get" [
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
  let full_url = (build-url $base "/metrics/counts/appointment-count-for-carrier/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reserve count for user
#
# GET /metrics/counts/reserve-count-for-user
# operationId: MetricsController_getReserveCountForUser
export def "metrics-counts-reserve-count-for-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string # User ID
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/counts/reserve-count-for-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds the next available appointment time for each dock and loadtype, starting from the current date and time onward
#
# POST /metrics/loadtype/first-avail-appt
# operationId: MetricsController_getFirstAvailAppts
export def "metrics-loadtype-first-avail-appt post" [
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
  let full_url = (build-url $base "/metrics/loadtype/first-avail-appt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an appointment list that matches the criteria described in the request body
#
# POST /metrics-v2/appointments
# operationId: MetricsV2Controller_getAppointmentsList
export def "metrics-v2-appointments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dockIds: list
  --loadTypeIds: list
  --carrierIds: list
  --tags: list
  --dateField: record
  --appointmentTypes: list
  --allCarriers: oneof<nothing, bool>
  --exportFields: list
  --skipCustomFields: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics-v2/appointments")
  let body = {dockIds: $dockIds, loadTypeIds: $loadTypeIds, carrierIds: $carrierIds, tags: $tags, dateField: $dateField, appointmentTypes: $appointmentTypes, allCarriers: $allCarriers, exportFields: $exportFields, skipCustomFields: $skipCustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an asset visit list that matches the criteria described in the request body
#
# POST /metrics-v2/asset-visits
# operationId: MetricsV2Controller_getAssetVisitsList
export def "metrics-v2-asset-visits post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouseIds: list
  --carrierIds: list
  --statuses: list
  --fromDate: string
  --toDate: string
  --dateField: string@dateField-completer
  page: float
  pageSize: float
  --exportFields: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics-v2/asset-visits")
  let body = {warehouseIds: $warehouseIds, carrierIds: $carrierIds, statuses: $statuses, fromDate: $fromDate, toDate: $toDate, dateField: $dateField, page: $page, pageSize: $pageSize, exportFields: $exportFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /bol
#
# operationId: BolController_create
export def "bol create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appointmentId: string # format: uuid
  documentUrl: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bol")
  let body = {appointmentId: $appointmentId, documentUrl: $documentUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /bol/appointment/{appointmentId}
#
# operationId: BolController_getByAppointmentId
export def "bol-appointment get" [
  appointmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, originalDoc: record<originalDocId: string, externalKey: string>, signedDoc: record<id: string, externalKey: string>, signedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bol/appointment/($appointmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /bol/{bolId}
#
# operationId: BolController_get
export def "bol get" [
  bolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, originalDoc: record<originalDocId: string, externalKey: string>, signedDoc: record<id: string, externalKey: string>, signedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bol/($bolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
