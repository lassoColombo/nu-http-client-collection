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
def DeviceEnergyType-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def MeterSubType-completer [] { ["MeterSubTypeChargingStation" "MeterSubTypeCold" "MeterSubTypeElectricity" "MeterSubTypeElectricityHeat" "MeterSubTypeGas" "MeterSubTypeHeat" "MeterSubTypeTemperature" "MeterSubTypeUnknown" "MeterSubTypeVirtualBattery" "MeterSubTypeWater"] }
def meterEnergyType-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def meterSubType-completer [] { ["MeterSubTypeChargingStation" "MeterSubTypeCold" "MeterSubTypeElectricity" "MeterSubTypeElectricityHeat" "MeterSubTypeGas" "MeterSubTypeHeat" "MeterSubTypeTemperature" "MeterSubTypeUnknown" "MeterSubTypeVirtualBattery" "MeterSubTypeWater"] }
def RegistrationType-completer [] { ["Disabled" "SingleMeterRegistration" "UserRegistration"] }
def DnsUpdateState-completer [] { ["DnsUpdateInternalIp" "DnsUpdatePublicIp" "NoUpdate"] }
def UploadInterval-completer [] { ["UploadInterval_10s" "UploadInterval_12h" "UploadInterval_15min" "UploadInterval_1s" "UploadInterval_24h" "UploadInterval_30min" "UploadInterval_30s" "UploadInterval_5min" "UploadInterval_5s" "UploadInterval_60min" "UploadInterval_60s" "UploadInterval_6h"] }
def PermissionLevel-completer [] { ["SelectedFolderAndSubfoldersMeters" "SelectedFolderOnly"] }
def FolderType-completer [] { ["Car" "ChargingStation" "Coffee" "ElecticityFolder" "Factory" "Folder" "Food" "GasFolder" "GridPhotovoltaicPowerSystem" "HeatFolder" "House" "Ice" "Light" "Location" "Machine" "Meter" "Office" "Sofa" "Sun" "TemperatureFolder" "Trash" "User" "VirtualMeter" "WaterFolder"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-token Put" } } | get name | first)
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
export def "access-token Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CardId: int # The ID of the Card (format: int64)
  --UserId: int # The ID of the User. The credentials provided must have permission to edit the user.             If no ID is provided, the user in the credentials is taken. (format: int64)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/AccessToken")
  let body = {CardId: $CardId, UserId: $UserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/Account/login
#
# operationId: Account_Login
export def "account-login Login" [
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
export def "actions Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Actions: list # List with all Actions for this device — item shape: {ObisCode?: string, Value?: float}
  --DeviceID: string # The ID of the Device
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Actions")
  let body = {Actions: $Actions, DeviceID: $DeviceID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all available Actions of a Device
#
# GET /api/Actions/{id}
# operationId: Actions_Get
export def "actions Get" [
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
  let full_url = (build-url $base $"/api/Actions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the additional information (e.g. Firmware Version) about a device.
#
# GET /api/AdditionalDeviceInformation/{id}
# operationId: AdditionalDeviceInformation_Get
export def "additional-device-information Get" [
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
  let full_url = (build-url $base $"/api/AdditionalDeviceInformation/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Custom Devices
#
# GET /api/CustomDevice
# operationId: CustomDevice_Get
export def "custom-device Get" [
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
export def "custom-device Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Id: string # The ID of the device
  --Name: string # The Name of the Device
  --Serial: int # The Serial number (format: int64)
  --ValueDate: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --Values: list # The Values of the custom Device — item shape: {Name?: string, Value?: float}
]: any -> record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CustomDevice")
  let body = {Id: $Id, Name: $Name, Serial: $Serial, ValueDate: $ValueDate, Values: $Values} | compact
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
  let full_url = (build-url $base $"/api/CustomDevice/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Device by it's Serial Number. The Serial is the part before the "-".
#
# GET /api/DeviceBySerial
# operationId: DeviceBySerial_Get
export def "device-by-serial Get" [
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
export def "devices Get" [
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
export def "devices Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ActivePower: float # The Active Power or current flow rate. In kW or m3/h (format: double)
  --CounterReading: float # The Meter Counter Reading (Total Energy used) in kWh or m3. (format: double)
  --CounterReadingExport: float # The Meter Counter Reading only export (format: double)
  --CounterReadingExportT1: float # The Meter Counter Reading only export (Tariff 1) (format: double)
  --CounterReadingExportT2: float # The Meter Counter Reading only export (Tariff 2) (format: double)
  --CounterReadingT1: float # The Meter Counter Reading Tariff 1 in kWh or m3. (format: double)
  --CounterReadingT2: float # The Meter Counter Reading Tariff 2 in kWh or m3. (format: double)
  --Current: float # The Current (in A) (format: double)
  --CurrentL1: float # The Current Phase L1 (in A) (format: double)
  --CurrentL2: float # The Current Phase L2 (in A) (format: double)
  --CurrentL3: float # The Current Phase L3 (in A) (format: double)
  --DeviceEnergyType: string@DeviceEnergyType-completer # The Energy Type of this device
  --DigitalInput1: oneof<nothing, bool> # The digital input number 1
  --Id: string # The ID of the device
  --MeterSubType: string@MeterSubType-completer # The Sub Type of this Meter.
  --Name: string # The Name of the Device
  --PowerFactor: float # The Power Factor (cos phi). Range: 0 - 1 (format: double)
  --PowerFactorL1: float # The Power Factor (cos phi) Phase L1. Range: 0 - 1 (format: double)
  --PowerFactorL2: float # The Power Factor (cos phi) Phase L2. Range: 0 - 1 (format: double)
  --PowerFactorL3: float # The Power Factor (cos phi) Phase L3. Range: 0 - 1 (format: double)
  --Serial: int # The Serial number (format: int64)
  --Temperature: float # The Temperature (in degree celsius) (format: double)
  --ValueDate: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --Voltage: float # The Voltage (in V) (format: double)
  --VoltageL1: float # The Voltage Phase L1 (in V) (format: double)
  --VoltageL2: float # The Voltage Phase L2 (in V) (format: double)
  --VoltageL3: float # The Voltage Phase L3 (in V) (format: double)
]: any -> record<ActivePower: float, CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingT1: float, CounterReadingT2: float, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Devices")
  let body = {ActivePower: $ActivePower, CounterReading: $CounterReading, CounterReadingExport: $CounterReadingExport, CounterReadingExportT1: $CounterReadingExportT1, CounterReadingExportT2: $CounterReadingExportT2, CounterReadingT1: $CounterReadingT1, CounterReadingT2: $CounterReadingT2, Current: $Current, CurrentL1: $CurrentL1, CurrentL2: $CurrentL2, CurrentL3: $CurrentL3, DeviceEnergyType: $DeviceEnergyType, DigitalInput1: $DigitalInput1, Id: $Id, MeterSubType: $MeterSubType, Name: $Name, PowerFactor: $PowerFactor, PowerFactorL1: $PowerFactorL1, PowerFactorL2: $PowerFactorL2, PowerFactorL3: $PowerFactorL3, Serial: $Serial, Temperature: $Temperature, ValueDate: $ValueDate, Voltage: $Voltage, VoltageL1: $VoltageL1, VoltageL2: $VoltageL2, VoltageL3: $VoltageL3} | compact
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
  let full_url = (build-url $base $"/api/Devices/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the On/Off Switch on a device.              For new implementations please use the "actions" command
#
# PUT /api/Devices/{id}
# operationId: Devices_Put
export def "devices Put" [
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
  --switchState: oneof<nothing, bool> # The new state of the switch
  --switchNumber: int # The number of the switch if there are multiple (1 for L1, 3 for L3) (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "switchState" $switchState "scalar") (serialize-qp "switchNumber" $switchNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/Devices/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Devices for an Energy Type
#
# GET /api/DevicesByEnergy
# operationId: DevicesByEnergy_Get
export def "devices-by-energy Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meterEnergyType: string@meterEnergyType-completer
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meterEnergyType" $meterEnergyType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesByEnergy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Devices by it's Sub Type (e.g. E-Charging Station)
#
# GET /api/DevicesBySubType
# operationId: DevicesBySubType_Get
export def "devices-by-sub-type Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meterSubType: string@meterSubType-completer
]: nothing -> table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meterSubType" $meterSubType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesBySubType" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force a device to send the data every second (if supported). This for about 30s.             Don't use this call to force a device to send the data every second for a longer time.
#
# GET /api/FastSendDeviceValues/{id}
# operationId: FastSendDeviceValues_Get
export def "fast-send-device-values Get" [
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
  let full_url = (build-url $base $"/api/FastSendDeviceValues/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Values for a folder or a meter
#
# GET /api/Folder/{id}
# operationId: Folder_Get
export def "folder Get" [
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
  let full_url = (build-url $base $"/api/Folder/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the folder menu items (each item might contain child items)
#
# GET /api/FolderMenu
# operationId: FolderMenu_Get
export def "folder-menu Get" [
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
export def "folder-menu Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BrowserTimeZoneName: string # The time zone name taken from the browser
  --BrowserUtcTime: string # The UTC time taken from the browser
  --Items: list # item shape: {AutoExportSettings?: record, Children?: list, Description?: string, FolderType?: "Folder"|"Location"|"Factory"|"House"|"Office"|"Machine"|"VirtualMeter"|"ElecticityFolder"|"WaterFolder"|"HeatFolder"|"GasFolder"|"TemperatureFolder"|"Sun"|"Light"|"Ice"|"Sofa"|"Food"|"Coffee"|"Car"|"ChargingStation"|"Meter"|"User"|"Trash"|"GridPhotovoltaicPowerSystem", Icon?: string, Id?: string, MeterSerialNumber?: string, Name?: string, UserId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/FolderMenu")
  let body = {BrowserTimeZoneName: $BrowserTimeZoneName, BrowserUtcTime: $BrowserUtcTime, Items: $Items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A method returning HTTP 200 OK when queried.             It is used by Kubernetes probes to determine whether the app is healthy.
#
# GET /api/Health
# operationId: Health_Get
export def "health Get" [
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
export def "m-bus Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Date: string # The Date of the M-BUS Telegram Readout (in UTC). If this is null the Server Time is used. (format: date-time)
  --Telegram: string # The M-BUS Telegram as Hex string.              Example: 68 1F 1F 68 08 02 72 78 56 34 12 24 40 01 07 55 00 00 00 03 13 15 31 00 DA 02 3B 13 01 8B 60 04 37 18 02 18 16
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MBus")
  let body = {Date: $Date, Telegram: $Telegram} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets the Name of a Meter or a Folder
#
# POST /api/MeterFolderInformation
# operationId: MeterFolderInformation_Post
export def "meter-folder-information Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Id: string # The ID of the device or folder
  --Name: string # Name of the Meter or Folder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MeterFolderInformation")
  let body = {Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Gets the General Information for a Meter or a Folder
#
# GET /api/MeterFolderInformation/{id}
# operationId: MeterFolderInformation_Get
export def "meter-folder-information Get" [
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
  let full_url = (build-url $base $"/api/MeterFolderInformation/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Values for a Meter at a given Date.              The first Value found before the given Date is returned.
#
# GET /api/MeterValues/{id}
# operationId: MeterValues_Get
export def "meter-values Get" [
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
  let full_url = (build-url $base $"/api/MeterValues/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all registrations for the Realtime API.
#
# GET /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Get
export def "register-for-realtime-api Get" [
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
export def "register-for-realtime-api Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ApiUrl: string # The URL of your endpoint. To this endpoint all the values are send to.
  --BasicAuthPassword: string # The Password (basic auth) of your endpoint. Leave empty of none.
  --BasicAuthUsername: string # The Username (basic auth) of your endpoint. Leave empty of none.
  --Id: string # The ID of the registration
  --MeterId: string # The ID of the Meter. Just used if the RegistrationType is "SingleMeterRegistration".
  --RegistrationType: string@RegistrationType-completer # The Type of this registration (per meter, per user, ...)
  --SerialNumber: string # The serial number of the Meter. Just used if the RegistrationType is "SingleMeterRegistration" and the MeterId is null.              Example: 1 SME 01 63000000 or 6300000
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RegisterForRealtimeApi")
  let body = {ApiUrl: $ApiUrl, BasicAuthPassword: $BasicAuthPassword, BasicAuthUsername: $BasicAuthUsername, Id: $Id, MeterId: $MeterId, RegistrationType: $RegistrationType, SerialNumber: $SerialNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a realtime API registration.
#
# DELETE /api/RegisterForRealtimeApi/{id}
# operationId: RegisterForRealtimeApi_Delete
export def "register-for-realtime-api Delete" [
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
  let full_url = (build-url $base $"/api/RegisterForRealtimeApi/($id)")
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
export def "smart-me-device-configuration Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceEncryptionKey: string # The encryption key used to decrypt messages received from an external meter (used only for the smart-me modules)
  --DevicePinCode: string # PIN code to enter on a external meter (e.g. for the FNN meters)
  --DnsUpdateState: string@DnsUpdateState-completer # Configuration of the dynamic DNS service. More information: http://wiki.smart-me.com/index.php/Dynamisches_DNS
  --EnableModbusTcp: oneof<nothing, bool> # Enables or disables Modbus TCP (if the meter supports it).
  --Id: string # The ID of the device
  --InputConfiguration: list # The configuration for the intput outputs — item shape: {Name?: string, Number?: int, OffText?: string, OnText?: string, Type?: "TariffInput"|"DigitalInput"}
  --OutputConfiguration: list # The configuration for the external outputs — item shape: {DigitalOutputNoConnectionAction?: "Nothing"|"TurnOff"|"TurnOn"|"SetPwmValue", Name?: string, Number?: int, S0PulseValue?: "PulseValue1000Kwh"|"PulseValue10000Kwh", Type?: "ImpulseOutputActiveEnergy"|"ImpulseOutputActiveEnergyImport"|"ImpulseOutputActiveEnergyExport"|"ImpulseOutputReactiveEnergy"|"DigitalOutput"|"AnalogPwmSignalOutput"|"Disabled"}
  --ShowReactiveEnergy: oneof<nothing, bool> # Shows the reactive energy values (if the meter supports it).
  --SwitchConfiguration: list # The configuration for the phase switches — item shape: {CanSwitchOff?: bool, Number?: int}
  --UploadInterval: string@UploadInterval-completer # Number of seconds the device will upload the data. For smaller values maybe a professional license is needed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SmartMeDeviceConfiguration")
  let body = {DeviceEncryptionKey: $DeviceEncryptionKey, DevicePinCode: $DevicePinCode, DnsUpdateState: $DnsUpdateState, EnableModbusTcp: $EnableModbusTcp, Id: $Id, InputConfiguration: $InputConfiguration, OutputConfiguration: $OutputConfiguration, ShowReactiveEnergy: $ShowReactiveEnergy, SwitchConfiguration: $SwitchConfiguration, UploadInterval: $UploadInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the configuration of a smart-me device.
#
# GET /api/SmartMeDeviceConfiguration/{id}
# operationId: SmartMeDeviceConfiguration_Get
export def "smart-me-device-configuration Get" [
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
  let full_url = (build-url $base $"/api/SmartMeDeviceConfiguration/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a subuser.             To create a new user set no ID (empty)
#
# POST /api/SubUser
# operationId: SubUser_Post
export def "sub-user Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AccessEndDate: string # The end date. until this date the user has access (format: date-time)
  --AccessTimeStartDate: string # The start date. From this date the user has access (format: date-time)
  --Email: string # The Email adress
  --Id: string # The ID of the user
  --NewPassword: string # If set this is used a new password
  --PermissionLevel: string@PermissionLevel-completer # The permission level of the user
  --Username: string # The username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SubUser")
  let body = {AccessEndDate: $AccessEndDate, AccessTimeStartDate: $AccessTimeStartDate, Email: $Email, Id: $Id, NewPassword: $NewPassword, PermissionLevel: $PermissionLevel, Username: $Username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a subuser
#
# DELETE /api/SubUser/{id}
# operationId: SubUser_Delete
export def "sub-user Delete" [
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
  let full_url = (build-url $base $"/api/SubUser/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sub user. The user must be assigend to the user that makes this call.
#
# GET /api/SubUser/{id}
# operationId: SubUser_Get
export def "sub-user Get" [
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
  let full_url = (build-url $base $"/api/SubUser/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers user account deletion.
#
# DELETE /api/User
# operationId: User_Delete
export def "user Delete" [
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
export def "user Get" [
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
export def "values Get" [
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
  let full_url = (build-url $base $"/api/Values/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all (last) values of a device             The first Value found before the given Date is returned.
#
# GET /api/ValuesInPast/{id}
# operationId: ValuesInPast_Get
export def "values-in-past Get" [
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
  let full_url = (build-url $base $"/api/ValuesInPast/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets multiple values of a device. This call needs a smart-me professional licence.
#
# GET /api/ValuesInPastMultiple/{id}
# operationId: ValuesInPastMultiple_Get
export def "values-in-past-multiple Get" [
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
  --startDate: string # The date when the first value should start (format: date-time)
  --endDate: string # The date when the last value should start (format: date-time)
  --interval: int # The interval in minutes betwenn the values. 0 means as fast as possible. Only 1000 values can be get in one call. (format: int32)
]: nothing -> table<Date: string, DeviceId: string, Values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/ValuesInPastMultiple/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Beta: Gets all active virtual meters
#
# GET /api/VirtualBillingMeterActive
# operationId: VirtualBillingMeterActive_Get
export def "virtual-billing-meter-active Get" [
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
export def "virtual-billing-meter-active Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --SerialNumber: string # The Serialnumber of the Meter to activate.
]: any -> record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterActive")
  let body = {SerialNumber: $SerialNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Virtual Meter API: Deactivates a Virtual Meter.
#
# POST /api/VirtualBillingMeterDeactivate
# operationId: VirtualBillingMeterDeactivate_Post
export def "virtual-billing-meter-deactivate Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ID: string # The ID of the Virtual meter to deactivate
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterDeactivate")
  let body = {ID: $ID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta: Gets all Meters available to activate as a Virtual Meter.
#
# GET /api/VirtualBillingMeters
# operationId: VirtualBillingMeters_Get
export def "virtual-billing-meters Get" [
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
export def "virtual-meter-calculate-formula Get" [
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
export def "virtual-tariff Get" [
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
  let full_url = (build-url $base $"/api/VirtualTariff/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the consumption of a folder with a virtuall tariffs.
#
# GET /api/VirtualTariffConsumption
# operationId: VirtualTariffConsumption_Get
export def "virtual-tariff-consumption Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --folderId: string # The ID of the Folder
  --startDate: string # The start date (UTC) (format: date-time)
  --endDate: string # The end date (UTC) (format: date-time)
]: nothing -> table<Consumption: float, Currency: string, Name: string, Price: float, TariffType: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folderId" $folderId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/VirtualTariffConsumption" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Virtual Tariffs for a property (folder)
#
# GET /api/VirtualTariffsForProperty/{id}
# operationId: VirtualTariffsForProperty_Get
export def "virtual-tariffs-for-property Get" [
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
  let full_url = (build-url $base $"/api/VirtualTariffsForProperty/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the calculation status for a virtual tariff property
#
# GET /api/VirtualTariffsStatusForProperty/{id}
# operationId: VirtualTariffsStatusForProperty_Get
export def "virtual-tariffs-status-for-property Get" [
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
  let full_url = (build-url $base $"/api/VirtualTariffsStatusForProperty/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a folder (source) or meter to another folder (target). Can be used to create a folder structure.
#
# POST /api/folder/assign
# operationId: FolderAssign_Post
export def "folder-assign Post" [
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
export def "folder-settings Delete" [
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
  let full_url = (build-url $base $"/api/folder/settings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the settings of a folder or meter
#
# GET /api/folder/settings/{id}
# operationId: FolderSettings_Get
export def "folder-settings Get" [
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
  let full_url = (build-url $base $"/api/folder/settings/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or edit a folder or a meter. To add a new folder use and empty ID
#
# POST /api/folder/settings/{id}
# operationId: FolderSettings_Post
export def "folder-settings Post" [
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
  --Description: string # The Description of the folder or meter
  --Enable: oneof<nothing, bool> # Flag if the meter is enabled (folder not supported yet)
  --FolderType: string@FolderType-completer # The Type of the folder
  --Name: string # The Name of the folder or meter
  --ParentFolderId: string # The parent folder ID of this item
  --SerialNumber: int # The serial number (meter only) (format: int64)
  --UseableForVirtualBillingMeters: oneof<nothing, bool> # Flag if the meter is usable for virtual billing meters (e.g. washroom)
  --ValueCorrection: float # The value correction on this meter (format: double)
  --ValueCorrectionParentFolder: float # The value correction on all parent folders. but not on the meter itself (format: double)
  --VisualizationName: string # The name of the visualization of the folder
]: any -> record<AutoExportSettings: record<ExportFormat: string, ExportInterval: string, MeterPointId: string, UploadType: string>, Children: list<any>, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/folder/settings/($id)")
  let body = {Description: $Description, Enable: $Enable, FolderType: $FolderType, Name: $Name, ParentFolderId: $ParentFolderId, SerialNumber: $SerialNumber, UseableForVirtualBillingMeters: $UseableForVirtualBillingMeters, ValueCorrection: $ValueCorrection, ValueCorrectionParentFolder: $ValueCorrectionParentFolder, VisualizationName: $VisualizationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a user to folder assignement
#
# DELETE /api/folder/user/assign
# operationId: UserToFolderAssign_Delete
export def "folder-user-assign Delete" [
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
export def "folder-user-assign Post" [
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
  --oldFolder: string # The ID of the old folder (in case of a drag and drop to a new folder)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "oldFolder" $oldFolder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/user/assign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/oauth/authorize
#
# operationId: OAuth_Authorize
export def "oauth-authorize Authorize" [
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
export def "pico Get" [
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
export def "pico-charging Get" [
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
  let full_url = (build-url $base $"/api/pico/charging/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the last charging history for a pico station
#
# GET /api/pico/history/{id}
# operationId: PicoChargingHistory_Get
export def "pico-history Get" [
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
  let full_url = (build-url $base $"/api/pico/history/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/loadmanagementgroup                          Returns all available load management groups
#
# GET /api/pico/loadmanagementgroup
export def "pico-loadmanagementgroup get" [
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
export def "pico-loadmanagementgroup-current Post" [
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
  let full_url = (build-url $base $"/api/pico/loadmanagementgroup/current/($serial)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/loadmanagementgroup                          Returns a pico load management group by it's id
#
# GET /api/pico/loadmanagementgroup/{id}
# operationId: PicoLoadmanagementGroup_Get
export def "pico-loadmanagementgroup Get" [
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
  let full_url = (build-url $base $"/api/pico/loadmanagementgroup/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET: api/pico/settings                          Returns the settings of a pico charging station.
#
# GET /api/pico/settings/{id}
# operationId: PicoSettings_Get
export def "pico-settings Get" [
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
  let full_url = (build-url $base $"/api/pico/settings/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Try to fix lock the cable of a pico. The pico must be online and a cable (without car) needs to be connected. Otherwise this will fail.
#
# POST /api/pico/tryenablecablelock/{id}
# operationId: PicoEnableFixCableLock_Post
export def "pico-tryenablecablelock Post" [
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
  let full_url = (build-url $base $"/api/pico/tryenablecablelock/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
