# Auto-generated client for Track-POD API v2.0
# Source: https://raw.githubusercontent.com/api-evangelist/track-pod/main/openapi/track-pod-openapi.yml
# Auth: --token flag or $env.TRACK_POD_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRACK_POD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-KEY: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/plain" "text/xml"] }
def Status-completer [] { ["NotDelivered"] }
def RejectReason-completer [] { ["Canceled"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "address AddAddress" } } | get name | first)
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

# Add or update address
#
# POST /Address
# operationId: AddAddress
export def "address AddAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 30495)
  --Name: string # Address name (nullable, e.g. 2 St Josephs Crescent, Liverpool, L3 3JF)
  --Street: string # Street (nullable, e.g. Josephs Crescent)
  --City: string # City (nullable, e.g. Liverpool)
  --State: string # State (nullable, e.g. )
  --PostalCode: string # Postal Code (nullable, e.g. )
  FullAddress: string # Full (customer's) address (e.g. 2 St Josephs Crescent, Liverpool, L3 3JF)
  --Zone: string # Address zone (nullable, e.g. Lvp)
  --Lat: float # Location latitude (nullable, format: double, e.g. 25.290479)
  --Lon: float # Location longitude (nullable, format: double, e.g. 65.294049)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Address")
  let body = {Id: $Id, Name: $Name, Street: $Street, City: $City, State: $State, PostalCode: $PostalCode, FullAddress: $FullAddress, Zone: $Zone, Lat: $Lat, Lon: $Lon, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get driver by Track-POD unique identifier
#
# GET /Driver/Id/{id}
# operationId: GetDriverById
export def "driver-id GetDriverById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Id: string, Number: int, Name: string, Vehicle: string, Phone: string, Username: string, DepotId: string, Depot: string, HomeAddress: string, Zone: string, Active: bool, Note: string, TeamCodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Driver/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete driver by Track-POD unique identifier
#
# DELETE /Driver/Id/{id}
# operationId: DeleteDriverById
export def "driver-id DeleteDriverById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Driver/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get driver by Username
#
# GET /Driver/Username/{username}
# operationId: GetDriverByUsername
export def "driver-username GetDriverByUsername" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Id: string, Number: int, Name: string, Vehicle: string, Phone: string, Username: string, DepotId: string, Depot: string, HomeAddress: string, Zone: string, Active: bool, Note: string, TeamCodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Driver/Username/($username)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Driver by id.
#
# DELETE /Driver/Username/{username}
# operationId: DeleteDriverByUsername
export def "driver-username DeleteDriverByUsername" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Driver/Username/($username)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get drivers
#
# GET /Driver
# operationId: GetDrivers
export def "driver GetDrivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Id: string, Number: int, Name: string, Vehicle: string, Phone: string, Username: string, DepotId: string, Depot: string, HomeAddress: string, Zone: string, Active: bool, Note: string, TeamCodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Driver")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add driver
#
# POST /Driver
# operationId: AddDriver
export def "driver AddDriver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Name: string # Required (*)   Name (nullable, e.g. John Doe)
  --Vehicle: string # Vehicle number (nullable, e.g. NYC 1898)
  --Phone: string # Phone (nullable, e.g. +1-XXX-456-7890)
  --Username: string # Required (*)   Username (nullable, e.g. john)
  --Password: string # Required (*)   Password (nullable)
  --DepotId: string # Unique identifier in user accounting system (nullable, e.g. 1)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --HomeAddress: string # Home address (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --Zone: string # Zone (nullable, e.g. South)
  --Active: string@bool-completer # Active flag (nullable, e.g. true)
  --Note: string # Note (nullable, e.g. My favourite driver)
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Driver")
  let body = {Name: $Name, Vehicle: $Vehicle, Phone: $Phone, Username: $Username, Password: $Password, DepotId: $DepotId, Depot: $Depot, HomeAddress: $HomeAddress, Zone: $Zone, Active: $Active, Note: $Note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update driver
#
# PUT /Driver
# operationId: UpdateDriver
export def "driver UpdateDriver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Id: string # Track-POD unique identifier (nullable, format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --Name: string # Required (*)   Name (nullable, e.g. John Doe)
  --Vehicle: string # Vehicle number (nullable, e.g. NYC 1898)
  --Phone: string # Phone (nullable, e.g. +1-XXX-456-7890)
  --Username: string # Required (*)   Username (nullable, e.g. john)
  --Password: string # Required (*)   Password (nullable)
  --DepotId: string # Unique identifier in user accounting system (nullable, e.g. 1)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --HomeAddress: string # Home address (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --Zone: string # Zone (nullable, e.g. South)
  --Active: string@bool-completer # Active flag (nullable, e.g. true)
  --Note: string # Note (nullable, e.g. My favourite driver)
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Driver")
  let body = {Id: $Id, Name: $Name, Vehicle: $Vehicle, Phone: $Phone, Username: $Username, Password: $Password, DepotId: $DepotId, Depot: $Depot, HomeAddress: $HomeAddress, Zone: $Zone, Active: $Active, Note: $Note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add unscheduled order
#
# POST /Order
# operationId: AddOrder
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
# --CustomFields item shape: {Id?: string, Value?: string}
# --PickupOrder shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
# --NotificationsPolicy shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
export def "order AddOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --updateGoodsPrice: string@bool-completer # Force update existing Price in the Goods directory from the payload data. (default: false)
  --Number: string # Order/Invoice/Job/Waybill number (nullable, e.g. cv30001-2)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 10000345)
  --Date: string # Order date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --Type: int # Order type: 0 - Delivery order; 1 - Collection order (format: int32, e.g. 0)
  --Shipper: string # Shipper/Supplier name (nullable, e.g. Sanitex)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --Client: string # Required (*)   Client/Customer name (nullable, e.g. Maxima)
  --Address: string # Required (*)   Delivery/Pickup address. Address cannot be updated for orders planned into routes (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --AddressLat: float # Address GPS Latitude (nullable, format: double, e.g. 25.290479)
  --AddressLon: float # Address GPS Longitude (nullable, format: double, e.g. 65.294049)
  --AddressZone: string # Address zone (nullable, e.g. Zone 1)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
  --ServiceTime: float # Service Time, min. If seconds are specified value will be decimal (nullable, format: double, e.g. 10)
  --Note: string # Notes to order (nullable, e.g. Only to sign Invoice)
  --ContactName: string # Customer’s contact name (nullable, e.g. John Doe)
  --Phone: string # Customer’s contact phone number (nullable, e.g. +37061191244)
  --Email: string # Customer’s e-mail (nullable, e.g. X-604@maxima.com)
  --Weight: float # Total weight (nullable, format: double, e.g. 50.5)
  --Volume: float # Total volume (nullable, format: double, e.g. 8.54)
  --Pallets: float # Pallets count (nullable, format: double, e.g. 3.5)
  --COD: float # Amount of Cash on Delivery (nullable, format: double, e.g. 20.45)
  --InvoiceId: string # Invoice identifier in user accounting system (nullable, e.g. inv0002 )
  --CustomerReferenceId: string # Customer reference order identifier in user accounting system (nullable, e.g. ord123/1)
  --Barcode: string # Barcode for scanning in the mobile application (nullable, e.g. 1234567890123)
  --ShipperId: string # Optional, unique identifier in user accounting system for shipper directory (nullable, e.g. 357)
  --DepotId: string # Optional, unique identifier in user accounting system for depot directory (nullable, e.g. 1)
  --ClientId: string # Optional, unique identifier in user accounting system for client directory (nullable, e.g. 247)
  --AddressId: string # Optional, unique identifier in user accounting system for address directory (nullable, e.g. 13587)
  --GoodsList: list # Goods List in Order (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
  --PickupOrder: record # shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
  --Priority: string # Priority Possible values: low, normal, high (nullable)
  --TeamCode: string # Team code (nullable)
  --NotificationsPolicy: record # shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "updateGoodsPrice" $updateGoodsPrice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Order" $qp)
  let body = {Number: $Number, Id: $Id, Date: $Date, Type: $Type, Shipper: $Shipper, Depot: $Depot, Client: $Client, Address: $Address, AddressLat: $AddressLat, AddressLon: $AddressLon, AddressZone: $AddressZone, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo, ServiceTime: $ServiceTime, Note: $Note, ContactName: $ContactName, Phone: $Phone, Email: $Email, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, COD: $COD, InvoiceId: $InvoiceId, CustomerReferenceId: $CustomerReferenceId, Barcode: $Barcode, ShipperId: $ShipperId, DepotId: $DepotId, ClientId: $ClientId, AddressId: $AddressId, GoodsList: $GoodsList, CustomFields: $CustomFields, PickupOrder: $PickupOrder, Priority: $Priority, TeamCode: $TeamCode, NotificationsPolicy: $NotificationsPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update order
#
# PUT /Order
# operationId: UpdateOrder
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
# --CustomFields item shape: {Id?: string, Value?: string}
# --PickupOrder shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
# --NotificationsPolicy shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
export def "order UpdateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --forceUpdate: string@bool-completer # Allows updating completed orders. (default: false)
  --Number: string # Order/Invoice/Job/Waybill number (nullable, e.g. cv30001-2)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 10000345)
  --Date: string # Order date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --Type: int # Order type: 0 - Delivery order; 1 - Collection order (format: int32, e.g. 0)
  --Shipper: string # Shipper/Supplier name (nullable, e.g. Sanitex)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --Client: string # Required (*)   Client/Customer name (nullable, e.g. Maxima)
  --Address: string # Required (*)   Delivery/Pickup address. Address cannot be updated for orders planned into routes (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --AddressLat: float # Address GPS Latitude (nullable, format: double, e.g. 25.290479)
  --AddressLon: float # Address GPS Longitude (nullable, format: double, e.g. 65.294049)
  --AddressZone: string # Address zone (nullable, e.g. Zone 1)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
  --ServiceTime: float # Service Time, min. If seconds are specified value will be decimal (nullable, format: double, e.g. 10)
  --Note: string # Notes to order (nullable, e.g. Only to sign Invoice)
  --ContactName: string # Customer’s contact name (nullable, e.g. John Doe)
  --Phone: string # Customer’s contact phone number (nullable, e.g. +37061191244)
  --Email: string # Customer’s e-mail (nullable, e.g. X-604@maxima.com)
  --Weight: float # Total weight (nullable, format: double, e.g. 50.5)
  --Volume: float # Total volume (nullable, format: double, e.g. 8.54)
  --Pallets: float # Pallets count (nullable, format: double, e.g. 3.5)
  --COD: float # Amount of Cash on Delivery (nullable, format: double, e.g. 20.45)
  --InvoiceId: string # Invoice identifier in user accounting system (nullable, e.g. inv0002 )
  --CustomerReferenceId: string # Customer reference order identifier in user accounting system (nullable, e.g. ord123/1)
  --Barcode: string # Barcode for scanning in the mobile application (nullable, e.g. 1234567890123)
  --ShipperId: string # Optional, unique identifier in user accounting system for shipper directory (nullable, e.g. 357)
  --DepotId: string # Optional, unique identifier in user accounting system for depot directory (nullable, e.g. 1)
  --ClientId: string # Optional, unique identifier in user accounting system for client directory (nullable, e.g. 247)
  --AddressId: string # Optional, unique identifier in user accounting system for address directory (nullable, e.g. 13587)
  --GoodsList: list # Goods List in Order (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
  --PickupOrder: record # shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
  --Priority: string # Priority Possible values: low, normal, high (nullable)
  --TeamCode: string # Team code (nullable)
  --NotificationsPolicy: record # shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Order" $qp)
  let body = {Number: $Number, Id: $Id, Date: $Date, Type: $Type, Shipper: $Shipper, Depot: $Depot, Client: $Client, Address: $Address, AddressLat: $AddressLat, AddressLon: $AddressLon, AddressZone: $AddressZone, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo, ServiceTime: $ServiceTime, Note: $Note, ContactName: $ContactName, Phone: $Phone, Email: $Email, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, COD: $COD, InvoiceId: $InvoiceId, CustomerReferenceId: $CustomerReferenceId, Barcode: $Barcode, ShipperId: $ShipperId, DepotId: $DepotId, ClientId: $ClientId, AddressId: $AddressId, GoodsList: $GoodsList, CustomFields: $CustomFields, PickupOrder: $PickupOrder, Priority: $Priority, TeamCode: $TeamCode, NotificationsPolicy: $NotificationsPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add unscheduled orders (the maximum is 500)
#
# POST /Order/Bulk
# operationId: AddOrderBulk
export def "order-bulk AddOrderBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --updateGoodsPrice: string@bool-completer # Force update existing Price in the Goods directory from the payload data. (default: false)
  --body: record
]: any -> table<Number: string, Id: string, Error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "updateGoodsPrice" $updateGoodsPrice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Order/Bulk" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get order by number
#
# GET /Order/Number/{number}
# operationId: GetOrderByNumber
export def "order-number GetOrderByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: table<OrderLineId: string, GoodsId: string, GoodsName: string, GoodsUnit: string, Note: string, Quantity: float, QuantityFact: float, Cost: float, RejectReason: string, HasPhoto: bool, Photos: list, OrderLineBarcode: string, GoodsBarcode: string, Scanned: bool, LoadStatus: string, LoadCheckScanRejectReason: string, ScanRejectReason: string>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list<record>, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: table<Id: string, Label: string, Value: any>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete order by number
#
# DELETE /Order/Number/{number}
# operationId: DeleteOrderByNumber
export def "order-number DeleteOrderByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order by Id
#
# GET /Order/Id/{id}
# operationId: GetOrderById
export def "order-id GetOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: table<OrderLineId: string, GoodsId: string, GoodsName: string, GoodsUnit: string, Note: string, Quantity: float, QuantityFact: float, Cost: float, RejectReason: string, HasPhoto: bool, Photos: list, OrderLineBarcode: string, GoodsBarcode: string, Scanned: bool, LoadStatus: string, LoadCheckScanRejectReason: string, ScanRejectReason: string>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list<record>, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: table<Id: string, Label: string, Value: any>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete order by id.
#
# DELETE /Order/Id/{id}
# operationId: DeleteOrderById
export def "order-id DeleteOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order by TrackId
#
# GET /Order/TrackId/{trackId}
# operationId: GetOrderByTrackId
export def "order-track-id GetOrderByTrackId" [
  trackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: table<OrderLineId: string, GoodsId: string, GoodsName: string, GoodsUnit: string, Note: string, Quantity: float, QuantityFact: float, Cost: float, RejectReason: string, HasPhoto: bool, Photos: list, OrderLineBarcode: string, GoodsBarcode: string, Scanned: bool, LoadStatus: string, LoadCheckScanRejectReason: string, ScanRejectReason: string>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list<record>, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: table<Id: string, Label: string, Value: any>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/TrackId/($trackId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update order by TrackId
#
# PUT /Order/TrackId/{trackId}
# operationId: UpdateOrderByTrackId
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
# --CustomFields item shape: {Id?: string, Value?: string}
# --PickupOrder shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
# --NotificationsPolicy shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
export def "order-track-id UpdateOrderByTrackId" [
  trackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --Number: string # Order/Invoice/Job/Waybill number (nullable, e.g. cv30001-2)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 10000345)
  --Date: string # Order date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --Type: int # Order type: 0 - Delivery order; 1 - Collection order (format: int32, e.g. 0)
  --Shipper: string # Shipper/Supplier name (nullable, e.g. Sanitex)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --Client: string # Required (*)   Client/Customer name (nullable, e.g. Maxima)
  --Address: string # Required (*)   Delivery/Pickup address. Address cannot be updated for orders planned into routes (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --AddressLat: float # Address GPS Latitude (nullable, format: double, e.g. 25.290479)
  --AddressLon: float # Address GPS Longitude (nullable, format: double, e.g. 65.294049)
  --AddressZone: string # Address zone (nullable, e.g. Zone 1)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
  --ServiceTime: float # Service Time, min. If seconds are specified value will be decimal (nullable, format: double, e.g. 10)
  --Note: string # Notes to order (nullable, e.g. Only to sign Invoice)
  --ContactName: string # Customer’s contact name (nullable, e.g. John Doe)
  --Phone: string # Customer’s contact phone number (nullable, e.g. +37061191244)
  --Email: string # Customer’s e-mail (nullable, e.g. X-604@maxima.com)
  --Weight: float # Total weight (nullable, format: double, e.g. 50.5)
  --Volume: float # Total volume (nullable, format: double, e.g. 8.54)
  --Pallets: float # Pallets count (nullable, format: double, e.g. 3.5)
  --COD: float # Amount of Cash on Delivery (nullable, format: double, e.g. 20.45)
  --InvoiceId: string # Invoice identifier in user accounting system (nullable, e.g. inv0002 )
  --CustomerReferenceId: string # Customer reference order identifier in user accounting system (nullable, e.g. ord123/1)
  --Barcode: string # Barcode for scanning in the mobile application (nullable, e.g. 1234567890123)
  --ShipperId: string # Optional, unique identifier in user accounting system for shipper directory (nullable, e.g. 357)
  --DepotId: string # Optional, unique identifier in user accounting system for depot directory (nullable, e.g. 1)
  --ClientId: string # Optional, unique identifier in user accounting system for client directory (nullable, e.g. 247)
  --AddressId: string # Optional, unique identifier in user accounting system for address directory (nullable, e.g. 13587)
  --GoodsList: list # Goods List in Order (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
  --PickupOrder: record # shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
  --Priority: string # Priority Possible values: low, normal, high (nullable)
  --TeamCode: string # Team code (nullable)
  --NotificationsPolicy: record # shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Order/TrackId/($trackId)" $qp)
  let body = {Number: $Number, Id: $Id, Date: $Date, Type: $Type, Shipper: $Shipper, Depot: $Depot, Client: $Client, Address: $Address, AddressLat: $AddressLat, AddressLon: $AddressLon, AddressZone: $AddressZone, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo, ServiceTime: $ServiceTime, Note: $Note, ContactName: $ContactName, Phone: $Phone, Email: $Email, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, COD: $COD, InvoiceId: $InvoiceId, CustomerReferenceId: $CustomerReferenceId, Barcode: $Barcode, ShipperId: $ShipperId, DepotId: $DepotId, ClientId: $ClientId, AddressId: $AddressId, GoodsList: $GoodsList, CustomFields: $CustomFields, PickupOrder: $PickupOrder, Priority: $Priority, TeamCode: $TeamCode, NotificationsPolicy: $NotificationsPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get orders by date
#
# GET /Order/Date/{date}
# operationId: GetOrderByDate
export def "order-date GetOrderByDate" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list<record>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list<record>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get orders by route date
#
# GET /Order/Route/Date/{date}
# operationId: GetOrderByRouteDate
export def "order-route-date GetOrderByRouteDate" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list<record>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list<record>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Route/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get orders by route code
#
# GET /Order/Route/Code/{code}
# operationId: GetOrderByRouteCode
export def "order-route-code GetOrderByRouteCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list<record>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list<record>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Route/Code/($code)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get orders after status modify date and time (min. request time is UTC - 1 day)
#
# GET /Order/Status/Date/{date}
# operationId: GetOrderByStatusDate
export def "order-status-date GetOrderByStatusDate" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list<record>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list<record>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Status/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get orders by number (last 25 orders)
#
# GET /Order/Number/{number}/List
# operationId: GetOrdersByNumber
export def "order-number-list GetOrdersByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list<record>, PickupOrder: record<Id_DocShipment: int, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, ContactName: string, Phone: string, Email: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, CustomFields: list, Note: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReasonId: int, RejectReason: string, ScanReasonId: int, ScanRejectReason: string, LoadCheckScanReasonId: int, LoadCheckScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, HasRoutePointPhoto: bool, StatusDate: string, PlanTime: int, PlanTimeDep: int, PlanServiceTime: int, ETA: string, UpdatedETA: string, RouteDate: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatusId: string, HasLoadSignature: bool, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, AddressNote: string, ClientNote: string, CustomFieldsStr: string, CancelledStatus: int, RescheduledTimes: int>, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record<PriorToRouteNotificationEnabled: bool, AtRouteStartNotificationEnabled: bool, EnRouteNotificationEnabled: bool, AtDepartureNotificationEnabled: bool>, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list<string>, HasPhoto: bool, Photos: list<string>, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list<record>, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list<string>, ChangeDate: string, RescheduledTimes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)/List")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set order status by number. Deprecated. Please use /Order/Complete or Reject instead.
#
# PUT /Order/Number/{number}/Status
# DEPRECATED
# operationId: SetOrderStatusByNumber
@deprecated
export def "order-number-status SetOrderStatusByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Status: string@Status-completer
  --RejectReason: string@RejectReason-completer
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)/Status")
  let body = {Status: $Status, RejectReason: $RejectReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set order status by TrackId. Deprecated. Please use /Order/Complete or Reject instead.
#
# PUT /Order/TrackId/{trackId}/Status
# DEPRECATED
# operationId: SetOrderStatusByTrackId
@deprecated
export def "order-track-id-status SetOrderStatusByTrackId" [
  trackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Status: string@Status-completer
  --RejectReason: string@RejectReason-completer
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/TrackId/($trackId)/Status")
  let body = {Status: $Status, RejectReason: $RejectReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set order status by id. Deprecated. Please use /Order/Complete or Reject instead.
#
# PUT /Order/Id/{id}/Status
# DEPRECATED
# operationId: SetOrderStatusById
@deprecated
export def "order-id-status SetOrderStatusById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Status: string@Status-completer
  --RejectReason: string@RejectReason-completer
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)/Status")
  let body = {Status: $Status, RejectReason: $RejectReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get order POD by number
#
# GET /Order/Number/{number}/Pdf
# operationId: GetOrderPodByNumber
export def "order-number-pdf GetOrderPodByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)/Pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order POD by Id
#
# GET /Order/Id/{id}/Pdf
# operationId: GetOrderPodById
export def "order-id-pdf GetOrderPodById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)/Pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order shipping label by number
#
# GET /Order/Number/{number}/Shipping-label
# operationId: GetOrderShippingLabelByNumber
export def "order-number-shipping-label GetOrderShippingLabelByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageType: string # Page type. Options: 6A4, 10x10, 10x15. (default: 6A4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageType" $pageType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Order/Number/($number)/Shipping-label" $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get order shipping label by Id
#
# GET /Order/Id/{id}/Shipping-label
# operationId: GetOrderShippingLabelById
export def "order-id-shipping-label GetOrderShippingLabelById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageType: string # Page type. Options: 6A4, 10x10, 10x15. (default: 6A4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageType" $pageType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Order/Id/($id)/Shipping-label" $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the order status to 'delivered', 'collected', or 'partially' by number. Note: The order must be scheduled for delivery.
#
# PUT /Order/Number/{number}/Complete
# operationId: CompleteOrderByNumber
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
export def "order-number-complete CompleteOrderByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --CODActual: float # Actual cash on delivery (COD) (nullable, format: double, e.g. 10.5)
  --GoodsList: list # Optional (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)/Complete")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, CODActual: $CODActual, GoodsList: $GoodsList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the order status to 'delivered', 'collected', or 'partially' by Id. Note: The order must be scheduled for delivery.
#
# PUT /Order/Id/{id}/Complete
# operationId: CompleteOrderById
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
export def "order-id-complete CompleteOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --CODActual: float # Actual cash on delivery (COD) (nullable, format: double, e.g. 10.5)
  --GoodsList: list # Optional (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)/Complete")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, CODActual: $CODActual, GoodsList: $GoodsList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the order status to 'delivered', 'collected', or 'partially' by TrackId. Note: The order must be scheduled for delivery.
#
# PUT /Order/TrackId/{trackId}/Complete
# operationId: CompleteOrderByTrackId
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
export def "order-track-id-complete CompleteOrderByTrackId" [
  trackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --CODActual: float # Actual cash on delivery (COD) (nullable, format: double, e.g. 10.5)
  --GoodsList: list # Optional (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, QuantityFact?: float, GoodsRejectReasonId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/TrackId/($trackId)/Complete")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, CODActual: $CODActual, GoodsList: $GoodsList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the order status to 'not delivered' or 'not collected' by number. Note: The order must be scheduled for delivery.
#
# PUT /Order/Number/{number}/Reject
# operationId: RejectOrderByNumber
export def "order-number-reject RejectOrderByNumber" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --RejectReasonId: int # Reject Reason Id from OrderIssue or SiteIssue list of GET /RejectReason endpoint. (nullable, format: int32, e.g. 19)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Number/($number)/Reject")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, RejectReasonId: $RejectReasonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the order status to 'not delivered' or 'not collected' by Id. Note: The order must be scheduled for delivery.
#
# PUT /Order/Id/{id}/Reject
# operationId: RejectOrderById
export def "order-id-reject RejectOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --RejectReasonId: int # Reject Reason Id from OrderIssue or SiteIssue list of GET /RejectReason endpoint. (nullable, format: int32, e.g. 19)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/Id/($id)/Reject")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, RejectReasonId: $RejectReasonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the order status to 'not delivered' or 'not collected' by TrackId. Note: The order must be scheduled for delivery.
#
# PUT /Order/TrackId/{trackId}/Reject
# operationId: RejectOrderByTrackId
export def "order-track-id-reject RejectOrderByTrackId" [
  trackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StatusDate: string # Local date and time when the status changed, yyyy-MM-ddTHH:mm:ss. If empty, the default will be now UTC+0. (nullable, format: date-time, e.g. 2025-05-13T13:36:05)
  --DriverComment: string # Driver note (nullable, e.g. Closed from API)
  --SignatureName: string # Recipient's signature name on ePOD (nullable, e.g. John Dow)
  --RejectReasonId: int # Reject Reason Id from OrderIssue or SiteIssue list of GET /RejectReason endpoint. (nullable, format: int32, e.g. 19)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Order/TrackId/($trackId)/Reject")
  let body = {StatusDate: $StatusDate, DriverComment: $DriverComment, SignatureName: $SignatureName, RejectReasonId: $RejectReasonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get reasons for rejection list
#
# GET /RejectReason
# operationId: GetRejectReasonsList
export def "reject-reason GetRejectReasonsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<SiteIssue: table<Id: int, Name: string>, OrderIssue: table<Id: int, Name: string>, GoodsIssue: table<Id: int, Name: string>, ScanningIssues: table<Id: int, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RejectReason")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add route
#
# POST /Route
# operationId: AddRoute
# --Vehicle shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
# --Orders item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
# --CustomFields item shape: {Id?: string, Value?: string}
export def "route AddRoute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --update: string@bool-completer # Add or remove orders from the route if route already exists on this date. (default: false)
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --mergeAddresses: string@bool-completer # Merge orders by address onto one site (default: true)
  --updateGoodsPrice: string@bool-completer # Force update existing Price in the Goods directory from the payload data. (default: false)
  --Code: string # Route code/number (nullable, e.g. R0001234)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 1234)
  --Date: string # Route date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --StartTimePlan: string # Planned Start Time, yyyy-MM-ddTHH:mm:ss or HH:mm (nullable, format: date-time, e.g. 13:00)
  --DepotId: string # Unique identifier in user accounting system (nullable, e.g. 1)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA)
  --StartFromDepot: string@bool-completer # Start route from depot (nullable, e.g. true)
  --ReturnToDepot: string@bool-completer # Return to depot (nullable, e.g. true)
  --DriverLogin: string # Driver's login (nullable, e.g. RT567 )
  --DriverPassword: string # Driver’s password (nullable, e.g. 1)
  --DriverName: string # Driver’s First Name and Last Name (nullable, e.g. Peter G.)
  --DriverVehicle: string # Driver’s vehicle license plate number (nullable, e.g. FCU 819)
  --Vehicle: record # shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
  --Orders: list # nullable — item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update" $update "scalar") (serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "mergeAddresses" $mergeAddresses "scalar") (serialize-qp "updateGoodsPrice" $updateGoodsPrice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Route" $qp)
  let body = {Code: $Code, Id: $Id, Date: $Date, StartTimePlan: $StartTimePlan, DepotId: $DepotId, Depot: $Depot, StartFromDepot: $StartFromDepot, ReturnToDepot: $ReturnToDepot, DriverLogin: $DriverLogin, DriverPassword: $DriverPassword, DriverName: $DriverName, DriverVehicle: $DriverVehicle, Vehicle: $Vehicle, Orders: $Orders, CustomFields: $CustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update route by code
#
# PUT /Route/Code/{code}
# operationId: UpdateRouteByCode
# --Vehicle shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
# --Orders item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
# --CustomFields item shape: {Id?: string, Value?: string}
export def "route-code UpdateRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --mergeAddresses: string@bool-completer # Merge orders by address onto one site (default: true)
  --Code: string # Route code/number (nullable, e.g. R0001234)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 1234)
  --Date: string # Route date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --StartTimePlan: string # Planned Start Time, yyyy-MM-ddTHH:mm:ss or HH:mm (nullable, format: date-time, e.g. 13:00)
  --DepotId: string # Unique identifier in user accounting system (nullable, e.g. 1)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA)
  --StartFromDepot: string@bool-completer # Start route from depot (nullable, e.g. true)
  --ReturnToDepot: string@bool-completer # Return to depot (nullable, e.g. true)
  --DriverLogin: string # Driver's login (nullable, e.g. RT567 )
  --DriverPassword: string # Driver’s password (nullable, e.g. 1)
  --DriverName: string # Driver’s First Name and Last Name (nullable, e.g. Peter G.)
  --DriverVehicle: string # Driver’s vehicle license plate number (nullable, e.g. FCU 819)
  --Vehicle: record # shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
  --Orders: list # nullable — item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "mergeAddresses" $mergeAddresses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Code/($code)" $qp)
  let body = {Code: $Code, Id: $Id, Date: $Date, StartTimePlan: $StartTimePlan, DepotId: $DepotId, Depot: $Depot, StartFromDepot: $StartFromDepot, ReturnToDepot: $ReturnToDepot, DriverLogin: $DriverLogin, DriverPassword: $DriverPassword, DriverName: $DriverName, DriverVehicle: $DriverVehicle, Vehicle: $Vehicle, Orders: $Orders, CustomFields: $CustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get route by code
#
# GET /Route/Code/{code}
# operationId: GetRouteByCode
export def "route-code GetRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Code: string, Id: string, Date: string, DepotId: string, Depot: string, StartFromDepot: bool, ReturnToDepot: bool, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, StartDate: string, CloseDate: string, Track: float, Priority: int, LocationLat: float, LocationLon: float, StartTimePlan: string, FinishTimePlan: string, DistancePlan: float, CostPlan: float, CostActual: float, CreateDateUtc: string, Orders: table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list, PickupOrder: record, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, RescheduledTimes: int>, Status: string, Xd: bool, Vehicle: record<Number: string, CarrierCode: string, Carrier: string, Weight: float, Volume: float, Pallets: float>, CustomFields: table<Id: string, Label: string, Value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Code/($code)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete route by code.
#
# DELETE /Route/Code/{code}
# operationId: DeleteRouteByCode
export def "route-code DeleteRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --deleteOrders: string@bool-completer # default: true
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOrders" $deleteOrders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Code/($code)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update route by id
#
# PUT /Route/Id/{id}
# operationId: UpdateRouteById
# --Vehicle shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
# --Orders item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
# --CustomFields item shape: {Id?: string, Value?: string}
export def "route-id UpdateRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --mergeAddresses: string@bool-completer # Merge orders by address onto one site (default: true)
  --Code: string # Route code/number (nullable, e.g. R0001234)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 1234)
  --Date: string # Route date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --StartTimePlan: string # Planned Start Time, yyyy-MM-ddTHH:mm:ss or HH:mm (nullable, format: date-time, e.g. 13:00)
  --DepotId: string # Unique identifier in user accounting system (nullable, e.g. 1)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA)
  --StartFromDepot: string@bool-completer # Start route from depot (nullable, e.g. true)
  --ReturnToDepot: string@bool-completer # Return to depot (nullable, e.g. true)
  --DriverLogin: string # Driver's login (nullable, e.g. RT567 )
  --DriverPassword: string # Driver’s password (nullable, e.g. 1)
  --DriverName: string # Driver’s First Name and Last Name (nullable, e.g. Peter G.)
  --DriverVehicle: string # Driver’s vehicle license plate number (nullable, e.g. FCU 819)
  --Vehicle: record # shape: {Number?: string, CarrierCode?: string, Carrier?: string, Weight?: float, Volume?: float, Pallets?: float}
  --Orders: list # nullable — item shape: {Number?: string, Id?: string, Date?: string, Type?: int, Shipper?: string, Depot?: string, Client?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, Note?: string, ContactName?: string, Phone?: string, Email?: string, Weight?: float, Volume?: float, Pallets?: float, COD?: float, InvoiceId?: string, CustomerReferenceId?: string, Barcode?: string, ShipperId?: string, DepotId?: string, ClientId?: string, AddressId?: string, GoodsList?: list, CustomFields?: list, PickupOrder?: record, Priority?: string, TeamCode?: string, NotificationsPolicy?: record}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "mergeAddresses" $mergeAddresses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Id/($id)" $qp)
  let body = {Code: $Code, Id: $Id, Date: $Date, StartTimePlan: $StartTimePlan, DepotId: $DepotId, Depot: $Depot, StartFromDepot: $StartFromDepot, ReturnToDepot: $ReturnToDepot, DriverLogin: $DriverLogin, DriverPassword: $DriverPassword, DriverName: $DriverName, DriverVehicle: $DriverVehicle, Vehicle: $Vehicle, Orders: $Orders, CustomFields: $CustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get route by id
#
# GET /Route/Id/{id}
# operationId: GetRouteById
export def "route-id GetRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Code: string, Id: string, Date: string, DepotId: string, Depot: string, StartFromDepot: bool, ReturnToDepot: bool, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, StartDate: string, CloseDate: string, Track: float, Priority: int, LocationLat: float, LocationLon: float, StartTimePlan: string, FinishTimePlan: string, DistancePlan: float, CostPlan: float, CostActual: float, CreateDateUtc: string, Orders: table<Number: string, Id: string, Date: string, SeqNumber: int, RouteNumber: string, RoutePriority: int, RouteStatus: string, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, ShipperId: string, Shipper: string, DepotId: string, Depot: string, Weight: float, Volume: float, Pallets: float, InvoiceId: string, CustomerReferenceId: string, GoodsList: list, PickupOrder: record, CreateSource: string, DistanceFromDepotPlan: float, SeqNumberDriver: int, DeliveryInstructions: string, Pin: string, AddressNote: string, ClientNote: string, CreateDateUtc: string, Priority: string, TeamCode: string, Feedback: string, NotificationsPolicy: record, RouteDate: string, Type: int, ClientId: string, Client: string, AddressId: string, Address: string, AddressLat: float, AddressLon: float, AddressZone: string, TimeSlotFrom: string, TimeSlotTo: string, ServiceTime: float, Note: string, ContactName: string, Phone: string, Email: string, COD: float, CODActual: string, StatusId: int, Status: string, StatusLat: float, StatusLon: float, DriverComment: string, RejectReason: string, LoadCheckScanRejectReason: string, ScanRejectReason: string, SignatureName: string, HasSignaturePhoto: bool, SignaturePhotos: list, HasPhoto: bool, Photos: list, StatusDate: string, ETA: string, UpdatedETA: string, ArrivedDate: string, DepartedDate: string, ReportUrl: string, CustomFields: list, Barcode: string, Scanned: bool, FeedbackRating: float, TrackKey: string, TrackId: string, TrackLink: string, LoadStatus: string, LoadDate: string, LoadSignaturePhotos: list, ChangeDate: string, RescheduledTimes: int>, Status: string, Xd: bool, Vehicle: record<Number: string, CarrierCode: string, Carrier: string, Weight: float, Volume: float, Pallets: float>, CustomFields: table<Id: string, Label: string, Value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete route by id.
#
# DELETE /Route/Id/{id}
# operationId: DeleteRouteById
export def "route-id DeleteRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --deleteOrders: string@bool-completer # default: true
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOrders" $deleteOrders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Id/($id)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update routes custom fields by route code
#
# PATCH /Route/Code/{code}/CustomFields
# operationId: UpdateRouteCustomValuesByCode
export def "route-code-custom-fields UpdateRouteCustomValuesByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Code/($code)/CustomFields")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update routes custom fields by route id
#
# PATCH /Route/Id/{id}/CustomFields
# operationId: UpdateRouteCustomValuesById
export def "route-id-custom-fields UpdateRouteCustomValuesById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Id/($id)/CustomFields")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get routes by date
#
# GET /Route/Date/{date}
# operationId: GetRouteByDate
export def "route-date GetRouteByDate" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<Code: string, Id: string, Date: string, DepotId: string, Depot: string, StartFromDepot: bool, ReturnToDepot: bool, DriverLogin: string, DriverName: string, DriverNumber: int, DriverVehicle: string, StartDate: string, CloseDate: string, Track: float, Priority: int, LocationLat: float, LocationLon: float, StartTimePlan: string, FinishTimePlan: string, DistancePlan: float, CostPlan: float, CostActual: float, CreateDateUtc: string, Orders: list<record>, Status: string, Xd: bool, Vehicle: record<Number: string, CarrierCode: string, Carrier: string, Weight: float, Volume: float, Pallets: float>, CustomFields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get route codes for export (exported is False)
#
# GET /Route/Export/Code
# operationId: GetRouteExportCode
export def "route-export-code GetRouteExportCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: int # Routes status: 0 - Ready; 5 - Closed (format: int32, default: 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Route/Export/Code" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get route ids for export (exported is False)
#
# GET /Route/Export/Id
# operationId: GetRouteExportId
export def "route-export-id GetRouteExportId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: int # Routes status: 0 - Ready; 5 - Closed (format: int32, default: 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Route/Export/Id" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm route export (set exported to True) by code
#
# PUT /Route/Export/Code/{code}
# operationId: SetRouteExportCode
export def "route-export-code SetRouteExportCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Export/Code/($code)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm route export (set exported to True) by id
#
# PUT /Route/Export/Id/{id}
# operationId: SetRouteExportId
export def "route-export-id SetRouteExportId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Export/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new order to route
#
# PUT /Route/Code/{code}/Order
# operationId: AddOrderToRouteByCode
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
# --CustomFields item shape: {Id?: string, Value?: string}
# --PickupOrder shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
# --NotificationsPolicy shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
export def "route-code-order AddOrderToRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --mergeAddresses: string@bool-completer # Merge orders by address onto one site (default: true)
  --Number: string # Order/Invoice/Job/Waybill number (nullable, e.g. cv30001-2)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 10000345)
  --Date: string # Order date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --Type: int # Order type: 0 - Delivery order; 1 - Collection order (format: int32, e.g. 0)
  --Shipper: string # Shipper/Supplier name (nullable, e.g. Sanitex)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --Client: string # Required (*)   Client/Customer name (nullable, e.g. Maxima)
  --Address: string # Required (*)   Delivery/Pickup address. Address cannot be updated for orders planned into routes (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --AddressLat: float # Address GPS Latitude (nullable, format: double, e.g. 25.290479)
  --AddressLon: float # Address GPS Longitude (nullable, format: double, e.g. 65.294049)
  --AddressZone: string # Address zone (nullable, e.g. Zone 1)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
  --ServiceTime: float # Service Time, min. If seconds are specified value will be decimal (nullable, format: double, e.g. 10)
  --Note: string # Notes to order (nullable, e.g. Only to sign Invoice)
  --ContactName: string # Customer’s contact name (nullable, e.g. John Doe)
  --Phone: string # Customer’s contact phone number (nullable, e.g. +37061191244)
  --Email: string # Customer’s e-mail (nullable, e.g. X-604@maxima.com)
  --Weight: float # Total weight (nullable, format: double, e.g. 50.5)
  --Volume: float # Total volume (nullable, format: double, e.g. 8.54)
  --Pallets: float # Pallets count (nullable, format: double, e.g. 3.5)
  --COD: float # Amount of Cash on Delivery (nullable, format: double, e.g. 20.45)
  --InvoiceId: string # Invoice identifier in user accounting system (nullable, e.g. inv0002 )
  --CustomerReferenceId: string # Customer reference order identifier in user accounting system (nullable, e.g. ord123/1)
  --Barcode: string # Barcode for scanning in the mobile application (nullable, e.g. 1234567890123)
  --ShipperId: string # Optional, unique identifier in user accounting system for shipper directory (nullable, e.g. 357)
  --DepotId: string # Optional, unique identifier in user accounting system for depot directory (nullable, e.g. 1)
  --ClientId: string # Optional, unique identifier in user accounting system for client directory (nullable, e.g. 247)
  --AddressId: string # Optional, unique identifier in user accounting system for address directory (nullable, e.g. 13587)
  --GoodsList: list # Goods List in Order (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
  --PickupOrder: record # shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
  --Priority: string # Priority Possible values: low, normal, high (nullable)
  --TeamCode: string # Team code (nullable)
  --NotificationsPolicy: record # shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "mergeAddresses" $mergeAddresses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Code/($code)/Order" $qp)
  let body = {Number: $Number, Id: $Id, Date: $Date, Type: $Type, Shipper: $Shipper, Depot: $Depot, Client: $Client, Address: $Address, AddressLat: $AddressLat, AddressLon: $AddressLon, AddressZone: $AddressZone, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo, ServiceTime: $ServiceTime, Note: $Note, ContactName: $ContactName, Phone: $Phone, Email: $Email, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, COD: $COD, InvoiceId: $InvoiceId, CustomerReferenceId: $CustomerReferenceId, Barcode: $Barcode, ShipperId: $ShipperId, DepotId: $DepotId, ClientId: $ClientId, AddressId: $AddressId, GoodsList: $GoodsList, CustomFields: $CustomFields, PickupOrder: $PickupOrder, Priority: $Priority, TeamCode: $TeamCode, NotificationsPolicy: $NotificationsPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add new order to route
#
# PUT /Route/Id/{id}/Order
# operationId: AddOrderToRouteById
# --GoodsList item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
# --CustomFields item shape: {Id?: string, Value?: string}
# --PickupOrder shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
# --NotificationsPolicy shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
export def "route-id-order AddOrderToRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --updateAddressGps: string@bool-completer # Force update existing Lat/Lon in the Addresses directory from the payload data. (default: false)
  --mergeAddresses: string@bool-completer # Merge orders by address onto one site (default: true)
  --Number: string # Order/Invoice/Job/Waybill number (nullable, e.g. cv30001-2)
  --Id: string # Unique identifier in user accounting system (nullable, e.g. 10000345)
  --Date: string # Order date, yyyy-MM-dd (nullable, format: date-time, e.g. 2019-02-01)
  --Type: int # Order type: 0 - Delivery order; 1 - Collection order (format: int32, e.g. 0)
  --Shipper: string # Shipper/Supplier name (nullable, e.g. Sanitex)
  --Depot: string # Depot address (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --Client: string # Required (*)   Client/Customer name (nullable, e.g. Maxima)
  --Address: string # Required (*)   Delivery/Pickup address. Address cannot be updated for orders planned into routes (nullable, e.g. 2 St Josephs Crescent, Liverpool L3 3JF)
  --AddressLat: float # Address GPS Latitude (nullable, format: double, e.g. 25.290479)
  --AddressLon: float # Address GPS Longitude (nullable, format: double, e.g. 65.294049)
  --AddressZone: string # Address zone (nullable, e.g. Zone 1)
  --TimeSlotFrom: string # Desired delivery/pickup time from, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T09:00:00)
  --TimeSlotTo: string # Desired delivery/pickup time till, yyyy-MM-ddTHH:mm:ss or HH:mm:ss (nullable, format: date-time, e.g. 2019-02-01T18:00:00)
  --ServiceTime: float # Service Time, min. If seconds are specified value will be decimal (nullable, format: double, e.g. 10)
  --Note: string # Notes to order (nullable, e.g. Only to sign Invoice)
  --ContactName: string # Customer’s contact name (nullable, e.g. John Doe)
  --Phone: string # Customer’s contact phone number (nullable, e.g. +37061191244)
  --Email: string # Customer’s e-mail (nullable, e.g. X-604@maxima.com)
  --Weight: float # Total weight (nullable, format: double, e.g. 50.5)
  --Volume: float # Total volume (nullable, format: double, e.g. 8.54)
  --Pallets: float # Pallets count (nullable, format: double, e.g. 3.5)
  --COD: float # Amount of Cash on Delivery (nullable, format: double, e.g. 20.45)
  --InvoiceId: string # Invoice identifier in user accounting system (nullable, e.g. inv0002 )
  --CustomerReferenceId: string # Customer reference order identifier in user accounting system (nullable, e.g. ord123/1)
  --Barcode: string # Barcode for scanning in the mobile application (nullable, e.g. 1234567890123)
  --ShipperId: string # Optional, unique identifier in user accounting system for shipper directory (nullable, e.g. 357)
  --DepotId: string # Optional, unique identifier in user accounting system for depot directory (nullable, e.g. 1)
  --ClientId: string # Optional, unique identifier in user accounting system for client directory (nullable, e.g. 247)
  --AddressId: string # Optional, unique identifier in user accounting system for address directory (nullable, e.g. 13587)
  --GoodsList: list # Goods List in Order (nullable) — item shape: {OrderLineId?: string, GoodsId?: string, GoodsName?: string, GoodsUnit?: string, Note?: string, Quantity?: float, Cost?: float, OrderLineBarcode?: string, GoodsBarcode?: string}
  --CustomFields: list # Custom Fields (nullable) — item shape: {Id?: string, Value?: string}
  --PickupOrder: record # shape: {ClientId?: string, Client?: string, AddressId?: string, Address?: string, AddressLat?: float, AddressLon?: float, AddressZone?: string, ContactName?: string, Phone?: string, Email?: string, TimeSlotFrom?: string, TimeSlotTo?: string, ServiceTime?: float, CustomFields?: list, COD?: float, Note?: string}
  --Priority: string # Priority Possible values: low, normal, high (nullable)
  --TeamCode: string # Team code (nullable)
  --NotificationsPolicy: record # shape: {PriorToRouteNotificationEnabled?: bool, AtRouteStartNotificationEnabled?: bool, EnRouteNotificationEnabled?: bool, AtDepartureNotificationEnabled?: bool}
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateAddressGps" $updateAddressGps "scalar") (serialize-qp "mergeAddresses" $mergeAddresses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Id/($id)/Order" $qp)
  let body = {Number: $Number, Id: $Id, Date: $Date, Type: $Type, Shipper: $Shipper, Depot: $Depot, Client: $Client, Address: $Address, AddressLat: $AddressLat, AddressLon: $AddressLon, AddressZone: $AddressZone, TimeSlotFrom: $TimeSlotFrom, TimeSlotTo: $TimeSlotTo, ServiceTime: $ServiceTime, Note: $Note, ContactName: $ContactName, Phone: $Phone, Email: $Email, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, COD: $COD, InvoiceId: $InvoiceId, CustomerReferenceId: $CustomerReferenceId, Barcode: $Barcode, ShipperId: $ShipperId, DepotId: $DepotId, ClientId: $ClientId, AddressId: $AddressId, GoodsList: $GoodsList, CustomFields: $CustomFields, PickupOrder: $PickupOrder, Priority: $Priority, TeamCode: $TeamCode, NotificationsPolicy: $NotificationsPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add existing order to route
#
# PUT /Route/Code/{code}/Order/Number/{number}
# operationId: MoveOrderToRouteByCodeByNumber
export def "route-code-order-number MoveOrderToRouteByCodeByNumber" [
  code: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --allowTransfer: string@bool-completer # If true allows transferring order (without delivery status) from another route (default: false)
  --allowReschedule: string@bool-completer # If true allows rescheduling, transferring order (with failed delivery status) from another route and clears old status (default: false)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowTransfer" $allowTransfer "scalar") (serialize-qp "allowReschedule" $allowReschedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Code/($code)/Order/Number/($number)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add existing order to route
#
# PUT /Route/Code/{code}/Order/Id/{orderId}
# operationId: MoveOrderToRouteByCodeById
export def "route-code-order-id MoveOrderToRouteByCodeById" [
  code: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --allowTransfer: string@bool-completer # If true allows transferring order (without delivery status) from another route (default: false)
  --allowReschedule: string@bool-completer # If true allows rescheduling, transferring order (with failed delivery status) from another route and clears old status (default: false)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowTransfer" $allowTransfer "scalar") (serialize-qp "allowReschedule" $allowReschedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Code/($code)/Order/Id/($orderId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add existing order to route
#
# PUT /Route/Id/{id}/Order/Number/{number}
# operationId: MoveOrderToRouteByIdByNumber
export def "route-id-order-number MoveOrderToRouteByIdByNumber" [
  id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --allowTransfer: string@bool-completer # If true allows transferring order (without delivery status) from another route (default: false)
  --allowReschedule: string@bool-completer # If true allows rescheduling, transferring order (with failed delivery status) from another route and clears old status (default: false)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowTransfer" $allowTransfer "scalar") (serialize-qp "allowReschedule" $allowReschedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Id/($id)/Order/Number/($number)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add existing order to route
#
# PUT /Route/Id/{id}/Order/Id/{orderId}
# operationId: MoveOrderToRouteByIdById
export def "route-id-order-id MoveOrderToRouteByIdById" [
  id: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --allowTransfer: string@bool-completer # If true allows transferring order (without delivery status) from another route (default: false)
  --allowReschedule: string@bool-completer # If true allows rescheduling, transferring order (with failed delivery status) from another route and clears old status (default: false)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowTransfer" $allowTransfer "scalar") (serialize-qp "allowReschedule" $allowReschedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Id/($id)/Order/Id/($orderId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get route track by code
#
# GET /Route/Track/Code/{code}
# operationId: GetRouteTrackByCode
export def "route-track-code GetRouteTrackByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<TrackPoints: table<Lat: float, Lng: float, Speed: float, Date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Track/Code/($code)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get route track by id
#
# GET /Route/Track/Id/{id}
# operationId: GetRouteTrackById
export def "route-track-id GetRouteTrackById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<TrackPoints: table<Lat: float, Lng: float, Speed: float, Date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Route/Track/Id/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start route by code
#
# PUT /Route/Start/Code/{code}
# operationId: StartRouteByCode
export def "route-start-code StartRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # Status date (client's local date and time) (format: date-time)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Start/Code/($code)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start route by id.
#
# PUT /Route/Start/Id/{id}
# operationId: StartRouteById
export def "route-start-id StartRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # format: date-time
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Start/Id/($id)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close route by code
#
# PUT /Route/Close/Code/{code}
# operationId: CloseRouteByCode
export def "route-close-code CloseRouteByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # Status date (client's local date and time) (format: date-time)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Close/Code/($code)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close route by id.
#
# PUT /Route/Close/Id/{id}
# operationId: CloseRouteById
export def "route-close-id CloseRouteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # format: date-time
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Close/Id/($id)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set route ready by code.
#
# PUT /Route/Ready/Code/{code}
# operationId: SetRouteReadyByCode
export def "route-ready-code SetRouteReadyByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # Status date (client's local date and time) (format: date-time)
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Ready/Code/($code)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set route ready by id.
#
# PUT /Route/Ready/Id/{id}
# operationId: SetRouteReadyById
export def "route-ready-id SetRouteReadyById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --statusDate: string # format: date-time
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusDate" $statusDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Route/Ready/Id/($id)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test authorization and rate limits
#
# GET /Test
# operationId: Test
export def "test Test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Test")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vehicle by Track-POD unique identifier
#
# GET /Vehicle/{id}
# operationId: GetVehicle
export def "vehicle GetVehicle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Id: int, DriverId: string, DriverUsername: string, DepotId: string, Depot: string, MaxNodes: int, MaxWorkTime: int, MaxDistance: int, SpeedRatio: float, CostPerDistance: float, CostPerHour: float, BaseFare: float, StartTime: string, VehicleType: int, EmissionCo2: int, Number: string, CarrierCode: string, Carrier: string, Weight: float, Volume: float, Pallets: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Vehicle/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete vehicle by Track-POD unique identifier
#
# DELETE /Vehicle/{id}
# operationId: DeleteVehicle
export def "vehicle DeleteVehicle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<Status: int, Title: string, Detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Vehicle/($id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vehicles
#
# GET /Vehicle
# operationId: GetVehicles
export def "vehicle GetVehicles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --number: string
]: nothing -> table<Id: int, DriverId: string, DriverUsername: string, DepotId: string, Depot: string, MaxNodes: int, MaxWorkTime: int, MaxDistance: int, SpeedRatio: float, CostPerDistance: float, CostPerHour: float, BaseFare: float, StartTime: string, VehicleType: int, EmissionCo2: int, Number: string, CarrierCode: string, Carrier: string, Weight: float, Volume: float, Pallets: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Vehicle" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add vehicle
#
# POST /Vehicle
# operationId: AddVehicle
export def "vehicle AddVehicle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Number: string # Required (*)   Number (nullable, e.g. XXX777)
  --CarrierCode: string # Carrier Code (nullable, e.g. 31)
  --Carrier: string # Carrier (nullable, e.g. Big Logistics)
  --Weight: float # Capacity Weight (nullable, format: double, e.g. 100)
  --Volume: float # Capacity Volume (nullable, format: double, e.g. 14.5)
  --Pallets: float # Capacity Pallets (nullable, format: double, e.g. 16)
  --DriverId: string # Required (*)   Driver's Track-POD unique identifier (DriverId or DriverUsername is Required) (nullable, format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --DriverUsername: string # Required (*)   Driver's username (DriverId or DriverUsername is Required) (nullable, e.g. MyDriver)
  --DepotId: string # Required (*)   Unique identifier in user accounting system (DepotId or Depot is Required) (nullable, e.g. 1)
  --Depot: string # Required (*)   Depot address (DepotId or Depot is Required) (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --MaxNodes: int # Maximum number of sites/orders (nullable, format: int32, e.g. 5)
  --MaxWorkTime: int # Maximum work time, h (nullable, format: int32, e.g. 8)
  --MaxDistance: int # Maximum distance, km (nullable, format: int32, e.g. 1000)
  --SpeedRatio: float # Speed ratio restriction (should be grater than 0 and less or equal 2) (nullable, format: double, e.g. 1)
  --CostPerDistance: float # Cost per distance (km) (nullable, format: double, e.g. 1.1)
  --CostPerHour: float # Cost per hour (nullable, format: double, e.g. 10)
  --BaseFare: float # Base fare (nullable, format: double, e.g. 0)
  --StartTime: string # Start time (nullable, format: date-span, e.g. 08:00:00)
  --VehicleType: int # Vehicle type: 0 - Truck/Car, 1 - Motorcycle, 2 - Bicycle (nullable, format: int32, e.g. 1)
  --EmissionCo2: int # Vehicle emission g/km or g/mile (nullable, format: int32, e.g. 250)
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Vehicle")
  let body = {Number: $Number, CarrierCode: $CarrierCode, Carrier: $Carrier, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, DriverId: $DriverId, DriverUsername: $DriverUsername, DepotId: $DepotId, Depot: $Depot, MaxNodes: $MaxNodes, MaxWorkTime: $MaxWorkTime, MaxDistance: $MaxDistance, SpeedRatio: $SpeedRatio, CostPerDistance: $CostPerDistance, CostPerHour: $CostPerHour, BaseFare: $BaseFare, StartTime: $StartTime, VehicleType: $VehicleType, EmissionCo2: $EmissionCo2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update vehicle
#
# PUT /Vehicle
# operationId: UpdateVehicle
export def "vehicle UpdateVehicle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Id: int # Track-POD unique identifier (format: int32, e.g. 2341)
  --Number: string # Required (*)   Number (nullable, e.g. XXX777)
  --CarrierCode: string # Carrier Code (nullable, e.g. 31)
  --Carrier: string # Carrier (nullable, e.g. Big Logistics)
  --Weight: float # Capacity Weight (nullable, format: double, e.g. 100)
  --Volume: float # Capacity Volume (nullable, format: double, e.g. 14.5)
  --Pallets: float # Capacity Pallets (nullable, format: double, e.g. 16)
  --DriverId: string # Required (*)   Driver's Track-POD unique identifier (DriverId or DriverUsername is Required) (nullable, format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --DriverUsername: string # Required (*)   Driver's username (DriverId or DriverUsername is Required) (nullable, e.g. MyDriver)
  --DepotId: string # Required (*)   Unique identifier in user accounting system (DepotId or Depot is Required) (nullable, e.g. 1)
  --Depot: string # Required (*)   Depot address (DepotId or Depot is Required) (nullable, e.g. 9 Riverside, Salford M7 1PA )
  --MaxNodes: int # Maximum number of sites/orders (nullable, format: int32, e.g. 5)
  --MaxWorkTime: int # Maximum work time, h (nullable, format: int32, e.g. 8)
  --MaxDistance: int # Maximum distance, km (nullable, format: int32, e.g. 1000)
  --SpeedRatio: float # Speed ratio restriction (should be grater than 0 and less or equal 2) (nullable, format: double, e.g. 1)
  --CostPerDistance: float # Cost per distance (km) (nullable, format: double, e.g. 1.1)
  --CostPerHour: float # Cost per hour (nullable, format: double, e.g. 10)
  --BaseFare: float # Base fare (nullable, format: double, e.g. 0)
  --StartTime: string # Start time (nullable, format: date-span, e.g. 08:00:00)
  --VehicleType: int # Vehicle type: 0 - Truck/Car, 1 - Motorcycle, 2 - Bicycle (nullable, format: int32, e.g. 1)
  --EmissionCo2: int # Vehicle emission g/km or g/mile (nullable, format: int32, e.g. 250)
]: any -> record<Status: int, Title: string, Detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Vehicle")
  let body = {Id: $Id, Number: $Number, CarrierCode: $CarrierCode, Carrier: $Carrier, Weight: $Weight, Volume: $Volume, Pallets: $Pallets, DriverId: $DriverId, DriverUsername: $DriverUsername, DepotId: $DepotId, Depot: $Depot, MaxNodes: $MaxNodes, MaxWorkTime: $MaxWorkTime, MaxDistance: $MaxDistance, SpeedRatio: $SpeedRatio, CostPerDistance: $CostPerDistance, CostPerHour: $CostPerHour, BaseFare: $BaseFare, StartTime: $StartTime, VehicleType: $VehicleType, EmissionCo2: $EmissionCo2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get last vehicle check by number
#
# GET /VehicleCheck/{number}
# operationId: GetCheckByVehicle
export def "vehicle-check GetCheckByVehicle" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<DriverLogin: string, DriverName: string, DepotId: string, Depot: string, Date: string, VehicleNumber: string, Odometer: float, Values: table<Label: string, Status: bool, Photo: bool, Photos: list, Note: string, Value: float>, HasSignature: bool, SignaturePhoto: string, Stage: string, RouteNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/VehicleCheck/($number)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vehicle checks by date
#
# GET /VehicleCheck/Number/{number}/Date/{date}
# operationId: GetChecksByVehicle
export def "vehicle-check-number-date GetChecksByVehicle" [
  number: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<DriverLogin: string, DriverName: string, DepotId: string, Depot: string, Date: string, VehicleNumber: string, Odometer: float, Values: list<record>, HasSignature: bool, SignaturePhoto: string, Stage: string, RouteNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/VehicleCheck/Number/($number)/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vehicle checks by date
#
# GET /VehicleCheck/Date/{date}
# operationId: GetVehicleChecksByDate
export def "vehicle-check-date GetVehicleChecksByDate" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<DriverLogin: string, DriverName: string, DepotId: string, Depot: string, Date: string, VehicleNumber: string, Odometer: float, Values: list<record>, HasSignature: bool, SignaturePhoto: string, Stage: string, RouteNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/VehicleCheck/Date/($date)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
