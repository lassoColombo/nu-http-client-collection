# Auto-generated client for smart-me vv1
# Source: https://api.apis.guru/v2/specs/smart-me.com/v1/openapi.json
# Auth: --token flag or $env.SMART_ME_TOKEN

const BASE_URL = "https://smart-me.com:443"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SMART_ME_TOKEN | default "" }
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

def base-url-completer [] { ["https://smart-me.com:443"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def device-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def meter-sub-type-completer [] { ["MeterSubTypeChargingStation" "MeterSubTypeCold" "MeterSubTypeElectricity" "MeterSubTypeElectricityHeat" "MeterSubTypeGas" "MeterSubTypeHeat" "MeterSubTypeTemperature" "MeterSubTypeUnknown" "MeterSubTypeVirtualBattery" "MeterSubTypeWater"] }
def meter-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def registration-type-completer [] { ["Disabled" "SingleMeterRegistration" "UserRegistration"] }
def dns-update-state-completer [] { ["DnsUpdateInternalIp" "DnsUpdatePublicIp" "NoUpdate"] }
def upload-interval-completer [] { ["UploadInterval_10s" "UploadInterval_12h" "UploadInterval_15min" "UploadInterval_1s" "UploadInterval_24h" "UploadInterval_30min" "UploadInterval_30s" "UploadInterval_5min" "UploadInterval_5s" "UploadInterval_60min" "UploadInterval_60s" "UploadInterval_6h"] }
def permission-level-completer [] { ["SelectedFolderAndSubfoldersMeters" "SelectedFolderOnly"] }
def folder-type-completer [] { ["Car" "ChargingStation" "Coffee" "ElecticityFolder" "Factory" "Folder" "Food" "GasFolder" "GridPhotovoltaicPowerSystem" "HeatFolder" "House" "Ice" "Light" "Location" "Machine" "Meter" "Office" "Sofa" "Sun" "TemperatureFolder" "Trash" "User" "VirtualMeter" "WaterFolder"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-token update" } } | get name | first)
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

# Creates a Access Token to write on a Card (e.g. NFC)
#
# PUT /api/AccessToken
# operationId: AccessToken_Put
export def "access-token update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --card-id: int # The ID of the Card (format: int64)
  --user-id: int # The ID of the User. The credentials provided must have permission to edit the user.             If no ID is provided, the user in the credentials is taken. (format: int64)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/AccessToken")
  let body = {"CardId": $card_id, "UserId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/Account/login
#
# operationId: Account_Login
export def "account-login get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account/login")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/Account/login
export def "account-login post" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account/login")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set an action for the specified device.
#
# POST /api/Actions
# operationId: Actions_Post
# --Actions item shape: {ObisCode?: string, Value?: float}
export def "actions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list # List with all Actions for this device — item shape: {ObisCode?: string, Value?: float}
  --device-id: string # The ID of the Device
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Actions")
  let body = {"Actions": $actions, "DeviceID": $device_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all available Actions of a Device
#
# GET /api/Actions/{id}
# operationId: Actions_Get
export def "actions get" [
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
]: nothing -> table<ActionType: string, MaxValue: float, MinValue: float, Name: string, ObisCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/Actions/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the additional information (e.g. Firmware Version) about a device.
#
# GET /api/AdditionalDeviceInformation/{id}
# operationId: AdditionalDeviceInformation_Get
export def "additional-device-information get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<AdditionalMeterSerialNumber: string, FirmwareVersion: int, HardwareVersion: int, ID: string, NetworkConnection: string, NetworkConnectionRSSI: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/AdditionalDeviceInformation/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Custom Devices
#
# GET /api/CustomDevice
# operationId: CustomDevice_Get
export def "custom-device list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Id: string, Name: string, Serial: int, ValueDate: string, Values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CustomDevice")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a Custom Device or updates it's values.
#
# POST /api/CustomDevice
# operationId: CustomDevice_Post
# --Values item shape: {Name?: string, Value?: float}
export def "custom-device create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The ID of the device
  --name: string # The Name of the Device
  --serial: int # The Serial number (format: int64)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --values: list # The Values of the custom Device — item shape: {Name?: string, Value?: float}
]: any -> record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CustomDevice")
  let body = {"Id": $id, "Name": $name, "Serial": $serial, "ValueDate": $value_date, "Values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a Custom Device by it's ID
#
# GET /api/CustomDevice/{id}
export def "custom-device get" [
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
]: nothing -> record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/CustomDevice/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Device by it's Serial Number. The Serial is the part before the "-".
#
# GET /api/DeviceBySerial
# operationId: DeviceBySerial_Get
export def "device-by-serial get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serial: int # The Serial Number of the device (format: int64)
]: nothing -> record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serial" $serial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DeviceBySerial" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Devices
#
# GET /api/Devices
# operationId: Devices_Get
export def "devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Devices")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a Device or updates it's values.
#
# POST /api/Devices
# operationId: Devices_Post
export def "devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-power: float # The Active Power or current flow rate. In kW or m3/h (format: double)
  --counter-reading: float # The Meter Counter Reading (Total Energy used) in kWh or m3. (format: double)
  --counter-reading-export: float # The Meter Counter Reading only export (format: double)
  --counter-reading-export-t1: float # The Meter Counter Reading only export (Tariff 1) (format: double)
  --counter-reading-export-t2: float # The Meter Counter Reading only export (Tariff 2) (format: double)
  --counter-reading-t1: float # The Meter Counter Reading Tariff 1 in kWh or m3. (format: double)
  --counter-reading-t2: float # The Meter Counter Reading Tariff 2 in kWh or m3. (format: double)
  --current: float # The Current (in A) (format: double)
  --current-l1: float # The Current Phase L1 (in A) (format: double)
  --current-l2: float # The Current Phase L2 (in A) (format: double)
  --current-l3: float # The Current Phase L3 (in A) (format: double)
  --device-energy-type: string@device-energy-type-completer # The Energy Type of this device
  --digital-input1: oneof<nothing, bool> # The digital input number 1
  --id: string # The ID of the device
  --meter-sub-type: string@meter-sub-type-completer # The Sub Type of this Meter.
  --name: string # The Name of the Device
  --power-factor: float # The Power Factor (cos phi). Range: 0 - 1 (format: double)
  --power-factor-l1: float # The Power Factor (cos phi) Phase L1. Range: 0 - 1 (format: double)
  --power-factor-l2: float # The Power Factor (cos phi) Phase L2. Range: 0 - 1 (format: double)
  --power-factor-l3: float # The Power Factor (cos phi) Phase L3. Range: 0 - 1 (format: double)
  --serial: int # The Serial number (format: int64)
  --temperature: float # The Temperature (in degree celsius) (format: double)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --voltage: float # The Voltage (in V) (format: double)
  --voltage-l1: float # The Voltage Phase L1 (in V) (format: double)
  --voltage-l2: float # The Voltage Phase L2 (in V) (format: double)
  --voltage-l3: float # The Voltage Phase L3 (in V) (format: double)
]: any -> record<ActivePower: float, CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingT1: float, CounterReadingT2: float, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Devices")
  let body = {"ActivePower": $active_power, "CounterReading": $counter_reading, "CounterReadingExport": $counter_reading_export, "CounterReadingExportT1": $counter_reading_export_t1, "CounterReadingExportT2": $counter_reading_export_t2, "CounterReadingT1": $counter_reading_t1, "CounterReadingT2": $counter_reading_t2, "Current": $current, "CurrentL1": $current_l1, "CurrentL2": $current_l2, "CurrentL3": $current_l3, "DeviceEnergyType": $device_energy_type, "DigitalInput1": $digital_input1, "Id": $id, "MeterSubType": $meter_sub_type, "Name": $name, "PowerFactor": $power_factor, "PowerFactorL1": $power_factor_l1, "PowerFactorL2": $power_factor_l2, "PowerFactorL3": $power_factor_l3, "Serial": $serial, "Temperature": $temperature, "ValueDate": $value_date, "Voltage": $voltage, "VoltageL1": $voltage_l1, "VoltageL2": $voltage_l2, "VoltageL3": $voltage_l3} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a Device by it's ID
#
# GET /api/Devices/{id}
export def "devices get" [
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
]: nothing -> record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/Devices/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the On/Off Switch on a device.              For new implementations please use the "actions" command
#
# PUT /api/Devices/{id}
# operationId: Devices_Put
export def "devices update" [
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
  --switch-state: oneof<nothing, bool> # The new state of the switch
  --switch-number: int # The number of the switch if there are multiple (1 for L1, 3 for L3) (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "switchState" $switch_state "scalar") (serialize-qp "switchNumber" $switch_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/Devices/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Devices for an Energy Type
#
# GET /api/DevicesByEnergy
# operationId: DevicesByEnergy_Get
export def "devices-by-energy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meter-energy-type: string@meter-energy-type-completer
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meterEnergyType" $meter_energy_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesByEnergy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Devices by it's Sub Type (e.g. E-Charging Station)
#
# GET /api/DevicesBySubType
# operationId: DevicesBySubType_Get
export def "devices-by-sub-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meter-sub-type: string@meter-sub-type-completer
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meterSubType" $meter_sub_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesBySubType" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force a device to send the data every second (if supported). This for about 30s.             Don't use this call to force a device to send the data every second for a longer time.
#
# GET /api/FastSendDeviceValues/{id}
# operationId: FastSendDeviceValues_Get
export def "fast-send-device-values get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/FastSendDeviceValues/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Values for a folder or a meter
#
# GET /api/Folder/{id}
# operationId: Folder_Get
export def "folder get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<ElectricityCounterValue: float, ElectricityPower: float, GasCounterValue: float, GasFlowRate: float, HeatCounterValue: float, HeatPower: float, WaterCounterValue: float, WaterFlowRate: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/Folder/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the folder menu items (each item might contain child items)
#
# GET /api/FolderMenu
# operationId: FolderMenu_Get
export def "folder-menu get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # (optional) Filter for the folders and meters:              all: load everything             assigned: load only folders and meters that are assigend to a folder             unassigend: load only meters that are not assigend to a folder             user: load only folder and all users assigned to this folders             subuserlist: load all subusers as a list
]: nothing -> record<BrowserTimeZoneName: string, BrowserUtcTime: string, Items: table<AutoExportSettings: record, Children: list, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FolderMenu" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates and updates the folder menu items
#
# POST /api/FolderMenu
# operationId: FolderMenu_Post
# --Items item shape: {AutoExportSettings?: record, Children?: list, Description?: string, FolderType?: "Folder"|"Location"|"Factory"|"House"|"Office"|"Machine"|"VirtualMeter"|"ElecticityFolder"|"WaterFolder"|"HeatFolder"|"GasFolder"|"TemperatureFolder"|"Sun"|"Light"|"Ice"|"Sofa"|"Food"|"Coffee"|"Car"|"ChargingStation"|"Meter"|"User"|"Trash"|"GridPhotovoltaicPowerSystem", Icon?: string, Id?: string, MeterSerialNumber?: string, Name?: string, UserId?: string}
export def "folder-menu create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --browser-time-zone-name: string # The time zone name taken from the browser
  --browser-utc-time: string # The UTC time taken from the browser
  --items: list # item shape: {AutoExportSettings?: record, Children?: list, Description?: string, FolderType?: "Folder"|"Location"|"Factory"|"House"|"Office"|"Machine"|"VirtualMeter"|"ElecticityFolder"|"WaterFolder"|"HeatFolder"|"GasFolder"|"TemperatureFolder"|"Sun"|"Light"|"Ice"|"Sofa"|"Food"|"Coffee"|"Car"|"ChargingStation"|"Meter"|"User"|"Trash"|"GridPhotovoltaicPowerSystem", Icon?: string, Id?: string, MeterSerialNumber?: string, Name?: string, UserId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/FolderMenu")
  let body = {"BrowserTimeZoneName": $browser_time_zone_name, "BrowserUtcTime": $browser_utc_time, "Items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A method returning HTTP 200 OK when queried.             It is used by Kubernetes probes to determine whether the app is healthy.
#
# GET /api/Health
# operationId: Health_Get
export def "health get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Health")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# M-BUS API: Adds data of a M-BUS Meter to the smart-me Cloud.             Just send us the M-BUS Telegram (RSP_UD) and we will do the Rest.
#
# POST /api/MBus
# operationId: MBus_Post
export def "m-bus create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --date: string # The Date of the M-BUS Telegram Readout (in UTC). If this is null the Server Time is used. (format: date-time)
  --telegram: string # The M-BUS Telegram as Hex string.              Example: 68 1F 1F 68 08 02 72 78 56 34 12 24 40 01 07 55 00 00 00 03 13 15 31 00 DA 02 3B 13 01 8B 60 04 37 18 02 18 16
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MBus")
  let body = {"Date": $date, "Telegram": $telegram} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets the Name of a Meter or a Folder
#
# POST /api/MeterFolderInformation
# operationId: MeterFolderInformation_Post
export def "meter-folder-information create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the device or folder
  --name: string # Name of the Meter or Folder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MeterFolderInformation")
  let body = {"Id": $id, "Name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Gets the General Information for a Meter or a Folder
#
# GET /api/MeterFolderInformation/{id}
# operationId: MeterFolderInformation_Get
export def "meter-folder-information get" [
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
]: nothing -> record<CommunicationModuleFirmwareVersion: int, CommunicationModuleHardwareVersion: int, FirmwareVersion: int, HardwareVersion: int, InputInformations: table<Name: string, Number: int>, IsFolder: bool, Name: string, OutputInformations: table<ActionType: string, Name: string, Number: int, ObisCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/MeterFolderInformation/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Values for a Meter at a given Date.              The first Value found before the given Date is returned.
#
# GET /api/MeterValues/{id}
# operationId: MeterValues_Get
export def "meter-values get" [
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
  --date: string # format: date-time
]: nothing -> record<CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingExportT3: float, CounterReadingExportT4: float, CounterReadingImport: float, CounterReadingImportT1: float, CounterReadingImportT2: float, CounterReadingImportT3: float, CounterReadingImportT4: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Date: string, Id: string, Serial: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/MeterValues/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all registrations for the Realtime API.
#
# GET /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Get
export def "register-for-realtime-api get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ApiUrl: string, BasicAuthPassword: string, BasicAuthUsername: string, Id: string, MeterId: string, RegistrationType: string, SerialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RegisterForRealtimeApi")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new registration for the realtime API. The Realtime API sends you the data of the registred devices as soon as we have them on the cloud.              More Information about the realtime API: https://www.smart-me.com/Description/api/realtimeapi.aspx
#
# POST /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Post
export def "register-for-realtime-api create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-url: string # The URL of your endpoint. To this endpoint all the values are send to.
  --basic-auth-password: string # The Password (basic auth) of your endpoint. Leave empty of none.
  --basic-auth-username: string # The Username (basic auth) of your endpoint. Leave empty of none.
  --id: string # The ID of the registration
  --meter-id: string # The ID of the Meter. Just used if the RegistrationType is "SingleMeterRegistration".
  --registration-type: string@registration-type-completer # The Type of this registration (per meter, per user, ...)
  --serial-number: string # The serial number of the Meter. Just used if the RegistrationType is "SingleMeterRegistration" and the MeterId is null.              Example: 1 SME 01 63000000 or 6300000
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RegisterForRealtimeApi")
  let body = {"ApiUrl": $api_url, "BasicAuthPassword": $basic_auth_password, "BasicAuthUsername": $basic_auth_username, "Id": $id, "MeterId": $meter_id, "RegistrationType": $registration_type, "SerialNumber": $serial_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a realtime API registration.
#
# DELETE /api/RegisterForRealtimeApi/{id}
# operationId: RegisterForRealtimeApi_Delete
export def "register-for-realtime-api delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/RegisterForRealtimeApi/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the configuration of a smart-me device. The device needs to be online.
#
# POST /api/SmartMeDeviceConfiguration
# operationId: SmartMeDeviceConfiguration_Post
# --InputConfiguration item shape: {Name?: string, Number?: int, OffText?: string, OnText?: string, Type?: "TariffInput"|"DigitalInput"}
# --OutputConfiguration item shape: {DigitalOutputNoConnectionAction?: "Nothing"|"TurnOff"|"TurnOn"|"SetPwmValue", Name?: string, Number?: int, S0PulseValue?: "PulseValue1000Kwh"|"PulseValue10000Kwh", Type?: "ImpulseOutputActiveEnergy"|"ImpulseOutputActiveEnergyImport"|"ImpulseOutputActiveEnergyExport"|"ImpulseOutputReactiveEnergy"|"DigitalOutput"|"AnalogPwmSignalOutput"|"Disabled"}
# --SwitchConfiguration item shape: {CanSwitchOff?: bool, Number?: int}
export def "smart-me-device-configuration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-encryption-key: string # The encryption key used to decrypt messages received from an external meter (used only for the smart-me modules)
  --device-pin-code: string # PIN code to enter on a external meter (e.g. for the FNN meters)
  --dns-update-state: string@dns-update-state-completer # Configuration of the dynamic DNS service. More information: http://wiki.smart-me.com/index.php/Dynamisches_DNS
  --enable-modbus-tcp: oneof<nothing, bool> # Enables or disables Modbus TCP (if the meter supports it).
  --id: string # The ID of the device
  --input-configuration: list # The configuration for the intput outputs — item shape: {Name?: string, Number?: int, OffText?: string, OnText?: string, Type?: "TariffInput"|"DigitalInput"}
  --output-configuration: list # The configuration for the external outputs — item shape: {DigitalOutputNoConnectionAction?: "Nothing"|"TurnOff"|"TurnOn"|"SetPwmValue", Name?: string, Number?: int, S0PulseValue?: "PulseValue1000Kwh"|"PulseValue10000Kwh", Type?: "ImpulseOutputActiveEnergy"|"ImpulseOutputActiveEnergyImport"|"ImpulseOutputActiveEnergyExport"|"ImpulseOutputReactiveEnergy"|"DigitalOutput"|"AnalogPwmSignalOutput"|"Disabled"}
  --show-reactive-energy: oneof<nothing, bool> # Shows the reactive energy values (if the meter supports it).
  --switch-configuration: list # The configuration for the phase switches — item shape: {CanSwitchOff?: bool, Number?: int}
  --upload-interval: string@upload-interval-completer # Number of seconds the device will upload the data. For smaller values maybe a professional license is needed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SmartMeDeviceConfiguration")
  let body = {"DeviceEncryptionKey": $device_encryption_key, "DevicePinCode": $device_pin_code, "DnsUpdateState": $dns_update_state, "EnableModbusTcp": $enable_modbus_tcp, "Id": $id, "InputConfiguration": $input_configuration, "OutputConfiguration": $output_configuration, "ShowReactiveEnergy": $show_reactive_energy, "SwitchConfiguration": $switch_configuration, "UploadInterval": $upload_interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the configuration of a smart-me device.
#
# GET /api/SmartMeDeviceConfiguration/{id}
# operationId: SmartMeDeviceConfiguration_Get
export def "smart-me-device-configuration get" [
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
]: nothing -> record<DeviceEncryptionKey: string, DevicePinCode: string, DnsUpdateState: string, EnableModbusTcp: bool, Id: string, InputConfiguration: table<Name: string, Number: int, OffText: string, OnText: string, Type: string>, OutputConfiguration: table<DigitalOutputNoConnectionAction: string, Name: string, Number: int, S0PulseValue: string, Type: string>, ShowReactiveEnergy: bool, SwitchConfiguration: table<CanSwitchOff: bool, Number: int>, UploadInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/SmartMeDeviceConfiguration/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a subuser.             To create a new user set no ID (empty)
#
# POST /api/SubUser
# operationId: SubUser_Post
export def "sub-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-end-date: string # The end date. until this date the user has access (format: date-time)
  --access-time-start-date: string # The start date. From this date the user has access (format: date-time)
  --email: string # The Email adress
  --id: string # The ID of the user
  --new-password: string # If set this is used a new password
  --permission-level: string@permission-level-completer # The permission level of the user
  --username: string # The username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SubUser")
  let body = {"AccessEndDate": $access_end_date, "AccessTimeStartDate": $access_time_start_date, "Email": $email, "Id": $id, "NewPassword": $new_password, "PermissionLevel": $permission_level, "Username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a subuser
#
# DELETE /api/SubUser/{id}
# operationId: SubUser_Delete
export def "sub-user delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/SubUser/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sub user. The user must be assigend to the user that makes this call.
#
# GET /api/SubUser/{id}
# operationId: SubUser_Get
export def "sub-user get" [
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
]: nothing -> record<AccessEndDate: string, AccessTimeStartDate: string, Email: string, Id: string, NewPassword: string, PermissionLevel: string, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/SubUser/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers user account deletion.
#
# DELETE /api/User
# operationId: User_Delete
export def "user delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the informations for the user.
#
# GET /api/User
# operationId: User_Get
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ChildUsers: list<any>, Email: string, Id: int, IdAsString: string, IsAdmin: bool, Permissions: list<string>, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all (last) values of a device
#
# GET /api/Values/{id}
# operationId: Values_Get
export def "values get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/Values/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all (last) values of a device             The first Value found before the given Date is returned.
#
# GET /api/ValuesInPast/{id}
# operationId: ValuesInPast_Get
export def "values-in-past get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --date: string # the date of the value (format: date-time)
]: nothing -> record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/ValuesInPast/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets multiple values of a device. This call needs a smart-me professional licence.
#
# GET /api/ValuesInPastMultiple/{id}
# operationId: ValuesInPastMultiple_Get
export def "values-in-past-multiple get" [
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
  --start-date: string # The date when the first value should start (format: date-time)
  --end-date: string # The date when the last value should start (format: date-time)
  --interval: int # The interval in minutes betwenn the values. 0 means as fast as possible. Only 1000 values can be get in one call. (format: int32)
]: nothing -> table<Date: string, DeviceId: string, Values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/ValuesInPastMultiple/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Beta: Gets all active virtual meters
#
# GET /api/VirtualBillingMeterActive
# operationId: VirtualBillingMeterActive_Get
export def "virtual-billing-meter-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterActive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Beta: Virtual Meter API: Activates a Meter and add the Consumption to a Virtual Meter assosiated with the User.
#
# POST /api/VirtualBillingMeterActive
# operationId: VirtualBillingMeterActive_Post
export def "virtual-billing-meter-active create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serial-number: string # The Serialnumber of the Meter to activate.
]: any -> record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterActive")
  let body = {"SerialNumber": $serial_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Virtual Meter API: Deactivates a Virtual Meter.
#
# POST /api/VirtualBillingMeterDeactivate
# operationId: VirtualBillingMeterDeactivate_Post
export def "virtual-billing-meter-deactivate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The ID of the Virtual meter to deactivate
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterDeactivate")
  let body = {"ID": $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Gets all Meters available to activate as a Virtual Meter.
#
# GET /api/VirtualBillingMeters
# operationId: VirtualBillingMeters_Get
export def "virtual-billing-meters get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeters")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculates a virtual meter from a formula.              A meter is coded as ID("METERID")
#
# GET /api/VirtualMeterCalculateFormula
# operationId: VirtualMeterCalculateFormula_Get
export def "virtual-meter-calculate-formula get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --formula: string
]: nothing -> record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "formula" $formula "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/VirtualMeterCalculateFormula" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Virtual Tariffs of a user
#
# GET /api/VirtualTariff
# operationId: VirtualTariff_Get
export def "virtual-tariff list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualTariff")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all virtual tariffs of a folder
#
# GET /api/VirtualTariff/{id}
export def "virtual-tariff get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<Date: string, FolderId: string, Name: string, VirtualTariffs: table<Factor: float, Id: string, Name: string, Type: string, Unit: string, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/VirtualTariff/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the consumption of a folder with a virtuall tariffs.
#
# GET /api/VirtualTariffConsumption
# operationId: VirtualTariffConsumption_Get
export def "virtual-tariff-consumption get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --folder-id: string # The ID of the Folder
  --start-date: string # The start date (UTC) (format: date-time)
  --end-date: string # The end date (UTC) (format: date-time)
]: nothing -> table<Consumption: float, Currency: string, Name: string, Price: float, TariffType: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folderId" $folder_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/VirtualTariffConsumption" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Virtual Tariffs for a property (folder)
#
# GET /api/VirtualTariffsForProperty/{id}
# operationId: VirtualTariffsForProperty_Get
export def "virtual-tariffs-for-property get" [
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
]: nothing -> table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/VirtualTariffsForProperty/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the calculation status for a virtual tariff property
#
# GET /api/VirtualTariffsStatusForProperty/{id}
# operationId: VirtualTariffsStatusForProperty_Get
export def "virtual-tariffs-status-for-property get" [
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
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/VirtualTariffsStatusForProperty/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a folder (source) or meter to another folder (target). Can be used to create a folder structure.
#
# POST /api/folder/assign
# operationId: FolderAssign_Post
export def "folder-assign create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string # The ID of the meter or folder that should be assign
  --target: string # The ID of the meter or folder that should be the parent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/assign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a folder
#
# DELETE /api/folder/settings/{id}
# operationId: FolderSettings_Delete
export def "folder-settings delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/folder/settings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the settings of a folder or meter
#
# GET /api/folder/settings/{id}
# operationId: FolderSettings_Get
export def "folder-settings get" [
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
]: nothing -> record<Description: string, Enable: bool, FolderType: string, Name: string, ParentFolderId: string, SerialNumber: int, UseableForVirtualBillingMeters: bool, ValueCorrection: float, ValueCorrectionParentFolder: float, VisualizationName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/folder/settings/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or edit a folder or a meter. To add a new folder use and empty ID
#
# POST /api/folder/settings/{id}
# operationId: FolderSettings_Post
export def "folder-settings create" [
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
  --description: string # The Description of the folder or meter
  --enable: oneof<nothing, bool> # Flag if the meter is enabled (folder not supported yet)
  --folder-type: string@folder-type-completer # The Type of the folder
  --name: string # The Name of the folder or meter
  --parent-folder-id: string # The parent folder ID of this item
  --serial-number: int # The serial number (meter only) (format: int64)
  --useable-for-virtual-billing-meters: oneof<nothing, bool> # Flag if the meter is usable for virtual billing meters (e.g. washroom)
  --value-correction: float # The value correction on this meter (format: double)
  --value-correction-parent-folder: float # The value correction on all parent folders. but not on the meter itself (format: double)
  --visualization-name: string # The name of the visualization of the folder
]: any -> record<AutoExportSettings: record<ExportFormat: string, ExportInterval: string, MeterPointId: string, UploadType: string>, Children: list<any>, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/folder/settings/{id}"))
  let body = {"Description": $description, "Enable": $enable, "FolderType": $folder_type, "Name": $name, "ParentFolderId": $parent_folder_id, "SerialNumber": $serial_number, "UseableForVirtualBillingMeters": $useable_for_virtual_billing_meters, "ValueCorrection": $value_correction, "ValueCorrectionParentFolder": $value_correction_parent_folder, "VisualizationName": $visualization_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a user to folder assignement
#
# DELETE /api/folder/user/assign
# operationId: UserToFolderAssign_Delete
export def "folder-user-assign delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string # The ID of the user that should be de-assign
  --target: string # The ID of the folder
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/user/assign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a user to a folder
#
# POST /api/folder/user/assign
# operationId: UserToFolderAssign_Post
export def "folder-user-assign create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string # The ID of the user that should be assign
  --target: string # The ID of the folder that should be the parent
  --old-folder: string # The ID of the old folder (in case of a drag and drop to a new folder)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "oldFolder" $old_folder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/user/assign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/oauth/authorize
#
# operationId: OAuth_Authorize
export def "oauth-authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string
  --redirect-uri: string
  --state: string
  --scope: string
  --client-secret: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oauth/authorize" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/oauth/authorize
export def "oauth-authorize post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string
  --redirect-uri: string
  --state: string
  --scope: string
  --client-secret: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oauth/authorize" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all pico charging stations for this user
#
# GET /api/pico
# operationId: Pico_Get
export def "pico get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pico")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the active charging data of a pico station
#
# GET /api/pico/charging/{id}
# operationId: PicoCharging_Get
export def "pico-charging get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<ActiveChargingEnergy: float, ActiveChargingPower: float, ConnectionMode: string, Duration: int, LastWarningOrError: string, LastWarningOrErrorMessage: string, LastWarningOrErrorTime: string, LoadSheddingState: string, LoadmanagementGroupName: string, MaxAllowedChargingCurrent: int, MaxDynamicCurrent: int, MaxLoadmanagementGroupCurrent: int, MaxStationCurrent: int, MinStationCurrent: int, State: string, ValueDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/pico/charging/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the last charging history for a pico station
#
# GET /api/pico/history/{id}
# operationId: PicoChargingHistory_Get
export def "pico-history get" [
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
]: nothing -> table<Duration: int, EnergyUsed: float, StartTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/pico/history/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/loadmanagementgroup                          Returns all available load management groups
#
# GET /api/pico/loadmanagementgroup
export def "pico-loadmanagementgroup list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pico/loadmanagementgroup")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the dynamic current of a load management group or a single station.
#
# POST /api/pico/loadmanagementgroup/current/{serial}
# operationId: PicoLoadmanagementSetDynamicCurrent_Post
export def "pico-loadmanagementgroup-current create" [
  serial: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --current: int # The dynamic current of the group (in mA) (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current" $current "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: $serial} | format pattern "/api/pico/loadmanagementgroup/current/{serial}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/loadmanagementgroup                          Returns a pico load management group by it's id
#
# GET /api/pico/loadmanagementgroup/{id}
# operationId: PicoLoadmanagementGroup_Get
export def "pico-loadmanagementgroup get" [
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
]: nothing -> record<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/pico/loadmanagementgroup/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/settings                          Returns the settings of a pico charging station.
#
# GET /api/pico/settings/{id}
# operationId: PicoSettings_Get
export def "pico-settings get" [
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
]: nothing -> record<AuthenticationType: string, CarIdDetection: bool, DisplayBrightness: string, DnsName: string, FixCableLockEnable: bool, IdleImageUrl: string, InternalIp: string, LoadmanagementGroupId: string, MaxCurrent: int, MinCurrent: int, ModbusTcp: bool, Name: string, SerialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/pico/settings/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Try to fix lock the cable of a pico. The pico must be online and a cable (without car) needs to be connected. Otherwise this will fail.
#
# POST /api/pico/tryenablecablelock/{id}
# operationId: PicoEnableFixCableLock_Post
export def "pico-tryenablecablelock create" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/pico/tryenablecablelock/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
