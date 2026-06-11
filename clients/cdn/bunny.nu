# Auto-generated client for bunny.net API v1.0.0
# Source: https://core-api-public-docs.b-cdn.net/docs/v3/public.json
# Auth: --token flag or $env.BUNNY_NET_API_TOKEN

const BASE_URL = "https://api.bunny.net"
const DEFAULT_AUTH = "accesskey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUNNY_NET_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "accesskey" => { {headers: {AccessKey: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.bunny.net"] }
def auth-scheme-completer [] { ["accesskey" "bearer"] }

# Completers for enum parameters
def KeyType-completer [] { ["0" "1"] }
def Order-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "country GetCountryList" } } | get name | first)
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

# Get Country List
#
# GET /country
# operationId: CountriesPublic_GetCountryList
export def "country GetCountryList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Name: string, IsoCode: string, IsEU: bool, TaxRate: float, TaxPrefix: string, FlagUrl: string, PopList: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List DNS Zones
#
# GET /dnszone
# operationId: DnsZonePublic_Index
export def "dnszone Index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --perPage: int # format: int32, default: 1000
  --search: string # The search term that will be used to filter the results (nullable)
]: nothing -> record<Items: table<Id: int, Domain: string, Records: list, DateModified: string, DateCreated: string, NameserversDetected: bool, CustomNameserversEnabled: bool, Nameserver1: string, Nameserver2: string, SoaEmail: string, NameserversNextCheck: string, LoggingEnabled: bool, LoggingIPAnonymizationEnabled: bool, LogAnonymizationType: any, DnsSecEnabled: bool, CertificateKeyType: any>, CurrentPage: int, TotalItems: int, HasMoreItems: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dnszone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add DNS Zone
#
# POST /dnszone
# operationId: DnsZonePublic_Add
# --Records item shape: {Type?: any, Ttl?: int, Value?: string, Name?: string, Weight?: int, Priority?: int, Flags?: int, Tag?: string, Port?: int, PullZoneId?: int, ScriptId?: int, Accelerated?: bool, MonitorType?: any, GeolocationLatitude?: float, GeolocationLongitude?: float, LatencyZone?: string, SmartRoutingType?: any, Disabled?: bool, EnviromentalVariables?: list, Comment?: string, AutoSslIssuance?: bool}
export def "dnszone Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Domain: string # The domain that will be added.
  --Records: list # Optional array of DNS records to add when creating the zone. (nullable) — item shape: {Type?: any, Ttl?: int, Value?: string, Name?: string, Weight?: int, Priority?: int, Flags?: int, Tag?: string, Port?: int, PullZoneId?: int, ScriptId?: int, Accelerated?: bool, MonitorType?: any, GeolocationLatitude?: float, GeolocationLongitude?: float, LatencyZone?: string, SmartRoutingType?: any, Disabled?: bool, EnviromentalVariables?: list, Comment?: string, AutoSslIssuance?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnszone")
  let body = {Domain: $Domain, Records: $Records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get DNS Zone
#
# GET /dnszone/{id}
# operationId: DnsZonePublic_Index2
export def "dnszone Index2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Domain: string, Records: table<Id: int, Type: int, Ttl: int, Value: string, Name: string, Weight: int, Priority: int, Port: int, Flags: int, Tag: string, Accelerated: bool, AcceleratedPullZoneId: int, LinkName: string, IPGeoLocationInfo: any, GeolocationInfo: any, MonitorStatus: int, MonitorType: int, GeolocationLatitude: float, GeolocationLongitude: float, EnviromentalVariables: list, LatencyZone: string, SmartRoutingType: int, Disabled: bool, Comment: string, AutoSslIssuance: bool, AccelerationStatus: int>, DateModified: string, DateCreated: string, NameserversDetected: bool, CustomNameserversEnabled: bool, Nameserver1: string, Nameserver2: string, SoaEmail: string, NameserversNextCheck: string, LoggingEnabled: bool, LoggingIPAnonymizationEnabled: bool, LogAnonymizationType: any, DnsSecEnabled: bool, CertificateKeyType: any> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update DNS Zones
#
# POST /dnszone/{id}
# operationId: DnsZonePublic_Update
export def "dnszone Update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CustomNameserversEnabled: string@bool-completer # nullable
  --Nameserver1: string # nullable
  --Nameserver2: string # nullable
  --SoaEmail: string # nullable
  --LoggingEnabled: string@bool-completer # nullable
  --LogAnonymizationType: any # Gets the log anonymization type for this zone (nullable)
  --CertificateKeyType: any # Sets the certificate private key type for wildcard certificates for this zone (nullable)
  --LoggingIPAnonymizationEnabled: string@bool-completer # Determines if the log anonoymization should be enabled (nullable)
]: any -> record<Id: int, Domain: string, Records: table<Id: int, Type: int, Ttl: int, Value: string, Name: string, Weight: int, Priority: int, Port: int, Flags: int, Tag: string, Accelerated: bool, AcceleratedPullZoneId: int, LinkName: string, IPGeoLocationInfo: any, GeolocationInfo: any, MonitorStatus: int, MonitorType: int, GeolocationLatitude: float, GeolocationLongitude: float, EnviromentalVariables: list, LatencyZone: string, SmartRoutingType: int, Disabled: bool, Comment: string, AutoSslIssuance: bool, AccelerationStatus: int>, DateModified: string, DateCreated: string, NameserversDetected: bool, CustomNameserversEnabled: bool, Nameserver1: string, Nameserver2: string, SoaEmail: string, NameserversNextCheck: string, LoggingEnabled: bool, LoggingIPAnonymizationEnabled: bool, LogAnonymizationType: any, DnsSecEnabled: bool, CertificateKeyType: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)")
  let body = {CustomNameserversEnabled: $CustomNameserversEnabled, Nameserver1: $Nameserver1, Nameserver2: $Nameserver2, SoaEmail: $SoaEmail, LoggingEnabled: $LoggingEnabled, LogAnonymizationType: $LogAnonymizationType, CertificateKeyType: $CertificateKeyType, LoggingIPAnonymizationEnabled: $LoggingIPAnonymizationEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete DNS Zone
#
# DELETE /dnszone/{id}
# operationId: DnsZonePublic_Delete
export def "dnszone Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /dnszone/{id}/export
#
# operationId: DnsZonePublic_Export
export def "dnszone-export Export" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)/export")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check the DNS zone availability
#
# POST /dnszone/checkavailability
# operationId: DnsZonePublic_CheckAvailability
export def "dnszone-checkavailability CheckAvailability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # Determines the name of the zone that we are checking (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnszone/checkavailability")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add DNS Record
#
# PUT /dnszone/{zoneId}/records
# operationId: DnsZonePublic_AddRecord
# --EnviromentalVariables item shape: {Name?: string, Value?: string}
export def "dnszone-records AddRecord" [
  zoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Type: any # nullable
  --Ttl: int # nullable, format: int32
  --Value: string # nullable
  --Name: string # nullable
  --Weight: int # nullable, format: int32
  --Priority: int # nullable, format: int32
  --Flags: int # nullable, format: byte
  --Tag: string # nullable
  --Port: int # nullable, format: int32
  --PullZoneId: int # nullable, format: int64
  --ScriptId: int # nullable, format: int64
  --Accelerated: string@bool-completer # nullable
  --MonitorType: any # nullable
  --GeolocationLatitude: float # nullable, format: double
  --GeolocationLongitude: float # nullable, format: double
  --LatencyZone: string # nullable
  --SmartRoutingType: any # nullable
  --Disabled: string@bool-completer # nullable
  --EnviromentalVariables: list # nullable — item shape: {Name?: string, Value?: string}
  --Comment: string # nullable
  --AutoSslIssuance: string@bool-completer # nullable
]: any -> record<Id: int, Type: int, Ttl: int, Value: string, Name: string, Weight: int, Priority: int, Port: int, Flags: int, Tag: string, Accelerated: bool, AcceleratedPullZoneId: int, LinkName: string, IPGeoLocationInfo: any, GeolocationInfo: any, MonitorStatus: int, MonitorType: int, GeolocationLatitude: float, GeolocationLongitude: float, EnviromentalVariables: table<Name: string, Value: string>, LatencyZone: string, SmartRoutingType: int, Disabled: bool, Comment: string, AutoSslIssuance: bool, AccelerationStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/records")
  let body = {Type: $Type, Ttl: $Ttl, Value: $Value, Name: $Name, Weight: $Weight, Priority: $Priority, Flags: $Flags, Tag: $Tag, Port: $Port, PullZoneId: $PullZoneId, ScriptId: $ScriptId, Accelerated: $Accelerated, MonitorType: $MonitorType, GeolocationLatitude: $GeolocationLatitude, GeolocationLongitude: $GeolocationLongitude, LatencyZone: $LatencyZone, SmartRoutingType: $SmartRoutingType, Disabled: $Disabled, EnviromentalVariables: $EnviromentalVariables, Comment: $Comment, AutoSslIssuance: $AutoSslIssuance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update DNS Record
#
# POST /dnszone/{zoneId}/records/{id}
# operationId: DnsZonePublic_UpdateRecord
# --EnviromentalVariables item shape: {Name?: string, Value?: string}
export def "dnszone-records UpdateRecord" [
  zoneId: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Type: any # nullable
  --Ttl: int # nullable, format: int32
  --Value: string # nullable
  --Name: string # nullable
  --Weight: int # nullable, format: int32
  --Priority: int # nullable, format: int32
  --Flags: int # nullable, format: byte
  --Tag: string # nullable
  --Port: int # nullable, format: int32
  --PullZoneId: int # nullable, format: int64
  --ScriptId: int # nullable, format: int64
  --Accelerated: string@bool-completer # nullable
  --MonitorType: any # nullable
  --GeolocationLatitude: float # nullable, format: double
  --GeolocationLongitude: float # nullable, format: double
  --LatencyZone: string # nullable
  --SmartRoutingType: any # nullable
  --Disabled: string@bool-completer # nullable
  --EnviromentalVariables: list # nullable — item shape: {Name?: string, Value?: string}
  --Comment: string # nullable
  --AutoSslIssuance: string@bool-completer # nullable
  --Id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/records/($id)")
  let body = {Type: $Type, Ttl: $Ttl, Value: $Value, Name: $Name, Weight: $Weight, Priority: $Priority, Flags: $Flags, Tag: $Tag, Port: $Port, PullZoneId: $PullZoneId, ScriptId: $ScriptId, Accelerated: $Accelerated, MonitorType: $MonitorType, GeolocationLatitude: $GeolocationLatitude, GeolocationLongitude: $GeolocationLongitude, LatencyZone: $LatencyZone, SmartRoutingType: $SmartRoutingType, Disabled: $Disabled, EnviromentalVariables: $EnviromentalVariables, Comment: $Comment, AutoSslIssuance: $AutoSslIssuance, Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete DNS Record
#
# DELETE /dnszone/{zoneId}/records/{id}
# operationId: DnsZonePublic_DeleteRecord
export def "dnszone-records DeleteRecord" [
  zoneId: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/records/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import DNS Records
#
# POST /dnszone/{zoneId}/import
# operationId: DnsZonePublic_Import
export def "dnszone-import Import" [
  zoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<RecordsSuccessful: int, RecordsFailed: int, RecordsSkipped: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/import")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue new wildcard certificate
#
# POST /dnszone/{zoneId}/certificate/issue
# operationId: DnsZonePublic_IssueWildcardCertificate
export def "dnszone-certificate-issue IssueWildcardCertificate" [
  zoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Domain: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/certificate/issue")
  let body = {Domain: $Domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pull Zones
#
# GET /pullzone
# operationId: PullZonePublic_IndexAll
export def "pullzone IndexAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. When set to 0 (default), all items are returned as a plain array. When set to a value greater than 0, items are returned in a paginated response object. (format: int32, default: 0)
  --perPage: int # format: int32, default: 1000
  --search: string # The search term that will be used to filter the results (nullable)
  --includeCertificate: string@bool-completer # Determines if the result hostnames should contain the SSL certificate (default: false)
]: nothing -> table<Id: int, Name: string, OriginUrl: string, Enabled: bool, Suspended: bool, Hostnames: list<record>, StorageZoneId: int, EdgeScriptId: int, EdgeScriptExecutionPhase: any, MiddlewareScriptId: int, MagicContainersAppId: string, MagicContainersEndpointId: string, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockedIps: list<string>, EnableGeoZoneUS: bool, EnableGeoZoneEU: bool, EnableGeoZoneASIA: bool, EnableGeoZoneSA: bool, EnableGeoZoneAF: bool, ZoneSecurityEnabled: bool, ZoneSecurityKey: string, ZoneSecurityIncludeHashRemoteIP: bool, IgnoreQueryStrings: bool, MonthlyBandwidthLimit: int, MonthlyBandwidthUsed: int, MonthlyCharges: float, AddHostHeader: bool, OriginHostHeader: string, Type: any, AccessControlOriginHeaderExtensions: list<string>, EnableAccessControlOriginHeader: bool, DisableCookies: bool, BudgetRedirectedCountries: list<string>, BlockedCountries: list<string>, EnableOriginShield: bool, CacheControlMaxAgeOverride: int, CacheControlPublicMaxAgeOverride: int, BurstSize: int, RequestLimit: int, BlockRootPathAccess: bool, BlockPostRequests: bool, LimitRatePerSecond: float, LimitRateAfter: float, ConnectionLimitPerIPCount: int, PriceOverride: float, OptimizerPricing: float, AddCanonicalHeader: bool, EnableLogging: bool, EnableCacheSlice: bool, EnableSmartCache: bool, EdgeRules: list<record>, EnableWebPVary: bool, EnableAvifVary: bool, EnableCountryCodeVary: bool, EnableCountryStateCodeVary: bool, EnableMobileVary: bool, EnableCookieVary: bool, CookieVaryParameters: list<string>, EnableHostnameVary: bool, CnameDomain: string, AWSSigningEnabled: bool, AWSSigningKey: string, AWSSigningSecret: string, AWSSigningRegionName: string, LoggingIPAnonymizationEnabled: bool, EnableTLS1: bool, EnableTLS1_1: bool, VerifyOriginSSL: bool, ErrorPageEnableCustomCode: bool, ErrorPageCustomCode: string, ErrorPageEnableStatuspageWidget: bool, ErrorPageStatuspageCode: string, ErrorPageWhitelabel: bool, OriginShieldZoneCode: string, LogForwardingEnabled: bool, LogForwardingHostname: string, LogForwardingPort: int, LogForwardingToken: string, LogForwardingProtocol: any, LoggingSaveToStorage: bool, LoggingStorageZoneId: int, FollowRedirects: bool, VideoLibraryId: int, DnsRecordId: int, DnsZoneId: int, DnsRecordValue: string, OptimizerEnabled: bool, OptimizerTunnelEnabled: bool, OptimizerDesktopMaxWidth: int, OptimizerMobileMaxWidth: int, OptimizerImageQuality: int, OptimizerMobileImageQuality: int, OptimizerEnableWebP: bool, OptimizerPrerenderHtml: bool, OptimizerEnableManipulationEngine: bool, OptimizerMinifyCSS: bool, OptimizerMinifyJavaScript: bool, OptimizerWatermarkEnabled: bool, OptimizerWatermarkUrl: string, OptimizerWatermarkPosition: any, OptimizerWatermarkOffset: float, OptimizerWatermarkMinImageSize: int, OptimizerAutomaticOptimizationEnabled: bool, PermaCacheStorageZoneId: int, PermaCacheType: any, OriginRetries: int, OriginConnectTimeout: int, OriginResponseTimeout: int, UseStaleWhileUpdating: bool, UseStaleWhileOffline: bool, OriginRetry5XXResponses: bool, OriginRetryConnectionTimeout: bool, OriginRetryResponseTimeout: bool, OriginRetryDelay: int, QueryStringVaryParameters: list<string>, OriginShieldEnableConcurrencyLimit: bool, OriginShieldMaxConcurrentRequests: int, EnableSafeHop: bool, CacheErrorResponses: bool, OriginShieldQueueMaxWaitTime: int, OriginShieldMaxQueuedRequests: int, OptimizerClasses: list<record>, OptimizerForceClasses: bool, OptimizerStaticHtmlEnabled: bool, OptimizerStaticHtmlWordPressPath: string, OptimizerStaticHtmlWordPressBypassCookie: string, UseBackgroundUpdate: bool, EnableAutoSSL: bool, EnableQueryStringOrdering: bool, LogAnonymizationType: any, LogFormat: int, LogForwardingFormat: int, ShieldDDosProtectionType: int, ShieldDDosProtectionEnabled: bool, OriginType: any, EnableRequestCoalescing: bool, RequestCoalescingTimeout: int, OriginLinkValue: string, DisableLetsEncrypt: bool, EnableBunnyImageAi: bool, BunnyAiImageBlueprints: list<record>, PreloadingScreenEnabled: bool, PreloadingScreenShowOnFirstVisit: bool, PreloadingScreenCode: string, PreloadingScreenLogoUrl: string, PreloadingScreenCodeEnabled: bool, PreloadingScreenTheme: any, PreloadingScreenDelay: int, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, RoutingFilters: list<string>, BlockNoneReferrer: bool, StickySessionType: any, StickySessionCookieName: string, StickySessionClientHeaders: string, UserId: string, CacheVersion: int, OptimizerEnableUpscaling: bool, EnableWebSockets: bool, MaxWebSocketConnections: int, EnableExtendedLogging: bool, CacheKeyHeaders: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "includeCertificate" $includeCertificate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pullzone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Pull Zone
#
# POST /pullzone
# operationId: PullZonePublic_Add
# --OptimizerClasses item shape: {Name?: string, Properties?: record}
# --BunnyAiImageBlueprints item shape: {Name?: string, Properties?: record}
export def "pullzone Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --OriginUrl: string # Sets the origin URL of the Pull Zone (nullable)
  --AllowedReferrers: list # Sets the list of referrer hostnames that are allowed to access the pull zone. Requests containing the header Referer: hostname that is not on the list will be rejected. If empty, all the referrers are allowed (nullable)
  --BlockedReferrers: list # Sets the list of referrer hostnames that are blocked from accessing the pull zone. (nullable)
  --BlockNoneReferrer: string@bool-completer # nullable
  --BlockedIps: list # Sets the list of IPs that are blocked from accessing the pull zone. Requests coming from the following IPs will be rejected. If empty, all the IPs will be allowed (nullable)
  --EnableGeoZoneUS: string@bool-completer # Determines if the delivery from the North America region should be enabled for this pull zone (nullable)
  --EnableGeoZoneEU: string@bool-completer # Determines if the delivery from the Europe region should be enabled for this pull zone (nullable)
  --EnableGeoZoneASIA: string@bool-completer # Determines if the delivery from the Asia / Oceania regions should be enabled for this pull zone (nullable)
  --EnableGeoZoneSA: string@bool-completer # Determines if the delivery from the South America region should be enabled for this pull zone (nullable)
  --EnableGeoZoneAF: string@bool-completer # Determines if the delivery from the Africa region should be enabled for this pull zone (nullable)
  --BlockRootPathAccess: string@bool-completer # Determines if the zone should block requests to the root of the zone. (nullable)
  --BlockPostRequests: string@bool-completer # Determines if the POST requests to this zone should be rejected. (nullable)
  --EnableQueryStringOrdering: string@bool-completer # Determines if the query string ordering should be enabled. (nullable)
  --EnableWebpVary: string@bool-completer # Determines if the WebP Vary feature should be enabled. (nullable)
  --EnableAvifVary: string@bool-completer # Determines if the AVIF Vary feature should be enabled. (nullable)
  --EnableMobileVary: string@bool-completer # Determines if the Mobile Vary feature is enabled. (nullable)
  --EnableCountryCodeVary: string@bool-completer # Determines if the Country Code Vary feature should be enabled. (nullable)
  --EnableCountryStateCodeVary: string@bool-completer # Determines if the Country State Code Vary feature should be enabled. (nullable)
  --EnableHostnameVary: string@bool-completer # Determines if the Hostname Vary feature should be enabled. (nullable)
  --EnableCacheSlice: string@bool-completer # Determines if cache slicing (Optimize for video) should be enabled for this zone (nullable)
  --ZoneSecurityEnabled: string@bool-completer # Determines if the zone token authentication security should be enabled (nullable)
  --ZoneSecurityIncludeHashRemoteIP: string@bool-completer # Determines if the token authentication IP validation should be enabled (nullable)
  --IgnoreQueryStrings: string@bool-completer # Determines if the Pull Zone should ignore query strings when serving cached objects (Vary by Query String) (nullable)
  --MonthlyBandwidthLimit: int # Sets the monthly limit of bandwidth in bytes that the pullzone is allowed to use (nullable, format: int64)
  --AccessControlOriginHeaderExtensions: list # Sets the list of extensions that will return the CORS headers (nullable)
  --EnableAccessControlOriginHeader: string@bool-completer # Determines if CORS headers should be enabled (nullable)
  --DisableCookies: string@bool-completer # Determines if the Pull Zone should automatically remove cookies from the responses (nullable)
  --BudgetRedirectedCountries: list # Sets the list of two letter Alpha2 country codes that will be redirected to the cheapest possible region (nullable)
  --BlockedCountries: list # Sets the list of two letter Alpha2 country codes that will be blocked from accessing the zone (nullable)
  --CacheControlMaxAgeOverride: int # Sets the cache control override setting for this zone (nullable, format: int64)
  --CacheControlPublicMaxAgeOverride: int # Sets the browser cache control override setting for this zone (nullable, format: int64)
  --CacheControlBrowserMaxAgeOverride: int # (Deprecated) Sets the browser cache control override setting for this zone (nullable, format: int64)
  --AddHostHeader: string@bool-completer # Determines if the zone should forward the requested host header to the origin (nullable)
  --AddCanonicalHeader: string@bool-completer # Determines if the canonical header should be added by this zone (nullable)
  --EnableLogging: string@bool-completer # Determines if the logging should be enabled for this zone (nullable)
  --LoggingIPAnonymizationEnabled: string@bool-completer # Determines if the log anonoymization should be enabled (nullable)
  --PermaCacheStorageZoneId: int # The ID of the storage zone that should be used as the Perma-Cache (nullable, format: int64)
  --PermaCacheType: any # Determines Perma-Cache behavior (nullable)
  --AWSSigningEnabled: string@bool-completer # Determines if the AWS signing should be enabled or not (nullable)
  --AWSSigningKey: string # Sets the AWS signing key (nullable)
  --AWSSigningRegionName: string # Sets the AWS signing region name (nullable)
  --AWSSigningSecret: string # Sets the AWS signing secret key (nullable)
  --EnableOriginShield: string@bool-completer # Determines if the origin shield should be enabled (nullable)
  --OriginShieldZoneCode: string # Determines the zone code where the origin shield should be set up (nullable)
  --EnableTLS1: string@bool-completer # Determines if the TLS 1 should be enabled on this zone (nullable)
  --EnableTLS1-1: string@bool-completer # Determines if the TLS 1.1 should be enabled on this zone (nullable)
  --CacheErrorResponses: string@bool-completer # Determines if the cache error responses should be enabled on the zone (nullable)
  --VerifyOriginSSL: string@bool-completer # Determines if the SSL certificate should be verified when connecting to the origin (nullable)
  --LogForwardingEnabled: string@bool-completer # Sets the log forwarding token for the zone (nullable)
  --LogForwardingHostname: string # Sets the log forwarding destination hostname for the zone (nullable)
  --LogForwardingPort: int # Sets the log forwarding port for the zone (nullable, format: int32)
  --LogForwardingToken: string # Sets the log forwarding token for the zone (nullable)
  --LogForwardingProtocol: any # Sets the log forwarding protocol type (nullable)
  --LoggingSaveToStorage: string@bool-completer # Determines if the logging permanent storage should be enabled (nullable)
  --LoggingStorageZoneId: int # Sets the Storage Zone id that should contain the logs from this Pull Zone (nullable, format: int64)
  --FollowRedirects: string@bool-completer # Determines if the zone should follow redirects return by the oprigin and cache the response (nullable)
  --ConnectionLimitPerIPCount: int # Determines the maximum number of connections per IP that will be allowed to connect to this Pull Zone (nullable, format: int32)
  --RequestLimit: int # Determines the maximum number of requests per second that will be allowed to connect to this Pull Zone (nullable, format: int32)
  --LimitRateAfter: float # Determines the amount of traffic transferred before the client is limited (nullable, format: double)
  --LimitRatePerSecond: int # Determines the maximum number of requests per second coming from a single IP before it is blocked. (nullable, format: int32)
  --BurstSize: int # Determines the maximum burst requests before an IP is blocked (nullable, format: int32)
  --ErrorPageEnableCustomCode: string@bool-completer # Determines if custom error page code should be enabled. (nullable)
  --ErrorPageCustomCode: string # Contains the custom error page code that will be returned (nullable)
  --ErrorPageEnableStatuspageWidget: string@bool-completer # Determines if the statuspage widget should be displayed on the error pages (nullable)
  --ErrorPageStatuspageCode: string # The statuspage code that will be used to build the status widget (nullable)
  --ErrorPageWhitelabel: string@bool-completer # Determines if the error pages should be whitelabel or not (nullable)
  --OptimizerEnabled: string@bool-completer # Determines if the optimizer should be enabled for this zone (nullable)
  --OptimizerTunnelEnabled: string@bool-completer # Determines if the optimizer origin tunnel system should be enabled for this zone (nullable)
  --OptimizerDesktopMaxWidth: int # Determines the maximum automatic image size for desktop clients (nullable, format: int32)
  --OptimizerMobileMaxWidth: int # Determines the maximum automatic image size for mobile clients (nullable, format: int32)
  --OptimizerImageQuality: int # Determines the image quality for desktop clients (nullable, format: int32)
  --OptimizerMobileImageQuality: int # Determines the image quality for mobile clients (nullable, format: int32)
  --OptimizerEnableWebP: string@bool-completer # Determines if the WebP optimization should be enabled (nullable)
  --OptimizerPrerenderHtml: string@bool-completer # Determines if the SEO HTML prerender should be enabled (nullable)
  --OptimizerEnableManipulationEngine: string@bool-completer # Determines the image manipulation should be enabled (nullable)
  --OptimizerMinifyCSS: string@bool-completer # Determines if the CSS minifcation should be enabled (nullable)
  --OptimizerMinifyJavaScript: string@bool-completer # Determines if the JavaScript minifcation should be enabled (nullable)
  --OptimizerWatermarkEnabled: string@bool-completer # Determines if image watermarking should be enabled (nullable)
  --OptimizerWatermarkUrl: string # Sets the URL of the watermark image (nullable)
  --OptimizerWatermarkPosition: any # Sets the position of the watermark image (nullable)
  --OptimizerWatermarkOffset: float # Sets the offset of the watermark image (nullable, format: double)
  --OptimizerWatermarkMinImageSize: int # Sets the minimum image size to which the watermark will be added (nullable, format: int32)
  --OptimizerAutomaticOptimizationEnabled: string@bool-completer # Determines if the automatic image optimization should be enabled (nullable)
  --OptimizerClasses: list # Determines the list of optimizer classes (nullable) — item shape: {Name?: string, Properties?: record}
  --OptimizerForceClasses: string@bool-completer # Determines if the optimizer classes should be forced (nullable)
  --OptimizerStaticHtmlEnabled: string@bool-completer # Determines whether optimizer static html feature enabled (nullable)
  --OptimizerStaticHtmlWordPressPath: string # Wordpress html path which should be bypassed by permacache in edge rule (nullable)
  --OptimizerStaticHtmlWordPressBypassCookie: string # Wordpress cookie which should be bypassed by permacache in edge rule (nullable)
  --Type: any # The type of the pull zone. Premium = 0, Volume = 1 (nullable)
  --OriginRetries: int # The number of retries to the origin server (nullable, format: int32)
  --OriginConnectTimeout: int # The amount of seconds to wait when connecting to the origin. Otherwise the request will fail or retry. (nullable, format: int32)
  --OriginResponseTimeout: int # The amount of seconds to wait when waiting for the origin reply. Otherwise the request will fail or retry. (nullable, format: int32)
  --UseStaleWhileUpdating: string@bool-completer # Determines if we should use stale cache while cache is updating (nullable)
  --UseStaleWhileOffline: string@bool-completer # Determines if we should use stale cache while the origin is offline (nullable)
  --OriginRetry5XXResponses: string@bool-completer # Determines if we should retry the request in case of a 5XX response. (nullable)
  --OriginRetryConnectionTimeout: string@bool-completer # Determines if we should retry the request in case of a connection timeout. (nullable)
  --OriginRetryResponseTimeout: string@bool-completer # Determines if we should retry the request in case of a response timeout. (nullable)
  --OriginRetryDelay: int # Determines the amount of time that the CDN should wait before retrying an origin request. (nullable, format: int32)
  --DnsOriginPort: int # Determines the origin port of the pull zone. (nullable, format: int32)
  --DnsOriginScheme: string # Determines the origin scheme of the pull zone. (nullable)
  --QueryStringVaryParameters: list # Contains the list of vary parameters that will be used for vary cache by query string. Only alphanumeric characters, dashes and underscores are allowed (values that contain other characters are ignorred). If empty, all parameters will be used to construct the key. (nullable)
  --OriginShieldEnableConcurrencyLimit: string@bool-completer # Determines if the origin shield concurrency limit is enabled. (nullable)
  --OriginShieldMaxConcurrentRequests: int # Determines the number of maximum concurrent requests allowed to the origin. (nullable, format: int32)
  --EnableCookieVary: string@bool-completer # Determines if the Cookie Vary feature is enabled. (nullable)
  --CookieVaryParameters: list # Contains the list of vary parameters that will be used for vary cache by cookie string.Only alphanumeric characters, dashes and underscores are allowed (values that contain other characters are ignorred). If empty, cookie vary will not be used. (nullable)
  --EnableSafeHop: string@bool-completer # nullable
  --OriginShieldQueueMaxWaitTime: int # Determines the max queue wait time (nullable, format: int32)
  --OriginShieldMaxQueuedRequests: int # Determines the max number of origin requests that will remain in the queue (nullable, format: int32)
  --UseBackgroundUpdate: string@bool-completer # Determines if cache update is performed in the background. (nullable)
  --EnableAutoSSL: string@bool-completer # If set to true, any hostnames added to this Pull Zone will automatically enable SSL. (nullable)
  --LogAnonymizationType: any # Sets the log anonymization type for this pull zone (nullable)
  --StorageZoneId: int # The ID of the storage zone that will be used as the origin (nullable, format: int64)
  --EdgeScriptId: int # The ID of the edge script that will be used as the origin (nullable, format: int64)
  --MiddlewareScriptId: int # The ID of the middleware script (nullable, format: int64)
  --EdgeScriptExecutionPhase: any # The execution phase of the edge script (nullable)
  --OriginType: any # Determine the type of the origin for this Pull Zone (nullable)
  --MagicContainersAppId: string # nullable
  --MagicContainersEndpointId: string # nullable
  --LogFormat: any # nullable
  --LogForwardingFormat: any # nullable
  --ShieldDDosProtectionType: any # nullable
  --ShieldDDosProtectionEnabled: string@bool-completer # nullable
  --OriginHostHeader: string # Sets the host header that will be sent to the origin (nullable)
  --EnableSmartCache: string@bool-completer # nullable
  --EnableRequestCoalescing: string@bool-completer # Determines if request coalescing is currently enabled. (nullable)
  --RequestCoalescingTimeout: int # Determines the lock time for coalesced requests. (nullable, format: int32)
  --DisableLetsEncrypt: string@bool-completer # If set to true, the built-in let's encrypt will be disabled and requests are passed to the origin. (nullable)
  --EnableBunnyImageAi: string@bool-completer # nullable
  --BunnyAiImageBlueprints: list # nullable — item shape: {Name?: string, Properties?: record}
  --PreloadingScreenEnabled: string@bool-completer # Determines if the preloading screen is currently enabled (nullable)
  --PreloadingScreenCode: string # The custom preloading screen coed (nullable)
  --PreloadingScreenLogoUrl: string # The preloading screen logo URL (nullable)
  --PreloadingScreenShowOnFirstVisit: string@bool-completer # Determines if the preloading screen is shown on the first load from a user.
  --PreloadingScreenTheme: any # The currently configured preloading screem theme. (0 - Light, 1 - Dark) (nullable)
  --PreloadingScreenCodeEnabled: string@bool-completer # Determines if the custom preloader screen should be enabled (nullable)
  --PreloadingScreenDelay: int # The delay in miliseconds after which the preloading screen will be displayed (0 - 10000ms) (nullable, format: int32)
  --RoutingFilters: list # The list of routing filters enabled for this zone (nullable)
  --StickySessionType: any # Whether to use a Sticky Session mechanism for this pull zone (nullable)
  --StickySessionCookieName: string # Sticky Session Cookie Name (nullable)
  --StickySessionClientHeaders: string # A set of comma-separated header names used to identify clients (nullable)
  --OptimizerEnableUpscaling: string@bool-completer # Determines if Optimizer is allowed to upscale images (nullable)
  --EnableWebSockets: string@bool-completer # Determines if WebSocket connections are allowed for this Pull Zone. (nullable)
  --MaxWebSocketConnections: int # The maximum global simultaneous WebSocket connections allowed for this Pull Zone. Allowed tiers: 500, 1,000, 2,500, 5,000, 10,000, 25,000. If you send a non-tier value, the value is rounded up to the next tier. Values over 25,000 are rejected, please contact sales if required. (nullable, format: int32)
  --CacheKeyHeaders: string # Vary Cache by Request Headers (comma delimited) (nullable)
  Name: string # The name of the pull zone.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pullzone")
  let body = {OriginUrl: $OriginUrl, AllowedReferrers: $AllowedReferrers, BlockedReferrers: $BlockedReferrers, BlockNoneReferrer: $BlockNoneReferrer, BlockedIps: $BlockedIps, EnableGeoZoneUS: $EnableGeoZoneUS, EnableGeoZoneEU: $EnableGeoZoneEU, EnableGeoZoneASIA: $EnableGeoZoneASIA, EnableGeoZoneSA: $EnableGeoZoneSA, EnableGeoZoneAF: $EnableGeoZoneAF, BlockRootPathAccess: $BlockRootPathAccess, BlockPostRequests: $BlockPostRequests, EnableQueryStringOrdering: $EnableQueryStringOrdering, EnableWebpVary: $EnableWebpVary, EnableAvifVary: $EnableAvifVary, EnableMobileVary: $EnableMobileVary, EnableCountryCodeVary: $EnableCountryCodeVary, EnableCountryStateCodeVary: $EnableCountryStateCodeVary, EnableHostnameVary: $EnableHostnameVary, EnableCacheSlice: $EnableCacheSlice, ZoneSecurityEnabled: $ZoneSecurityEnabled, ZoneSecurityIncludeHashRemoteIP: $ZoneSecurityIncludeHashRemoteIP, IgnoreQueryStrings: $IgnoreQueryStrings, MonthlyBandwidthLimit: $MonthlyBandwidthLimit, AccessControlOriginHeaderExtensions: $AccessControlOriginHeaderExtensions, EnableAccessControlOriginHeader: $EnableAccessControlOriginHeader, DisableCookies: $DisableCookies, BudgetRedirectedCountries: $BudgetRedirectedCountries, BlockedCountries: $BlockedCountries, CacheControlMaxAgeOverride: $CacheControlMaxAgeOverride, CacheControlPublicMaxAgeOverride: $CacheControlPublicMaxAgeOverride, CacheControlBrowserMaxAgeOverride: $CacheControlBrowserMaxAgeOverride, AddHostHeader: $AddHostHeader, AddCanonicalHeader: $AddCanonicalHeader, EnableLogging: $EnableLogging, LoggingIPAnonymizationEnabled: $LoggingIPAnonymizationEnabled, PermaCacheStorageZoneId: $PermaCacheStorageZoneId, PermaCacheType: $PermaCacheType, AWSSigningEnabled: $AWSSigningEnabled, AWSSigningKey: $AWSSigningKey, AWSSigningRegionName: $AWSSigningRegionName, AWSSigningSecret: $AWSSigningSecret, EnableOriginShield: $EnableOriginShield, OriginShieldZoneCode: $OriginShieldZoneCode, EnableTLS1: $EnableTLS1, EnableTLS1_1: $EnableTLS1_1, CacheErrorResponses: $CacheErrorResponses, VerifyOriginSSL: $VerifyOriginSSL, LogForwardingEnabled: $LogForwardingEnabled, LogForwardingHostname: $LogForwardingHostname, LogForwardingPort: $LogForwardingPort, LogForwardingToken: $LogForwardingToken, LogForwardingProtocol: $LogForwardingProtocol, LoggingSaveToStorage: $LoggingSaveToStorage, LoggingStorageZoneId: $LoggingStorageZoneId, FollowRedirects: $FollowRedirects, ConnectionLimitPerIPCount: $ConnectionLimitPerIPCount, RequestLimit: $RequestLimit, LimitRateAfter: $LimitRateAfter, LimitRatePerSecond: $LimitRatePerSecond, BurstSize: $BurstSize, ErrorPageEnableCustomCode: $ErrorPageEnableCustomCode, ErrorPageCustomCode: $ErrorPageCustomCode, ErrorPageEnableStatuspageWidget: $ErrorPageEnableStatuspageWidget, ErrorPageStatuspageCode: $ErrorPageStatuspageCode, ErrorPageWhitelabel: $ErrorPageWhitelabel, OptimizerEnabled: $OptimizerEnabled, OptimizerTunnelEnabled: $OptimizerTunnelEnabled, OptimizerDesktopMaxWidth: $OptimizerDesktopMaxWidth, OptimizerMobileMaxWidth: $OptimizerMobileMaxWidth, OptimizerImageQuality: $OptimizerImageQuality, OptimizerMobileImageQuality: $OptimizerMobileImageQuality, OptimizerEnableWebP: $OptimizerEnableWebP, OptimizerPrerenderHtml: $OptimizerPrerenderHtml, OptimizerEnableManipulationEngine: $OptimizerEnableManipulationEngine, OptimizerMinifyCSS: $OptimizerMinifyCSS, OptimizerMinifyJavaScript: $OptimizerMinifyJavaScript, OptimizerWatermarkEnabled: $OptimizerWatermarkEnabled, OptimizerWatermarkUrl: $OptimizerWatermarkUrl, OptimizerWatermarkPosition: $OptimizerWatermarkPosition, OptimizerWatermarkOffset: $OptimizerWatermarkOffset, OptimizerWatermarkMinImageSize: $OptimizerWatermarkMinImageSize, OptimizerAutomaticOptimizationEnabled: $OptimizerAutomaticOptimizationEnabled, OptimizerClasses: $OptimizerClasses, OptimizerForceClasses: $OptimizerForceClasses, OptimizerStaticHtmlEnabled: $OptimizerStaticHtmlEnabled, OptimizerStaticHtmlWordPressPath: $OptimizerStaticHtmlWordPressPath, OptimizerStaticHtmlWordPressBypassCookie: $OptimizerStaticHtmlWordPressBypassCookie, Type: $Type, OriginRetries: $OriginRetries, OriginConnectTimeout: $OriginConnectTimeout, OriginResponseTimeout: $OriginResponseTimeout, UseStaleWhileUpdating: $UseStaleWhileUpdating, UseStaleWhileOffline: $UseStaleWhileOffline, OriginRetry5XXResponses: $OriginRetry5XXResponses, OriginRetryConnectionTimeout: $OriginRetryConnectionTimeout, OriginRetryResponseTimeout: $OriginRetryResponseTimeout, OriginRetryDelay: $OriginRetryDelay, DnsOriginPort: $DnsOriginPort, DnsOriginScheme: $DnsOriginScheme, QueryStringVaryParameters: $QueryStringVaryParameters, OriginShieldEnableConcurrencyLimit: $OriginShieldEnableConcurrencyLimit, OriginShieldMaxConcurrentRequests: $OriginShieldMaxConcurrentRequests, EnableCookieVary: $EnableCookieVary, CookieVaryParameters: $CookieVaryParameters, EnableSafeHop: $EnableSafeHop, OriginShieldQueueMaxWaitTime: $OriginShieldQueueMaxWaitTime, OriginShieldMaxQueuedRequests: $OriginShieldMaxQueuedRequests, UseBackgroundUpdate: $UseBackgroundUpdate, EnableAutoSSL: $EnableAutoSSL, LogAnonymizationType: $LogAnonymizationType, StorageZoneId: $StorageZoneId, EdgeScriptId: $EdgeScriptId, MiddlewareScriptId: $MiddlewareScriptId, EdgeScriptExecutionPhase: $EdgeScriptExecutionPhase, OriginType: $OriginType, MagicContainersAppId: $MagicContainersAppId, MagicContainersEndpointId: $MagicContainersEndpointId, LogFormat: $LogFormat, LogForwardingFormat: $LogForwardingFormat, ShieldDDosProtectionType: $ShieldDDosProtectionType, ShieldDDosProtectionEnabled: $ShieldDDosProtectionEnabled, OriginHostHeader: $OriginHostHeader, EnableSmartCache: $EnableSmartCache, EnableRequestCoalescing: $EnableRequestCoalescing, RequestCoalescingTimeout: $RequestCoalescingTimeout, DisableLetsEncrypt: $DisableLetsEncrypt, EnableBunnyImageAi: $EnableBunnyImageAi, BunnyAiImageBlueprints: $BunnyAiImageBlueprints, PreloadingScreenEnabled: $PreloadingScreenEnabled, PreloadingScreenCode: $PreloadingScreenCode, PreloadingScreenLogoUrl: $PreloadingScreenLogoUrl, PreloadingScreenShowOnFirstVisit: $PreloadingScreenShowOnFirstVisit, PreloadingScreenTheme: $PreloadingScreenTheme, PreloadingScreenCodeEnabled: $PreloadingScreenCodeEnabled, PreloadingScreenDelay: $PreloadingScreenDelay, RoutingFilters: $RoutingFilters, StickySessionType: $StickySessionType, StickySessionCookieName: $StickySessionCookieName, StickySessionClientHeaders: $StickySessionClientHeaders, OptimizerEnableUpscaling: $OptimizerEnableUpscaling, EnableWebSockets: $EnableWebSockets, MaxWebSocketConnections: $MaxWebSocketConnections, CacheKeyHeaders: $CacheKeyHeaders, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Pull Zones
#
# GET /pullzone/count
# operationId: PullZonePublic_Count
export def "pullzone-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Count: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pullzone/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pull Zone
#
# GET /pullzone/{id}
# operationId: PullZonePublic_Index
export def "pullzone Index" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeCertificate: string@bool-completer # Determines if the result hostnames should contain the SSL certificate (default: false)
]: nothing -> record<Id: int, Name: string, OriginUrl: string, Enabled: bool, Suspended: bool, Hostnames: table<Id: int, Value: string, ForceSSL: bool, IsSystemHostname: bool, IsManagedHostname: bool, HasCertificate: bool, Certificate: string, CertificateKey: string, CertificateKeyType: any, CertificateProvisionType: any>, StorageZoneId: int, EdgeScriptId: int, EdgeScriptExecutionPhase: any, MiddlewareScriptId: int, MagicContainersAppId: string, MagicContainersEndpointId: string, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockedIps: list<string>, EnableGeoZoneUS: bool, EnableGeoZoneEU: bool, EnableGeoZoneASIA: bool, EnableGeoZoneSA: bool, EnableGeoZoneAF: bool, ZoneSecurityEnabled: bool, ZoneSecurityKey: string, ZoneSecurityIncludeHashRemoteIP: bool, IgnoreQueryStrings: bool, MonthlyBandwidthLimit: int, MonthlyBandwidthUsed: int, MonthlyCharges: float, AddHostHeader: bool, OriginHostHeader: string, Type: any, AccessControlOriginHeaderExtensions: list<string>, EnableAccessControlOriginHeader: bool, DisableCookies: bool, BudgetRedirectedCountries: list<string>, BlockedCountries: list<string>, EnableOriginShield: bool, CacheControlMaxAgeOverride: int, CacheControlPublicMaxAgeOverride: int, BurstSize: int, RequestLimit: int, BlockRootPathAccess: bool, BlockPostRequests: bool, LimitRatePerSecond: float, LimitRateAfter: float, ConnectionLimitPerIPCount: int, PriceOverride: float, OptimizerPricing: float, AddCanonicalHeader: bool, EnableLogging: bool, EnableCacheSlice: bool, EnableSmartCache: bool, EdgeRules: table<Guid: string, ActionType: any, ActionParameter1: string, ActionParameter2: string, ActionParameter3: string, Triggers: list, ExtraActions: list, TriggerMatchingType: any, Description: string, Enabled: bool, OrderIndex: int, ReadOnly: bool>, EnableWebPVary: bool, EnableAvifVary: bool, EnableCountryCodeVary: bool, EnableCountryStateCodeVary: bool, EnableMobileVary: bool, EnableCookieVary: bool, CookieVaryParameters: list<string>, EnableHostnameVary: bool, CnameDomain: string, AWSSigningEnabled: bool, AWSSigningKey: string, AWSSigningSecret: string, AWSSigningRegionName: string, LoggingIPAnonymizationEnabled: bool, EnableTLS1: bool, EnableTLS1_1: bool, VerifyOriginSSL: bool, ErrorPageEnableCustomCode: bool, ErrorPageCustomCode: string, ErrorPageEnableStatuspageWidget: bool, ErrorPageStatuspageCode: string, ErrorPageWhitelabel: bool, OriginShieldZoneCode: string, LogForwardingEnabled: bool, LogForwardingHostname: string, LogForwardingPort: int, LogForwardingToken: string, LogForwardingProtocol: any, LoggingSaveToStorage: bool, LoggingStorageZoneId: int, FollowRedirects: bool, VideoLibraryId: int, DnsRecordId: int, DnsZoneId: int, DnsRecordValue: string, OptimizerEnabled: bool, OptimizerTunnelEnabled: bool, OptimizerDesktopMaxWidth: int, OptimizerMobileMaxWidth: int, OptimizerImageQuality: int, OptimizerMobileImageQuality: int, OptimizerEnableWebP: bool, OptimizerPrerenderHtml: bool, OptimizerEnableManipulationEngine: bool, OptimizerMinifyCSS: bool, OptimizerMinifyJavaScript: bool, OptimizerWatermarkEnabled: bool, OptimizerWatermarkUrl: string, OptimizerWatermarkPosition: any, OptimizerWatermarkOffset: float, OptimizerWatermarkMinImageSize: int, OptimizerAutomaticOptimizationEnabled: bool, PermaCacheStorageZoneId: int, PermaCacheType: any, OriginRetries: int, OriginConnectTimeout: int, OriginResponseTimeout: int, UseStaleWhileUpdating: bool, UseStaleWhileOffline: bool, OriginRetry5XXResponses: bool, OriginRetryConnectionTimeout: bool, OriginRetryResponseTimeout: bool, OriginRetryDelay: int, QueryStringVaryParameters: list<string>, OriginShieldEnableConcurrencyLimit: bool, OriginShieldMaxConcurrentRequests: int, EnableSafeHop: bool, CacheErrorResponses: bool, OriginShieldQueueMaxWaitTime: int, OriginShieldMaxQueuedRequests: int, OptimizerClasses: table<Name: string, Properties: record>, OptimizerForceClasses: bool, OptimizerStaticHtmlEnabled: bool, OptimizerStaticHtmlWordPressPath: string, OptimizerStaticHtmlWordPressBypassCookie: string, UseBackgroundUpdate: bool, EnableAutoSSL: bool, EnableQueryStringOrdering: bool, LogAnonymizationType: any, LogFormat: int, LogForwardingFormat: int, ShieldDDosProtectionType: int, ShieldDDosProtectionEnabled: bool, OriginType: any, EnableRequestCoalescing: bool, RequestCoalescingTimeout: int, OriginLinkValue: string, DisableLetsEncrypt: bool, EnableBunnyImageAi: bool, BunnyAiImageBlueprints: table<Name: string, Properties: record>, PreloadingScreenEnabled: bool, PreloadingScreenShowOnFirstVisit: bool, PreloadingScreenCode: string, PreloadingScreenLogoUrl: string, PreloadingScreenCodeEnabled: bool, PreloadingScreenTheme: any, PreloadingScreenDelay: int, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, RoutingFilters: list<string>, BlockNoneReferrer: bool, StickySessionType: any, StickySessionCookieName: string, StickySessionClientHeaders: string, UserId: string, CacheVersion: int, OptimizerEnableUpscaling: bool, EnableWebSockets: bool, MaxWebSocketConnections: int, EnableExtendedLogging: bool, CacheKeyHeaders: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCertificate" $includeCertificate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pullzone/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Pull Zone
#
# POST /pullzone/{id}
# operationId: PullZonePublic_UpdatePullZone
# --OptimizerClasses item shape: {Name?: string, Properties?: record}
# --BunnyAiImageBlueprints item shape: {Name?: string, Properties?: record}
export def "pullzone UpdatePullZone" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --OriginUrl: string # Sets the origin URL of the Pull Zone (nullable)
  --AllowedReferrers: list # Sets the list of referrer hostnames that are allowed to access the pull zone. Requests containing the header Referer: hostname that is not on the list will be rejected. If empty, all the referrers are allowed (nullable)
  --BlockedReferrers: list # Sets the list of referrer hostnames that are blocked from accessing the pull zone. (nullable)
  --BlockNoneReferrer: string@bool-completer # nullable
  --BlockedIps: list # Sets the list of IPs that are blocked from accessing the pull zone. Requests coming from the following IPs will be rejected. If empty, all the IPs will be allowed (nullable)
  --EnableGeoZoneUS: string@bool-completer # Determines if the delivery from the North America region should be enabled for this pull zone (nullable)
  --EnableGeoZoneEU: string@bool-completer # Determines if the delivery from the Europe region should be enabled for this pull zone (nullable)
  --EnableGeoZoneASIA: string@bool-completer # Determines if the delivery from the Asia / Oceania regions should be enabled for this pull zone (nullable)
  --EnableGeoZoneSA: string@bool-completer # Determines if the delivery from the South America region should be enabled for this pull zone (nullable)
  --EnableGeoZoneAF: string@bool-completer # Determines if the delivery from the Africa region should be enabled for this pull zone (nullable)
  --BlockRootPathAccess: string@bool-completer # Determines if the zone should block requests to the root of the zone. (nullable)
  --BlockPostRequests: string@bool-completer # Determines if the POST requests to this zone should be rejected. (nullable)
  --EnableQueryStringOrdering: string@bool-completer # Determines if the query string ordering should be enabled. (nullable)
  --EnableWebpVary: string@bool-completer # Determines if the WebP Vary feature should be enabled. (nullable)
  --EnableAvifVary: string@bool-completer # Determines if the AVIF Vary feature should be enabled. (nullable)
  --EnableMobileVary: string@bool-completer # Determines if the Mobile Vary feature is enabled. (nullable)
  --EnableCountryCodeVary: string@bool-completer # Determines if the Country Code Vary feature should be enabled. (nullable)
  --EnableCountryStateCodeVary: string@bool-completer # Determines if the Country State Code Vary feature should be enabled. (nullable)
  --EnableHostnameVary: string@bool-completer # Determines if the Hostname Vary feature should be enabled. (nullable)
  --EnableCacheSlice: string@bool-completer # Determines if cache slicing (Optimize for video) should be enabled for this zone (nullable)
  --ZoneSecurityEnabled: string@bool-completer # Determines if the zone token authentication security should be enabled (nullable)
  --ZoneSecurityIncludeHashRemoteIP: string@bool-completer # Determines if the token authentication IP validation should be enabled (nullable)
  --IgnoreQueryStrings: string@bool-completer # Determines if the Pull Zone should ignore query strings when serving cached objects (Vary by Query String) (nullable)
  --MonthlyBandwidthLimit: int # Sets the monthly limit of bandwidth in bytes that the pullzone is allowed to use (nullable, format: int64)
  --AccessControlOriginHeaderExtensions: list # Sets the list of extensions that will return the CORS headers (nullable)
  --EnableAccessControlOriginHeader: string@bool-completer # Determines if CORS headers should be enabled (nullable)
  --DisableCookies: string@bool-completer # Determines if the Pull Zone should automatically remove cookies from the responses (nullable)
  --BudgetRedirectedCountries: list # Sets the list of two letter Alpha2 country codes that will be redirected to the cheapest possible region (nullable)
  --BlockedCountries: list # Sets the list of two letter Alpha2 country codes that will be blocked from accessing the zone (nullable)
  --CacheControlMaxAgeOverride: int # Sets the cache control override setting for this zone (nullable, format: int64)
  --CacheControlPublicMaxAgeOverride: int # Sets the browser cache control override setting for this zone (nullable, format: int64)
  --CacheControlBrowserMaxAgeOverride: int # (Deprecated) Sets the browser cache control override setting for this zone (nullable, format: int64)
  --AddHostHeader: string@bool-completer # Determines if the zone should forward the requested host header to the origin (nullable)
  --AddCanonicalHeader: string@bool-completer # Determines if the canonical header should be added by this zone (nullable)
  --EnableLogging: string@bool-completer # Determines if the logging should be enabled for this zone (nullable)
  --LoggingIPAnonymizationEnabled: string@bool-completer # Determines if the log anonoymization should be enabled (nullable)
  --PermaCacheStorageZoneId: int # The ID of the storage zone that should be used as the Perma-Cache (nullable, format: int64)
  --PermaCacheType: any # Determines Perma-Cache behavior (nullable)
  --AWSSigningEnabled: string@bool-completer # Determines if the AWS signing should be enabled or not (nullable)
  --AWSSigningKey: string # Sets the AWS signing key (nullable)
  --AWSSigningRegionName: string # Sets the AWS signing region name (nullable)
  --AWSSigningSecret: string # Sets the AWS signing secret key (nullable)
  --EnableOriginShield: string@bool-completer # Determines if the origin shield should be enabled (nullable)
  --OriginShieldZoneCode: string # Determines the zone code where the origin shield should be set up (nullable)
  --EnableTLS1: string@bool-completer # Determines if the TLS 1 should be enabled on this zone (nullable)
  --EnableTLS1-1: string@bool-completer # Determines if the TLS 1.1 should be enabled on this zone (nullable)
  --CacheErrorResponses: string@bool-completer # Determines if the cache error responses should be enabled on the zone (nullable)
  --VerifyOriginSSL: string@bool-completer # Determines if the SSL certificate should be verified when connecting to the origin (nullable)
  --LogForwardingEnabled: string@bool-completer # Sets the log forwarding token for the zone (nullable)
  --LogForwardingHostname: string # Sets the log forwarding destination hostname for the zone (nullable)
  --LogForwardingPort: int # Sets the log forwarding port for the zone (nullable, format: int32)
  --LogForwardingToken: string # Sets the log forwarding token for the zone (nullable)
  --LogForwardingProtocol: any # Sets the log forwarding protocol type (nullable)
  --LoggingSaveToStorage: string@bool-completer # Determines if the logging permanent storage should be enabled (nullable)
  --LoggingStorageZoneId: int # Sets the Storage Zone id that should contain the logs from this Pull Zone (nullable, format: int64)
  --FollowRedirects: string@bool-completer # Determines if the zone should follow redirects return by the oprigin and cache the response (nullable)
  --ConnectionLimitPerIPCount: int # Determines the maximum number of connections per IP that will be allowed to connect to this Pull Zone (nullable, format: int32)
  --RequestLimit: int # Determines the maximum number of requests per second that will be allowed to connect to this Pull Zone (nullable, format: int32)
  --LimitRateAfter: float # Determines the amount of traffic transferred before the client is limited (nullable, format: double)
  --LimitRatePerSecond: int # Determines the maximum number of requests per second coming from a single IP before it is blocked. (nullable, format: int32)
  --BurstSize: int # Determines the maximum burst requests before an IP is blocked (nullable, format: int32)
  --ErrorPageEnableCustomCode: string@bool-completer # Determines if custom error page code should be enabled. (nullable)
  --ErrorPageCustomCode: string # Contains the custom error page code that will be returned (nullable)
  --ErrorPageEnableStatuspageWidget: string@bool-completer # Determines if the statuspage widget should be displayed on the error pages (nullable)
  --ErrorPageStatuspageCode: string # The statuspage code that will be used to build the status widget (nullable)
  --ErrorPageWhitelabel: string@bool-completer # Determines if the error pages should be whitelabel or not (nullable)
  --OptimizerEnabled: string@bool-completer # Determines if the optimizer should be enabled for this zone (nullable)
  --OptimizerTunnelEnabled: string@bool-completer # Determines if the optimizer origin tunnel system should be enabled for this zone (nullable)
  --OptimizerDesktopMaxWidth: int # Determines the maximum automatic image size for desktop clients (nullable, format: int32)
  --OptimizerMobileMaxWidth: int # Determines the maximum automatic image size for mobile clients (nullable, format: int32)
  --OptimizerImageQuality: int # Determines the image quality for desktop clients (nullable, format: int32)
  --OptimizerMobileImageQuality: int # Determines the image quality for mobile clients (nullable, format: int32)
  --OptimizerEnableWebP: string@bool-completer # Determines if the WebP optimization should be enabled (nullable)
  --OptimizerPrerenderHtml: string@bool-completer # Determines if the SEO HTML prerender should be enabled (nullable)
  --OptimizerEnableManipulationEngine: string@bool-completer # Determines the image manipulation should be enabled (nullable)
  --OptimizerMinifyCSS: string@bool-completer # Determines if the CSS minifcation should be enabled (nullable)
  --OptimizerMinifyJavaScript: string@bool-completer # Determines if the JavaScript minifcation should be enabled (nullable)
  --OptimizerWatermarkEnabled: string@bool-completer # Determines if image watermarking should be enabled (nullable)
  --OptimizerWatermarkUrl: string # Sets the URL of the watermark image (nullable)
  --OptimizerWatermarkPosition: any # Sets the position of the watermark image (nullable)
  --OptimizerWatermarkOffset: float # Sets the offset of the watermark image (nullable, format: double)
  --OptimizerWatermarkMinImageSize: int # Sets the minimum image size to which the watermark will be added (nullable, format: int32)
  --OptimizerAutomaticOptimizationEnabled: string@bool-completer # Determines if the automatic image optimization should be enabled (nullable)
  --OptimizerClasses: list # Determines the list of optimizer classes (nullable) — item shape: {Name?: string, Properties?: record}
  --OptimizerForceClasses: string@bool-completer # Determines if the optimizer classes should be forced (nullable)
  --OptimizerStaticHtmlEnabled: string@bool-completer # Determines whether optimizer static html feature enabled (nullable)
  --OptimizerStaticHtmlWordPressPath: string # Wordpress html path which should be bypassed by permacache in edge rule (nullable)
  --OptimizerStaticHtmlWordPressBypassCookie: string # Wordpress cookie which should be bypassed by permacache in edge rule (nullable)
  --Type: any # The type of the pull zone. Premium = 0, Volume = 1 (nullable)
  --OriginRetries: int # The number of retries to the origin server (nullable, format: int32)
  --OriginConnectTimeout: int # The amount of seconds to wait when connecting to the origin. Otherwise the request will fail or retry. (nullable, format: int32)
  --OriginResponseTimeout: int # The amount of seconds to wait when waiting for the origin reply. Otherwise the request will fail or retry. (nullable, format: int32)
  --UseStaleWhileUpdating: string@bool-completer # Determines if we should use stale cache while cache is updating (nullable)
  --UseStaleWhileOffline: string@bool-completer # Determines if we should use stale cache while the origin is offline (nullable)
  --OriginRetry5XXResponses: string@bool-completer # Determines if we should retry the request in case of a 5XX response. (nullable)
  --OriginRetryConnectionTimeout: string@bool-completer # Determines if we should retry the request in case of a connection timeout. (nullable)
  --OriginRetryResponseTimeout: string@bool-completer # Determines if we should retry the request in case of a response timeout. (nullable)
  --OriginRetryDelay: int # Determines the amount of time that the CDN should wait before retrying an origin request. (nullable, format: int32)
  --DnsOriginPort: int # Determines the origin port of the pull zone. (nullable, format: int32)
  --DnsOriginScheme: string # Determines the origin scheme of the pull zone. (nullable)
  --QueryStringVaryParameters: list # Contains the list of vary parameters that will be used for vary cache by query string. Only alphanumeric characters, dashes and underscores are allowed (values that contain other characters are ignorred). If empty, all parameters will be used to construct the key. (nullable)
  --OriginShieldEnableConcurrencyLimit: string@bool-completer # Determines if the origin shield concurrency limit is enabled. (nullable)
  --OriginShieldMaxConcurrentRequests: int # Determines the number of maximum concurrent requests allowed to the origin. (nullable, format: int32)
  --EnableCookieVary: string@bool-completer # Determines if the Cookie Vary feature is enabled. (nullable)
  --CookieVaryParameters: list # Contains the list of vary parameters that will be used for vary cache by cookie string.Only alphanumeric characters, dashes and underscores are allowed (values that contain other characters are ignorred). If empty, cookie vary will not be used. (nullable)
  --EnableSafeHop: string@bool-completer # nullable
  --OriginShieldQueueMaxWaitTime: int # Determines the max queue wait time (nullable, format: int32)
  --OriginShieldMaxQueuedRequests: int # Determines the max number of origin requests that will remain in the queue (nullable, format: int32)
  --UseBackgroundUpdate: string@bool-completer # Determines if cache update is performed in the background. (nullable)
  --EnableAutoSSL: string@bool-completer # If set to true, any hostnames added to this Pull Zone will automatically enable SSL. (nullable)
  --LogAnonymizationType: any # Sets the log anonymization type for this pull zone (nullable)
  --StorageZoneId: int # The ID of the storage zone that will be used as the origin (nullable, format: int64)
  --EdgeScriptId: int # The ID of the edge script that will be used as the origin (nullable, format: int64)
  --MiddlewareScriptId: int # The ID of the middleware script (nullable, format: int64)
  --EdgeScriptExecutionPhase: any # The execution phase of the edge script (nullable)
  --OriginType: any # Determine the type of the origin for this Pull Zone (nullable)
  --MagicContainersAppId: string # nullable
  --MagicContainersEndpointId: string # nullable
  --LogFormat: any # nullable
  --LogForwardingFormat: any # nullable
  --ShieldDDosProtectionType: any # nullable
  --ShieldDDosProtectionEnabled: string@bool-completer # nullable
  --OriginHostHeader: string # Sets the host header that will be sent to the origin (nullable)
  --EnableSmartCache: string@bool-completer # nullable
  --EnableRequestCoalescing: string@bool-completer # Determines if request coalescing is currently enabled. (nullable)
  --RequestCoalescingTimeout: int # Determines the lock time for coalesced requests. (nullable, format: int32)
  --DisableLetsEncrypt: string@bool-completer # If set to true, the built-in let's encrypt will be disabled and requests are passed to the origin. (nullable)
  --EnableBunnyImageAi: string@bool-completer # nullable
  --BunnyAiImageBlueprints: list # nullable — item shape: {Name?: string, Properties?: record}
  --PreloadingScreenEnabled: string@bool-completer # Determines if the preloading screen is currently enabled (nullable)
  --PreloadingScreenCode: string # The custom preloading screen coed (nullable)
  --PreloadingScreenLogoUrl: string # The preloading screen logo URL (nullable)
  --PreloadingScreenShowOnFirstVisit: string@bool-completer # Determines if the preloading screen is shown on the first load from a user.
  --PreloadingScreenTheme: any # The currently configured preloading screem theme. (0 - Light, 1 - Dark) (nullable)
  --PreloadingScreenCodeEnabled: string@bool-completer # Determines if the custom preloader screen should be enabled (nullable)
  --PreloadingScreenDelay: int # The delay in miliseconds after which the preloading screen will be displayed (0 - 10000ms) (nullable, format: int32)
  --RoutingFilters: list # The list of routing filters enabled for this zone (nullable)
  --StickySessionType: any # Whether to use a Sticky Session mechanism for this pull zone (nullable)
  --StickySessionCookieName: string # Sticky Session Cookie Name (nullable)
  --StickySessionClientHeaders: string # A set of comma-separated header names used to identify clients (nullable)
  --OptimizerEnableUpscaling: string@bool-completer # Determines if Optimizer is allowed to upscale images (nullable)
  --EnableWebSockets: string@bool-completer # Determines if WebSocket connections are allowed for this Pull Zone. (nullable)
  --MaxWebSocketConnections: int # The maximum global simultaneous WebSocket connections allowed for this Pull Zone. Allowed tiers: 500, 1,000, 2,500, 5,000, 10,000, 25,000. If you send a non-tier value, the value is rounded up to the next tier. Values over 25,000 are rejected, please contact sales if required. (nullable, format: int32)
  --CacheKeyHeaders: string # Vary Cache by Request Headers (comma delimited) (nullable)
]: any -> record<Id: int, Name: string, OriginUrl: string, Enabled: bool, Suspended: bool, Hostnames: table<Id: int, Value: string, ForceSSL: bool, IsSystemHostname: bool, IsManagedHostname: bool, HasCertificate: bool, Certificate: string, CertificateKey: string, CertificateKeyType: any, CertificateProvisionType: any>, StorageZoneId: int, EdgeScriptId: int, EdgeScriptExecutionPhase: any, MiddlewareScriptId: int, MagicContainersAppId: string, MagicContainersEndpointId: string, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockedIps: list<string>, EnableGeoZoneUS: bool, EnableGeoZoneEU: bool, EnableGeoZoneASIA: bool, EnableGeoZoneSA: bool, EnableGeoZoneAF: bool, ZoneSecurityEnabled: bool, ZoneSecurityKey: string, ZoneSecurityIncludeHashRemoteIP: bool, IgnoreQueryStrings: bool, MonthlyBandwidthLimit: int, MonthlyBandwidthUsed: int, MonthlyCharges: float, AddHostHeader: bool, OriginHostHeader: string, Type: any, AccessControlOriginHeaderExtensions: list<string>, EnableAccessControlOriginHeader: bool, DisableCookies: bool, BudgetRedirectedCountries: list<string>, BlockedCountries: list<string>, EnableOriginShield: bool, CacheControlMaxAgeOverride: int, CacheControlPublicMaxAgeOverride: int, BurstSize: int, RequestLimit: int, BlockRootPathAccess: bool, BlockPostRequests: bool, LimitRatePerSecond: float, LimitRateAfter: float, ConnectionLimitPerIPCount: int, PriceOverride: float, OptimizerPricing: float, AddCanonicalHeader: bool, EnableLogging: bool, EnableCacheSlice: bool, EnableSmartCache: bool, EdgeRules: table<Guid: string, ActionType: any, ActionParameter1: string, ActionParameter2: string, ActionParameter3: string, Triggers: list, ExtraActions: list, TriggerMatchingType: any, Description: string, Enabled: bool, OrderIndex: int, ReadOnly: bool>, EnableWebPVary: bool, EnableAvifVary: bool, EnableCountryCodeVary: bool, EnableCountryStateCodeVary: bool, EnableMobileVary: bool, EnableCookieVary: bool, CookieVaryParameters: list<string>, EnableHostnameVary: bool, CnameDomain: string, AWSSigningEnabled: bool, AWSSigningKey: string, AWSSigningSecret: string, AWSSigningRegionName: string, LoggingIPAnonymizationEnabled: bool, EnableTLS1: bool, EnableTLS1_1: bool, VerifyOriginSSL: bool, ErrorPageEnableCustomCode: bool, ErrorPageCustomCode: string, ErrorPageEnableStatuspageWidget: bool, ErrorPageStatuspageCode: string, ErrorPageWhitelabel: bool, OriginShieldZoneCode: string, LogForwardingEnabled: bool, LogForwardingHostname: string, LogForwardingPort: int, LogForwardingToken: string, LogForwardingProtocol: any, LoggingSaveToStorage: bool, LoggingStorageZoneId: int, FollowRedirects: bool, VideoLibraryId: int, DnsRecordId: int, DnsZoneId: int, DnsRecordValue: string, OptimizerEnabled: bool, OptimizerTunnelEnabled: bool, OptimizerDesktopMaxWidth: int, OptimizerMobileMaxWidth: int, OptimizerImageQuality: int, OptimizerMobileImageQuality: int, OptimizerEnableWebP: bool, OptimizerPrerenderHtml: bool, OptimizerEnableManipulationEngine: bool, OptimizerMinifyCSS: bool, OptimizerMinifyJavaScript: bool, OptimizerWatermarkEnabled: bool, OptimizerWatermarkUrl: string, OptimizerWatermarkPosition: any, OptimizerWatermarkOffset: float, OptimizerWatermarkMinImageSize: int, OptimizerAutomaticOptimizationEnabled: bool, PermaCacheStorageZoneId: int, PermaCacheType: any, OriginRetries: int, OriginConnectTimeout: int, OriginResponseTimeout: int, UseStaleWhileUpdating: bool, UseStaleWhileOffline: bool, OriginRetry5XXResponses: bool, OriginRetryConnectionTimeout: bool, OriginRetryResponseTimeout: bool, OriginRetryDelay: int, QueryStringVaryParameters: list<string>, OriginShieldEnableConcurrencyLimit: bool, OriginShieldMaxConcurrentRequests: int, EnableSafeHop: bool, CacheErrorResponses: bool, OriginShieldQueueMaxWaitTime: int, OriginShieldMaxQueuedRequests: int, OptimizerClasses: table<Name: string, Properties: record>, OptimizerForceClasses: bool, OptimizerStaticHtmlEnabled: bool, OptimizerStaticHtmlWordPressPath: string, OptimizerStaticHtmlWordPressBypassCookie: string, UseBackgroundUpdate: bool, EnableAutoSSL: bool, EnableQueryStringOrdering: bool, LogAnonymizationType: any, LogFormat: int, LogForwardingFormat: int, ShieldDDosProtectionType: int, ShieldDDosProtectionEnabled: bool, OriginType: any, EnableRequestCoalescing: bool, RequestCoalescingTimeout: int, OriginLinkValue: string, DisableLetsEncrypt: bool, EnableBunnyImageAi: bool, BunnyAiImageBlueprints: table<Name: string, Properties: record>, PreloadingScreenEnabled: bool, PreloadingScreenShowOnFirstVisit: bool, PreloadingScreenCode: string, PreloadingScreenLogoUrl: string, PreloadingScreenCodeEnabled: bool, PreloadingScreenTheme: any, PreloadingScreenDelay: int, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, RoutingFilters: list<string>, BlockNoneReferrer: bool, StickySessionType: any, StickySessionCookieName: string, StickySessionClientHeaders: string, UserId: string, CacheVersion: int, OptimizerEnableUpscaling: bool, EnableWebSockets: bool, MaxWebSocketConnections: int, EnableExtendedLogging: bool, CacheKeyHeaders: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)")
  let body = {OriginUrl: $OriginUrl, AllowedReferrers: $AllowedReferrers, BlockedReferrers: $BlockedReferrers, BlockNoneReferrer: $BlockNoneReferrer, BlockedIps: $BlockedIps, EnableGeoZoneUS: $EnableGeoZoneUS, EnableGeoZoneEU: $EnableGeoZoneEU, EnableGeoZoneASIA: $EnableGeoZoneASIA, EnableGeoZoneSA: $EnableGeoZoneSA, EnableGeoZoneAF: $EnableGeoZoneAF, BlockRootPathAccess: $BlockRootPathAccess, BlockPostRequests: $BlockPostRequests, EnableQueryStringOrdering: $EnableQueryStringOrdering, EnableWebpVary: $EnableWebpVary, EnableAvifVary: $EnableAvifVary, EnableMobileVary: $EnableMobileVary, EnableCountryCodeVary: $EnableCountryCodeVary, EnableCountryStateCodeVary: $EnableCountryStateCodeVary, EnableHostnameVary: $EnableHostnameVary, EnableCacheSlice: $EnableCacheSlice, ZoneSecurityEnabled: $ZoneSecurityEnabled, ZoneSecurityIncludeHashRemoteIP: $ZoneSecurityIncludeHashRemoteIP, IgnoreQueryStrings: $IgnoreQueryStrings, MonthlyBandwidthLimit: $MonthlyBandwidthLimit, AccessControlOriginHeaderExtensions: $AccessControlOriginHeaderExtensions, EnableAccessControlOriginHeader: $EnableAccessControlOriginHeader, DisableCookies: $DisableCookies, BudgetRedirectedCountries: $BudgetRedirectedCountries, BlockedCountries: $BlockedCountries, CacheControlMaxAgeOverride: $CacheControlMaxAgeOverride, CacheControlPublicMaxAgeOverride: $CacheControlPublicMaxAgeOverride, CacheControlBrowserMaxAgeOverride: $CacheControlBrowserMaxAgeOverride, AddHostHeader: $AddHostHeader, AddCanonicalHeader: $AddCanonicalHeader, EnableLogging: $EnableLogging, LoggingIPAnonymizationEnabled: $LoggingIPAnonymizationEnabled, PermaCacheStorageZoneId: $PermaCacheStorageZoneId, PermaCacheType: $PermaCacheType, AWSSigningEnabled: $AWSSigningEnabled, AWSSigningKey: $AWSSigningKey, AWSSigningRegionName: $AWSSigningRegionName, AWSSigningSecret: $AWSSigningSecret, EnableOriginShield: $EnableOriginShield, OriginShieldZoneCode: $OriginShieldZoneCode, EnableTLS1: $EnableTLS1, EnableTLS1_1: $EnableTLS1_1, CacheErrorResponses: $CacheErrorResponses, VerifyOriginSSL: $VerifyOriginSSL, LogForwardingEnabled: $LogForwardingEnabled, LogForwardingHostname: $LogForwardingHostname, LogForwardingPort: $LogForwardingPort, LogForwardingToken: $LogForwardingToken, LogForwardingProtocol: $LogForwardingProtocol, LoggingSaveToStorage: $LoggingSaveToStorage, LoggingStorageZoneId: $LoggingStorageZoneId, FollowRedirects: $FollowRedirects, ConnectionLimitPerIPCount: $ConnectionLimitPerIPCount, RequestLimit: $RequestLimit, LimitRateAfter: $LimitRateAfter, LimitRatePerSecond: $LimitRatePerSecond, BurstSize: $BurstSize, ErrorPageEnableCustomCode: $ErrorPageEnableCustomCode, ErrorPageCustomCode: $ErrorPageCustomCode, ErrorPageEnableStatuspageWidget: $ErrorPageEnableStatuspageWidget, ErrorPageStatuspageCode: $ErrorPageStatuspageCode, ErrorPageWhitelabel: $ErrorPageWhitelabel, OptimizerEnabled: $OptimizerEnabled, OptimizerTunnelEnabled: $OptimizerTunnelEnabled, OptimizerDesktopMaxWidth: $OptimizerDesktopMaxWidth, OptimizerMobileMaxWidth: $OptimizerMobileMaxWidth, OptimizerImageQuality: $OptimizerImageQuality, OptimizerMobileImageQuality: $OptimizerMobileImageQuality, OptimizerEnableWebP: $OptimizerEnableWebP, OptimizerPrerenderHtml: $OptimizerPrerenderHtml, OptimizerEnableManipulationEngine: $OptimizerEnableManipulationEngine, OptimizerMinifyCSS: $OptimizerMinifyCSS, OptimizerMinifyJavaScript: $OptimizerMinifyJavaScript, OptimizerWatermarkEnabled: $OptimizerWatermarkEnabled, OptimizerWatermarkUrl: $OptimizerWatermarkUrl, OptimizerWatermarkPosition: $OptimizerWatermarkPosition, OptimizerWatermarkOffset: $OptimizerWatermarkOffset, OptimizerWatermarkMinImageSize: $OptimizerWatermarkMinImageSize, OptimizerAutomaticOptimizationEnabled: $OptimizerAutomaticOptimizationEnabled, OptimizerClasses: $OptimizerClasses, OptimizerForceClasses: $OptimizerForceClasses, OptimizerStaticHtmlEnabled: $OptimizerStaticHtmlEnabled, OptimizerStaticHtmlWordPressPath: $OptimizerStaticHtmlWordPressPath, OptimizerStaticHtmlWordPressBypassCookie: $OptimizerStaticHtmlWordPressBypassCookie, Type: $Type, OriginRetries: $OriginRetries, OriginConnectTimeout: $OriginConnectTimeout, OriginResponseTimeout: $OriginResponseTimeout, UseStaleWhileUpdating: $UseStaleWhileUpdating, UseStaleWhileOffline: $UseStaleWhileOffline, OriginRetry5XXResponses: $OriginRetry5XXResponses, OriginRetryConnectionTimeout: $OriginRetryConnectionTimeout, OriginRetryResponseTimeout: $OriginRetryResponseTimeout, OriginRetryDelay: $OriginRetryDelay, DnsOriginPort: $DnsOriginPort, DnsOriginScheme: $DnsOriginScheme, QueryStringVaryParameters: $QueryStringVaryParameters, OriginShieldEnableConcurrencyLimit: $OriginShieldEnableConcurrencyLimit, OriginShieldMaxConcurrentRequests: $OriginShieldMaxConcurrentRequests, EnableCookieVary: $EnableCookieVary, CookieVaryParameters: $CookieVaryParameters, EnableSafeHop: $EnableSafeHop, OriginShieldQueueMaxWaitTime: $OriginShieldQueueMaxWaitTime, OriginShieldMaxQueuedRequests: $OriginShieldMaxQueuedRequests, UseBackgroundUpdate: $UseBackgroundUpdate, EnableAutoSSL: $EnableAutoSSL, LogAnonymizationType: $LogAnonymizationType, StorageZoneId: $StorageZoneId, EdgeScriptId: $EdgeScriptId, MiddlewareScriptId: $MiddlewareScriptId, EdgeScriptExecutionPhase: $EdgeScriptExecutionPhase, OriginType: $OriginType, MagicContainersAppId: $MagicContainersAppId, MagicContainersEndpointId: $MagicContainersEndpointId, LogFormat: $LogFormat, LogForwardingFormat: $LogForwardingFormat, ShieldDDosProtectionType: $ShieldDDosProtectionType, ShieldDDosProtectionEnabled: $ShieldDDosProtectionEnabled, OriginHostHeader: $OriginHostHeader, EnableSmartCache: $EnableSmartCache, EnableRequestCoalescing: $EnableRequestCoalescing, RequestCoalescingTimeout: $RequestCoalescingTimeout, DisableLetsEncrypt: $DisableLetsEncrypt, EnableBunnyImageAi: $EnableBunnyImageAi, BunnyAiImageBlueprints: $BunnyAiImageBlueprints, PreloadingScreenEnabled: $PreloadingScreenEnabled, PreloadingScreenCode: $PreloadingScreenCode, PreloadingScreenLogoUrl: $PreloadingScreenLogoUrl, PreloadingScreenShowOnFirstVisit: $PreloadingScreenShowOnFirstVisit, PreloadingScreenTheme: $PreloadingScreenTheme, PreloadingScreenCodeEnabled: $PreloadingScreenCodeEnabled, PreloadingScreenDelay: $PreloadingScreenDelay, RoutingFilters: $RoutingFilters, StickySessionType: $StickySessionType, StickySessionCookieName: $StickySessionCookieName, StickySessionClientHeaders: $StickySessionClientHeaders, OptimizerEnableUpscaling: $OptimizerEnableUpscaling, EnableWebSockets: $EnableWebSockets, MaxWebSocketConnections: $MaxWebSocketConnections, CacheKeyHeaders: $CacheKeyHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pull Zone
#
# DELETE /pullzone/{id}
# operationId: PullZonePublic_Delete
export def "pullzone Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Edge Rule
#
# DELETE /pullzone/{pullZoneId}/edgerules/{edgeRuleId}
# operationId: PullZonePublic_DeleteEdgeRule
export def "pullzone-edgerules DeleteEdgeRule" [
  pullZoneId: int
  edgeRuleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/edgerules/($edgeRuleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add/Update Edge Rule
#
# POST /pullzone/{pullZoneId}/edgerules/addOrUpdate
# operationId: PullZonePublic_AddEdgeRule
# --Triggers item shape: {Type?: any, PatternMatches?: list, PatternMatchingType?: any, Parameter1?: string}
# --ExtraActions item shape: {ActionType?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20"|"21"|"22"|"23"|"24"|"25"|"26"|"27"|"28"|"29"|"30"|"31"|"32"|"33"|"34", ActionParameter1?: string, ActionParameter2?: string, ActionParameter3?: string}
export def "pullzone-edgerules-add-or-update AddEdgeRule" [
  pullZoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Guid: string # The unique GUID of the edge rule (nullable)
  --ActionType: any # The action type of the edge rule. ForceSSL = 0, Redirect = 1, OriginUrl = 2, OverrideCacheTime = 3, BlockRequest = 4, SetResponseHeader = 5, SetRequestHeader = 6, ForceDownload = 7, DisableTokenAuthentication = 8, EnableTokenAuthentication = 9, OverrideCacheTimePublic = 10, IgnoreQueryString = 11, DisableOptimizer = 12, ForceCompression = 13, SetStatusCode = 14, BypassPermaCache = 15, OverrideBrowserCacheTime = 16
  --ActionParameter1: string # The Action parameter 1. The value depends on other parameters of the edge rule. (nullable)
  --ActionParameter2: string # The Action parameter 2. The value depends on other parameters of the edge rule. (nullable)
  --ActionParameter3: string # The Action parameter 3. The value depends on other parameters of the edge rule. (nullable)
  --Triggers: list # nullable — item shape: {Type?: any, PatternMatches?: list, PatternMatchingType?: any, Parameter1?: string}
  --ExtraActions: list # nullable — item shape: {ActionType?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20"|"21"|"22"|"23"|"24"|"25"|"26"|"27"|"28"|"29"|"30"|"31"|"32"|"33"|"34", ActionParameter1?: string, ActionParameter2?: string, ActionParameter3?: string}
  --TriggerMatchingType: any # The trigger matching type. MatchAny = 0, MatchAll = 1, MatchNone = 2
  --Description: string # The description of the edge rule (nullable)
  --Enabled: string@bool-completer # Determines if the edge rule is currently enabled or not
  --OrderIndex: int # The index of the edge rule in the list of execution priority (format: int32)
  --ReadOnly: string@bool-completer # Determines if the edge rule is read-only and cannot be modified or deleted
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/edgerules/addOrUpdate")
  let body = {Guid: $Guid, ActionType: $ActionType, ActionParameter1: $ActionParameter1, ActionParameter2: $ActionParameter2, ActionParameter3: $ActionParameter3, Triggers: $Triggers, ExtraActions: $ExtraActions, TriggerMatchingType: $TriggerMatchingType, Description: $Description, Enabled: $Enabled, OrderIndex: $OrderIndex, ReadOnly: $ReadOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Edge Rule Enabled
#
# POST /pullzone/{pullZoneId}/edgerules/{edgeRuleId}/setEdgeRuleEnabled
# operationId: PullZonePublic_SetEdgeRuleEnabled
export def "pullzone-edgerules-set-edge-rule-enabled SetEdgeRuleEnabled" [
  pullZoneId: int
  edgeRuleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Id: int # format: int64
  --Value: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/edgerules/($edgeRuleId)/setEdgeRuleEnabled")
  let body = {Id: $Id, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change hostname private key type
#
# POST /pullzone/{id}/updatePrivateKeyType
# operationId: PullZonePublic_UpdatePrivateKeyType
export def "pullzone-update-private-key-type UpdatePrivateKeyType" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string
  KeyType: int@KeyType-completer # 0 = Ecdsa 1 = Rsa
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/updatePrivateKeyType")
  let body = {Hostname: $Hostname, KeyType: $KeyType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Free Certificate
#
# GET /pullzone/loadFreeCertificate
# operationId: PullZonePublic_LoadFreeCertificate
export def "pullzone-load-free-certificate LoadFreeCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hostname: string # The hostname that the certificate will be loaded for (nullable)
  --useOnlyHttp01: string@bool-completer # If false and a Bunny DNS Zone exists for the domain, DNS01 validation we be attempted. This has no effect on wildcard domains, as this can only use DNS01 (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostname" $hostname "scalar") (serialize-qp "useOnlyHttp01" $useOnlyHttp01 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pullzone/loadFreeCertificate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request External DNS Certificate
#
# POST /pullzone/requestExternalDnsCertificate
# operationId: PullZonePublic_RequestExternalDnsCertificate
export def "pullzone-request-external-dns-certificate RequestExternalDnsCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pullzone/requestExternalDnsCertificate")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete External DNS Certificate
#
# POST /pullzone/completeExternalDnsCertificate
# operationId: PullZonePublic_CompleteExternalDnsCertificate
export def "pullzone-complete-external-dns-certificate CompleteExternalDnsCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pullzone/completeExternalDnsCertificate")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge Cache
#
# POST /pullzone/{id}/purgeCache
# operationId: PullZonePublic_PurgeCachePostByTag
export def "pullzone-purge-cache PurgeCachePostByTag" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CacheTag: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/purgeCache")
  let body = {CacheTag: $CacheTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check the pull zone availability
#
# POST /pullzone/checkavailability
# operationId: PullZonePublic_CheckAvailability
export def "pullzone-checkavailability CheckAvailability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # Determines the name of the zone that we are checking (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pullzone/checkavailability")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Custom Certificate
#
# POST /pullzone/{id}/addCertificate
# operationId: PullZonePublic_AddCertificate
export def "pullzone-add-certificate AddCertificate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname to which the hostname will be added
  Certificate: string # The Base64 encoded binary data of the certificate file
  CertificateKey: string # The Base64 encoded binary data of the certificate key file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/addCertificate")
  let body = {Hostname: $Hostname, Certificate: $Certificate, CertificateKey: $CertificateKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Certificate
#
# DELETE /pullzone/{id}/removeCertificate
# operationId: PullZonePublic_RemoveCertificate
export def "pullzone-remove-certificate RemoveCertificate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname from which the certificate will be removed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/removeCertificate")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Custom Hostname
#
# POST /pullzone/{id}/addHostname
# operationId: PullZonePublic_AddHostname
export def "pullzone-add-hostname AddHostname" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be added
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/addHostname")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Custom Hostname
#
# DELETE /pullzone/{id}/removeHostname
# operationId: PullZonePublic_RemoveHostname
export def "pullzone-remove-hostname RemoveHostname" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be removed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/removeHostname")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Force SSL
#
# POST /pullzone/{id}/setForceSSL
# operationId: PullZonePublic_SetForceSSL
export def "pullzone-set-force-ssl SetForceSSL" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be updated
  --ForceSSL: string@bool-completer # Set to true to force SSL on the given pull zone hostname
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/setForceSSL")
  let body = {Hostname: $Hostname, ForceSSL: $ForceSSL} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset Token Key
#
# POST /pullzone/{id}/resetSecurityKey
# operationId: ResetSecurityKeyEndpoint_ResetSecurityKey
export def "pullzone-reset-security-key ResetSecurityKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SecurityKey: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/resetSecurityKey")
  let body = {SecurityKey: $SecurityKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Allowed Referer
#
# POST /pullzone/{id}/addAllowedReferrer
# operationId: PullZonePublic_AddAllowedReferrer
export def "pullzone-add-allowed-referrer AddAllowedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be added as an allowed referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/addAllowedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Allowed Referer
#
# POST /pullzone/{id}/removeAllowedReferrer
# operationId: PullZonePublic_RemoveAllowedReferrer
export def "pullzone-remove-allowed-referrer RemoveAllowedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be removed as an allowed referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/removeAllowedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Blocked Referer
#
# POST /pullzone/{id}/addBlockedReferrer
# operationId: PullZonePublic_AddBlockedReferrer
export def "pullzone-add-blocked-referrer AddBlockedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be added as a blocked referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/addBlockedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Blocked Referer
#
# POST /pullzone/{id}/removeBlockedReferrer
# operationId: PullZonePublic_RemoveBlockedReferrer
export def "pullzone-remove-blocked-referrer RemoveBlockedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be removed as an allowed referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/removeBlockedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Blocked IP
#
# POST /pullzone/{id}/addBlockedIp
# operationId: PullZonePublic_AddBlockedIp
export def "pullzone-add-blocked-ip AddBlockedIp" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  BlockedIp: string # The IP that will be blocked from accessing the pull zone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/addBlockedIp")
  let body = {BlockedIp: $BlockedIp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Blocked IP
#
# POST /pullzone/{id}/removeBlockedIp
# operationId: PullZonePublic_RemoveBlockedIp
export def "pullzone-remove-blocked-ip RemoveBlockedIp" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  BlockedIp: string # The IP that will be removed fromt he block list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pullzone/($id)/removeBlockedIp")
  let body = {BlockedIp: $BlockedIp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge URL
#
# POST /purge
# operationId: PurgePublic_IndexPost
export def "purge IndexPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The URL that will be purged from cache. (nullable)
  --async: string@bool-completer # (Optional) Determines if the call should wait for the purge logic to complete (default: false)
  --exactPath: string@bool-completer # (Optional) When true and the URL ends with '/', purges only the exact path without adding a wildcard suffix. Only applies when the pull zone has IgnoreQueryStrings disabled. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "async" $async "scalar") (serialize-qp "exactPath" $exactPath "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/purge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Region list
#
# GET /region
# operationId: RegionPublic_Index
export def "region Index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Id: int, Name: string, PricePerGigabyte: float, RegionCode: string, ContinentCode: string, CountryCode: string, Latitude: float, Longitude: float, AllowLatencyRouting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/region")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Storage Zones
#
# GET /storagezone
# operationId: StorageZonePublic_IndexAll
export def "storagezone IndexAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. When set to 0 (default), all items are returned as a plain array. When set to a value greater than 0, items are returned in a paginated response object. (format: int32, default: 0)
  --perPage: int # format: int32, default: 1000
  --includeDeleted: string@bool-completer # default: false
  --search: string # The search term that will be used to filter the results (nullable)
]: nothing -> table<Id: int, UserId: string, Name: string, Password: string, DateModified: string, Deleted: bool, StorageUsed: int, FilesStored: int, Region: string, ReplicationRegions: list<string>, PullZones: list<record>, ReadOnlyPassword: string, Rewrite404To200: bool, Custom404FilePath: string, StorageHostname: string, ZoneTier: any, ReplicationChangeInProgress: bool, PriceOverride: float, Discount: int, StorageZoneType: any> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storagezone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Storage Zone
#
# POST /storagezone
# operationId: StorageZonePublic_Add
export def "storagezone Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # The name of the storage zone
  Region: string # The code of the main storage zone region (Possible values: DE, NY, LA, SG)
  --ReplicationRegions: list # The code of the main storage zone region (Possible values: DE, NY, LA, SG, SYD) (nullable)
  --ZoneTier: any # Determines the storage zone tier that will be storing the data
  --StorageZoneType: any # The Storage Zone S3 support type
]: any -> record<Id: int, UserId: string, Name: string, Password: string, DateModified: string, Deleted: bool, StorageUsed: int, FilesStored: int, Region: string, ReplicationRegions: list<string>, PullZones: table<Id: int, Name: string, OriginUrl: string, Enabled: bool, Suspended: bool, Hostnames: list, StorageZoneId: int, EdgeScriptId: int, EdgeScriptExecutionPhase: any, MiddlewareScriptId: int, MagicContainersAppId: string, MagicContainersEndpointId: string, AllowedReferrers: list, BlockedReferrers: list, BlockedIps: list, EnableGeoZoneUS: bool, EnableGeoZoneEU: bool, EnableGeoZoneASIA: bool, EnableGeoZoneSA: bool, EnableGeoZoneAF: bool, ZoneSecurityEnabled: bool, ZoneSecurityKey: string, ZoneSecurityIncludeHashRemoteIP: bool, IgnoreQueryStrings: bool, MonthlyBandwidthLimit: int, MonthlyBandwidthUsed: int, MonthlyCharges: float, AddHostHeader: bool, OriginHostHeader: string, Type: any, AccessControlOriginHeaderExtensions: list, EnableAccessControlOriginHeader: bool, DisableCookies: bool, BudgetRedirectedCountries: list, BlockedCountries: list, EnableOriginShield: bool, CacheControlMaxAgeOverride: int, CacheControlPublicMaxAgeOverride: int, BurstSize: int, RequestLimit: int, BlockRootPathAccess: bool, BlockPostRequests: bool, LimitRatePerSecond: float, LimitRateAfter: float, ConnectionLimitPerIPCount: int, PriceOverride: float, OptimizerPricing: float, AddCanonicalHeader: bool, EnableLogging: bool, EnableCacheSlice: bool, EnableSmartCache: bool, EdgeRules: list, EnableWebPVary: bool, EnableAvifVary: bool, EnableCountryCodeVary: bool, EnableCountryStateCodeVary: bool, EnableMobileVary: bool, EnableCookieVary: bool, CookieVaryParameters: list, EnableHostnameVary: bool, CnameDomain: string, AWSSigningEnabled: bool, AWSSigningKey: string, AWSSigningSecret: string, AWSSigningRegionName: string, LoggingIPAnonymizationEnabled: bool, EnableTLS1: bool, EnableTLS1_1: bool, VerifyOriginSSL: bool, ErrorPageEnableCustomCode: bool, ErrorPageCustomCode: string, ErrorPageEnableStatuspageWidget: bool, ErrorPageStatuspageCode: string, ErrorPageWhitelabel: bool, OriginShieldZoneCode: string, LogForwardingEnabled: bool, LogForwardingHostname: string, LogForwardingPort: int, LogForwardingToken: string, LogForwardingProtocol: any, LoggingSaveToStorage: bool, LoggingStorageZoneId: int, FollowRedirects: bool, VideoLibraryId: int, DnsRecordId: int, DnsZoneId: int, DnsRecordValue: string, OptimizerEnabled: bool, OptimizerTunnelEnabled: bool, OptimizerDesktopMaxWidth: int, OptimizerMobileMaxWidth: int, OptimizerImageQuality: int, OptimizerMobileImageQuality: int, OptimizerEnableWebP: bool, OptimizerPrerenderHtml: bool, OptimizerEnableManipulationEngine: bool, OptimizerMinifyCSS: bool, OptimizerMinifyJavaScript: bool, OptimizerWatermarkEnabled: bool, OptimizerWatermarkUrl: string, OptimizerWatermarkPosition: any, OptimizerWatermarkOffset: float, OptimizerWatermarkMinImageSize: int, OptimizerAutomaticOptimizationEnabled: bool, PermaCacheStorageZoneId: int, PermaCacheType: any, OriginRetries: int, OriginConnectTimeout: int, OriginResponseTimeout: int, UseStaleWhileUpdating: bool, UseStaleWhileOffline: bool, OriginRetry5XXResponses: bool, OriginRetryConnectionTimeout: bool, OriginRetryResponseTimeout: bool, OriginRetryDelay: int, QueryStringVaryParameters: list, OriginShieldEnableConcurrencyLimit: bool, OriginShieldMaxConcurrentRequests: int, EnableSafeHop: bool, CacheErrorResponses: bool, OriginShieldQueueMaxWaitTime: int, OriginShieldMaxQueuedRequests: int, OptimizerClasses: list, OptimizerForceClasses: bool, OptimizerStaticHtmlEnabled: bool, OptimizerStaticHtmlWordPressPath: string, OptimizerStaticHtmlWordPressBypassCookie: string, UseBackgroundUpdate: bool, EnableAutoSSL: bool, EnableQueryStringOrdering: bool, LogAnonymizationType: any, LogFormat: int, LogForwardingFormat: int, ShieldDDosProtectionType: int, ShieldDDosProtectionEnabled: bool, OriginType: any, EnableRequestCoalescing: bool, RequestCoalescingTimeout: int, OriginLinkValue: string, DisableLetsEncrypt: bool, EnableBunnyImageAi: bool, BunnyAiImageBlueprints: list, PreloadingScreenEnabled: bool, PreloadingScreenShowOnFirstVisit: bool, PreloadingScreenCode: string, PreloadingScreenLogoUrl: string, PreloadingScreenCodeEnabled: bool, PreloadingScreenTheme: any, PreloadingScreenDelay: int, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, RoutingFilters: list, BlockNoneReferrer: bool, StickySessionType: any, StickySessionCookieName: string, StickySessionClientHeaders: string, UserId: string, CacheVersion: int, OptimizerEnableUpscaling: bool, EnableWebSockets: bool, MaxWebSocketConnections: int, EnableExtendedLogging: bool, CacheKeyHeaders: string>, ReadOnlyPassword: string, Rewrite404To200: bool, Custom404FilePath: string, StorageHostname: string, ZoneTier: any, ReplicationChangeInProgress: bool, PriceOverride: float, Discount: int, StorageZoneType: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storagezone")
  let body = {Name: $Name, Region: $Region, ReplicationRegions: $ReplicationRegions, ZoneTier: $ZoneTier, StorageZoneType: $StorageZoneType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check the storage zone availability
#
# POST /storagezone/checkavailability
# operationId: StorageZonePublic_CheckAvailability
export def "storagezone-checkavailability CheckAvailability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # Determines the name of the zone that we are checking (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storagezone/checkavailability")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Storage Zone
#
# GET /storagezone/{id}
# operationId: StorageZonePublic_Index
export def "storagezone Index" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, UserId: string, Name: string, Password: string, DateModified: string, Deleted: bool, StorageUsed: int, FilesStored: int, Region: string, ReplicationRegions: list<string>, PullZones: table<Id: int, Name: string, OriginUrl: string, Enabled: bool, Suspended: bool, Hostnames: list, StorageZoneId: int, EdgeScriptId: int, EdgeScriptExecutionPhase: any, MiddlewareScriptId: int, MagicContainersAppId: string, MagicContainersEndpointId: string, AllowedReferrers: list, BlockedReferrers: list, BlockedIps: list, EnableGeoZoneUS: bool, EnableGeoZoneEU: bool, EnableGeoZoneASIA: bool, EnableGeoZoneSA: bool, EnableGeoZoneAF: bool, ZoneSecurityEnabled: bool, ZoneSecurityKey: string, ZoneSecurityIncludeHashRemoteIP: bool, IgnoreQueryStrings: bool, MonthlyBandwidthLimit: int, MonthlyBandwidthUsed: int, MonthlyCharges: float, AddHostHeader: bool, OriginHostHeader: string, Type: any, AccessControlOriginHeaderExtensions: list, EnableAccessControlOriginHeader: bool, DisableCookies: bool, BudgetRedirectedCountries: list, BlockedCountries: list, EnableOriginShield: bool, CacheControlMaxAgeOverride: int, CacheControlPublicMaxAgeOverride: int, BurstSize: int, RequestLimit: int, BlockRootPathAccess: bool, BlockPostRequests: bool, LimitRatePerSecond: float, LimitRateAfter: float, ConnectionLimitPerIPCount: int, PriceOverride: float, OptimizerPricing: float, AddCanonicalHeader: bool, EnableLogging: bool, EnableCacheSlice: bool, EnableSmartCache: bool, EdgeRules: list, EnableWebPVary: bool, EnableAvifVary: bool, EnableCountryCodeVary: bool, EnableCountryStateCodeVary: bool, EnableMobileVary: bool, EnableCookieVary: bool, CookieVaryParameters: list, EnableHostnameVary: bool, CnameDomain: string, AWSSigningEnabled: bool, AWSSigningKey: string, AWSSigningSecret: string, AWSSigningRegionName: string, LoggingIPAnonymizationEnabled: bool, EnableTLS1: bool, EnableTLS1_1: bool, VerifyOriginSSL: bool, ErrorPageEnableCustomCode: bool, ErrorPageCustomCode: string, ErrorPageEnableStatuspageWidget: bool, ErrorPageStatuspageCode: string, ErrorPageWhitelabel: bool, OriginShieldZoneCode: string, LogForwardingEnabled: bool, LogForwardingHostname: string, LogForwardingPort: int, LogForwardingToken: string, LogForwardingProtocol: any, LoggingSaveToStorage: bool, LoggingStorageZoneId: int, FollowRedirects: bool, VideoLibraryId: int, DnsRecordId: int, DnsZoneId: int, DnsRecordValue: string, OptimizerEnabled: bool, OptimizerTunnelEnabled: bool, OptimizerDesktopMaxWidth: int, OptimizerMobileMaxWidth: int, OptimizerImageQuality: int, OptimizerMobileImageQuality: int, OptimizerEnableWebP: bool, OptimizerPrerenderHtml: bool, OptimizerEnableManipulationEngine: bool, OptimizerMinifyCSS: bool, OptimizerMinifyJavaScript: bool, OptimizerWatermarkEnabled: bool, OptimizerWatermarkUrl: string, OptimizerWatermarkPosition: any, OptimizerWatermarkOffset: float, OptimizerWatermarkMinImageSize: int, OptimizerAutomaticOptimizationEnabled: bool, PermaCacheStorageZoneId: int, PermaCacheType: any, OriginRetries: int, OriginConnectTimeout: int, OriginResponseTimeout: int, UseStaleWhileUpdating: bool, UseStaleWhileOffline: bool, OriginRetry5XXResponses: bool, OriginRetryConnectionTimeout: bool, OriginRetryResponseTimeout: bool, OriginRetryDelay: int, QueryStringVaryParameters: list, OriginShieldEnableConcurrencyLimit: bool, OriginShieldMaxConcurrentRequests: int, EnableSafeHop: bool, CacheErrorResponses: bool, OriginShieldQueueMaxWaitTime: int, OriginShieldMaxQueuedRequests: int, OptimizerClasses: list, OptimizerForceClasses: bool, OptimizerStaticHtmlEnabled: bool, OptimizerStaticHtmlWordPressPath: string, OptimizerStaticHtmlWordPressBypassCookie: string, UseBackgroundUpdate: bool, EnableAutoSSL: bool, EnableQueryStringOrdering: bool, LogAnonymizationType: any, LogFormat: int, LogForwardingFormat: int, ShieldDDosProtectionType: int, ShieldDDosProtectionEnabled: bool, OriginType: any, EnableRequestCoalescing: bool, RequestCoalescingTimeout: int, OriginLinkValue: string, DisableLetsEncrypt: bool, EnableBunnyImageAi: bool, BunnyAiImageBlueprints: list, PreloadingScreenEnabled: bool, PreloadingScreenShowOnFirstVisit: bool, PreloadingScreenCode: string, PreloadingScreenLogoUrl: string, PreloadingScreenCodeEnabled: bool, PreloadingScreenTheme: any, PreloadingScreenDelay: int, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, RoutingFilters: list, BlockNoneReferrer: bool, StickySessionType: any, StickySessionCookieName: string, StickySessionClientHeaders: string, UserId: string, CacheVersion: int, OptimizerEnableUpscaling: bool, EnableWebSockets: bool, MaxWebSocketConnections: int, EnableExtendedLogging: bool, CacheKeyHeaders: string>, ReadOnlyPassword: string, Rewrite404To200: bool, Custom404FilePath: string, StorageHostname: string, ZoneTier: any, ReplicationChangeInProgress: bool, PriceOverride: float, Discount: int, StorageZoneType: any> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storagezone/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Storage Zone
#
# POST /storagezone/{id}
# operationId: StorageZonePublic_Update
export def "storagezone Update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ReplicationZones: list # The list of replication zones enabld for the storage zone (nullable)
  --OriginUrl: string # The origin URL of the storage zone (nullable)
  --Custom404FilePath: string # The path to the custom file that will be returned in a case of 404 (nullable)
  --Rewrite404To200: string@bool-completer # Rewrite 404 status code to 200 for URLs without extension (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storagezone/($id)")
  let body = {ReplicationZones: $ReplicationZones, OriginUrl: $OriginUrl, Custom404FilePath: $Custom404FilePath, Rewrite404To200: $Rewrite404To200} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Storage Zone
#
# DELETE /storagezone/{id}
# operationId: StorageZonePublic_Delete
export def "storagezone Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteLinkedPullZones: string@bool-completer # Deletes all pull zones linked to this storage zone (default behavior) (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteLinkedPullZones" $deleteLinkedPullZones "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storagezone/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Password
#
# POST /storagezone/{id}/resetPassword
# operationId: StorageZonePublic_ResetPassword
export def "storagezone-reset-password ResetPassword" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storagezone/($id)/resetPassword")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Read-Only Password
#
# POST /storagezone/resetReadOnlyPassword
# operationId: StorageZonePublic_ResetReadOnlyPassword
export def "storagezone-reset-read-only-password ResetReadOnlyPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # The ID of the storage zone that should have the read-only password reset (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storagezone/resetReadOnlyPassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Allowed Referer
#
# POST /videolibrary/{id}/addAllowedReferrer
# operationId: AddAllowedReferrerEndpoint_AddAllowedReferrer
export def "videolibrary-add-allowed-referrer AddAllowedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be added as an allowed referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/addAllowedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Blocked Referer
#
# POST /videolibrary/{id}/addBlockedReferrer
# operationId: AddBlockedReferrerEndpoint_AddBlockedReferrer
export def "videolibrary-add-blocked-referrer AddBlockedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be added as a blocked referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/addBlockedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Video Library
#
# POST /videolibrary
# operationId: AddVideoLibraryEndpoint_AddVideoLibrary
export def "videolibrary AddVideoLibrary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # The name of the Video Library.
  --ReplicationRegions: list # The geo-replication regions of the underlying storage zone (nullable)
  --PlayerVersion: int # (Optional) Sets player version used for this library (nullable, format: int32)
  --EncodingTier: any # (Optional) Defines encoding tier. Premium is a paid tier that offers prioritized encoding and extra codec support. (nullable)
  --JitEncodingEnabled: string@bool-completer # (Optional) Determines whether JIT encoding should be used for the library. Supported in premium encoding only. (nullable)
  --OutputCodecs: string # (Optional) Specifies which video codecs are used for encoding, provided as a comma-separated (CSV) string. Free encoding tier supports only x264. A premium encoding tier adds support for vp9, hevc, and av1. (nullable)
  --EnabledResolutions: string # (Optional) Sets the enabled resolutions for the transcoding. At least one resolution should be enabled. Possible values: 240p, 360p, 480p, 720p, 1080p, 1440p, 2160p (nullable)
  --BlockNoneReferrer: string@bool-completer # (Optional) Determines if requests without a referer should be blocked. (nullable)
  --EnableMP4Fallback: string@bool-completer # (Optional) Determines if MP4 fallback should be enabled for this library. (nullable)
  --KeepOriginalFiles: string@bool-completer # (Optional) Determines if the original file should be kept after the video is processed. (nullable)
  --AllowDirectPlay: string@bool-completer # (Optional) Determines if direct play URLs should be enabled for the library (nullable)
  --EnableMultiAudioTrackSupport: string@bool-completer # (Optional) Determines if multiple output audio track support is enabled on video library. (nullable)
  --EnableTranscribing: string@bool-completer # (Optional) Enables automatic audio transcribing for this library. (nullable)
  --TranscribingCaptionLanguages: list # (Optional) Languages that captions will be automatically transcribed to. (nullable)
  --EnableTranscribingTitleGeneration: string@bool-completer # (Optional) Determines if automatic transcribing title generation is enabled for this library. Enabling any smart generation feature turns on transcribing automatically. (nullable)
  --EnableTranscribingDescriptionGeneration: string@bool-completer # (Optional) Determines if automatic transcribing description generation is enabled for this library. Enabling any smart generation feature turns on transcribing automatically. (nullable)
  --EnableTranscribingChaptersGeneration: string@bool-completer # (Optional) Determines if automatic transcribing chapters generation is enabled for this library. Enabling any smart generation feature turns on transcribing automatically. (nullable)
  --EnableTranscribingMomentsGeneration: string@bool-completer # (Optional) Determines if automatic transcribing moments generation is enabled for this library. Enabling any smart generation feature turns on transcribing automatically. (nullable)
  --AllowEarlyPlay: string@bool-completer # (Optional) Enables Early Play. Enabling this also exposes originals via CDN settings consistent with the video library update API. (nullable)
]: any -> record<Id: int, Name: string, VideoCount: int, TrafficUsage: int, StorageUsage: int, DateCreated: string, DateModified: string, ReplicationRegions: list<string>, ApiKey: string, ReadOnlyApiKey: string, HasWatermark: bool, WatermarkPositionLeft: int, WatermarkPositionTop: int, WatermarkWidth: int, PullZoneId: int, StorageZoneId: int, WatermarkHeight: int, EnabledResolutions: string, ViAiPublisherId: string, VastTagUrl: string, WebhookUrl: string, CaptionsFontSize: int, CaptionsFontColor: string, CaptionsBackground: string, UILanguage: string, AllowEarlyPlay: bool, PlayerTokenAuthenticationEnabled: bool, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockNoneReferrer: bool, EnableMP4Fallback: bool, KeepOriginalFiles: bool, AllowDirectPlay: bool, EnableDRM: bool, DrmVersion: any, AppleFairPlayDrm: any, GoogleWidevineDrm: any, Bitrate240p: int, Bitrate360p: int, Bitrate480p: int, Bitrate720p: int, Bitrate1080p: int, Bitrate1440p: int, Bitrate2160p: int, ApiAccessKey: string, ShowHeatmap: bool, EnableContentTagging: bool, PullZoneType: any, CustomHTML: string, Controls: string, PlaybackSpeeds: string, PlayerKeyColor: string, FontFamily: string, WatermarkVersion: int, EnableTranscribing: bool, EnableTranscribingTitleGeneration: bool, EnableTranscribingDescriptionGeneration: bool, EnableTranscribingChaptersGeneration: bool, EnableTranscribingMomentsGeneration: bool, TranscribingCaptionLanguages: list<string>, EnableCaptionsInPlaylist: bool, RememberPlayerPosition: bool, EnableMultiAudioTrackSupport: bool, UseSeparateAudioStream: bool, JitEncodingEnabled: bool, EncodingTier: any, OutputCodecs: string, DrmBasePriceOverride: float, DrmCostPerLicenseOverride: float, TranscribingPriceOverride: float, PremiumEncodingPriceOverride: float, MonthlyChargesTranscribing: float, MonthlyChargesPremiumEncoding: float, MonthlyChargesEnterpriseDrm: float, FeatureFlags: string, PlayerVersion: int, RemoveMetadataFromFallbackVideos: bool, ScaleVideoUsingBothDimensions: bool, ExposeOriginals: bool, ExposeVideoMetadata: bool, EnableCompactControls: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videolibrary")
  let body = {Name: $Name, ReplicationRegions: $ReplicationRegions, PlayerVersion: $PlayerVersion, EncodingTier: $EncodingTier, JitEncodingEnabled: $JitEncodingEnabled, OutputCodecs: $OutputCodecs, EnabledResolutions: $EnabledResolutions, BlockNoneReferrer: $BlockNoneReferrer, EnableMP4Fallback: $EnableMP4Fallback, KeepOriginalFiles: $KeepOriginalFiles, AllowDirectPlay: $AllowDirectPlay, EnableMultiAudioTrackSupport: $EnableMultiAudioTrackSupport, EnableTranscribing: $EnableTranscribing, TranscribingCaptionLanguages: $TranscribingCaptionLanguages, EnableTranscribingTitleGeneration: $EnableTranscribingTitleGeneration, EnableTranscribingDescriptionGeneration: $EnableTranscribingDescriptionGeneration, EnableTranscribingChaptersGeneration: $EnableTranscribingChaptersGeneration, EnableTranscribingMomentsGeneration: $EnableTranscribingMomentsGeneration, AllowEarlyPlay: $AllowEarlyPlay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Video Libraries
#
# GET /videolibrary
# operationId: ListVideoLibrariesEndpoint_ListVideoLibraries
export def "videolibrary ListVideoLibraries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 0
  --perPage: int # format: int32, default: 1000
  --search: string # The search term that will be used to filter the results (nullable)
]: nothing -> record<Items: table<Id: int, Name: string, VideoCount: int, TrafficUsage: int, StorageUsage: int, DateCreated: string, DateModified: string, ReplicationRegions: list, ApiKey: string, ReadOnlyApiKey: string, HasWatermark: bool, WatermarkPositionLeft: int, WatermarkPositionTop: int, WatermarkWidth: int, PullZoneId: int, StorageZoneId: int, WatermarkHeight: int, EnabledResolutions: string, ViAiPublisherId: string, VastTagUrl: string, WebhookUrl: string, CaptionsFontSize: int, CaptionsFontColor: string, CaptionsBackground: string, UILanguage: string, AllowEarlyPlay: bool, PlayerTokenAuthenticationEnabled: bool, AllowedReferrers: list, BlockedReferrers: list, BlockNoneReferrer: bool, EnableMP4Fallback: bool, KeepOriginalFiles: bool, AllowDirectPlay: bool, EnableDRM: bool, DrmVersion: any, AppleFairPlayDrm: any, GoogleWidevineDrm: any, Bitrate240p: int, Bitrate360p: int, Bitrate480p: int, Bitrate720p: int, Bitrate1080p: int, Bitrate1440p: int, Bitrate2160p: int, ApiAccessKey: string, ShowHeatmap: bool, EnableContentTagging: bool, PullZoneType: any, CustomHTML: string, Controls: string, PlaybackSpeeds: string, PlayerKeyColor: string, FontFamily: string, WatermarkVersion: int, EnableTranscribing: bool, EnableTranscribingTitleGeneration: bool, EnableTranscribingDescriptionGeneration: bool, EnableTranscribingChaptersGeneration: bool, EnableTranscribingMomentsGeneration: bool, TranscribingCaptionLanguages: list, EnableCaptionsInPlaylist: bool, RememberPlayerPosition: bool, EnableMultiAudioTrackSupport: bool, UseSeparateAudioStream: bool, JitEncodingEnabled: bool, EncodingTier: any, OutputCodecs: string, DrmBasePriceOverride: float, DrmCostPerLicenseOverride: float, TranscribingPriceOverride: float, PremiumEncodingPriceOverride: float, MonthlyChargesTranscribing: float, MonthlyChargesPremiumEncoding: float, MonthlyChargesEnterpriseDrm: float, FeatureFlags: string, PlayerVersion: int, RemoveMetadataFromFallbackVideos: bool, ScaleVideoUsingBothDimensions: bool, ExposeOriginals: bool, ExposeVideoMetadata: bool, EnableCompactControls: bool>, CurrentPage: int, TotalItems: int, HasMoreItems: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videolibrary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Watermark
#
# PUT /videolibrary/{id}/watermark
# operationId: AddWatermarkEndpoint_AddWatermark
export def "videolibrary-watermark AddWatermark" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Watermark
#
# DELETE /videolibrary/{id}/watermark
# operationId: DeleteWatermarkEndpoint_DeleteWatermark
export def "videolibrary-watermark DeleteWatermark" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Video Library
#
# DELETE /videolibrary/{id}
# operationId: DeleteVideoLibraryEndpoint_DeleteVideoLibrary
export def "videolibrary DeleteVideoLibrary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Library
#
# GET /videolibrary/{id}
# operationId: GetVideoLibraryEndpoint_GetVideoLibrary
export def "videolibrary GetVideoLibrary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Name: string, VideoCount: int, TrafficUsage: int, StorageUsage: int, DateCreated: string, DateModified: string, ReplicationRegions: list<string>, ApiKey: string, ReadOnlyApiKey: string, HasWatermark: bool, WatermarkPositionLeft: int, WatermarkPositionTop: int, WatermarkWidth: int, PullZoneId: int, StorageZoneId: int, WatermarkHeight: int, EnabledResolutions: string, ViAiPublisherId: string, VastTagUrl: string, WebhookUrl: string, CaptionsFontSize: int, CaptionsFontColor: string, CaptionsBackground: string, UILanguage: string, AllowEarlyPlay: bool, PlayerTokenAuthenticationEnabled: bool, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockNoneReferrer: bool, EnableMP4Fallback: bool, KeepOriginalFiles: bool, AllowDirectPlay: bool, EnableDRM: bool, DrmVersion: any, AppleFairPlayDrm: any, GoogleWidevineDrm: any, Bitrate240p: int, Bitrate360p: int, Bitrate480p: int, Bitrate720p: int, Bitrate1080p: int, Bitrate1440p: int, Bitrate2160p: int, ApiAccessKey: string, ShowHeatmap: bool, EnableContentTagging: bool, PullZoneType: any, CustomHTML: string, Controls: string, PlaybackSpeeds: string, PlayerKeyColor: string, FontFamily: string, WatermarkVersion: int, EnableTranscribing: bool, EnableTranscribingTitleGeneration: bool, EnableTranscribingDescriptionGeneration: bool, EnableTranscribingChaptersGeneration: bool, EnableTranscribingMomentsGeneration: bool, TranscribingCaptionLanguages: list<string>, EnableCaptionsInPlaylist: bool, RememberPlayerPosition: bool, EnableMultiAudioTrackSupport: bool, UseSeparateAudioStream: bool, JitEncodingEnabled: bool, EncodingTier: any, OutputCodecs: string, DrmBasePriceOverride: float, DrmCostPerLicenseOverride: float, TranscribingPriceOverride: float, PremiumEncodingPriceOverride: float, MonthlyChargesTranscribing: float, MonthlyChargesPremiumEncoding: float, MonthlyChargesEnterpriseDrm: float, FeatureFlags: string, PlayerVersion: int, RemoveMetadataFromFallbackVideos: bool, ScaleVideoUsingBothDimensions: bool, ExposeOriginals: bool, ExposeVideoMetadata: bool, EnableCompactControls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Video Library
#
# POST /videolibrary/{id}
# operationId: UpdateVideoLibraryEndpoint_UpdateVideoLibrary
export def "videolibrary UpdateVideoLibrary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # (Optional) Sets name of the video library (nullable)
  --CustomHTML: string # (Optional) Sets the player custom HTML code (nullable)
  --PlayerKeyColor: string # (Optional) Sets the player key control color (nullable)
  --EnableTokenAuthentication: string@bool-completer # (Optional) Determines if the token authentication should be enabled (nullable)
  --EnableTokenIPVerification: string@bool-completer # (Optional) Determines if the token IP verification should be enabled (nullable)
  --ResetToken: string@bool-completer # (Optional) Set to true to reset the CDN and embed view token key (nullable)
  --WatermarkPositionLeft: int # (Optional) Sets the left offset of the watermark position (in %) (nullable, format: int32)
  --WatermarkPositionTop: int # (Optional) Sets the top offset of the watermark position (in %) (nullable, format: int32)
  --WatermarkWidth: int # (Optional) Sets the width of the watermark (in %) (nullable, format: int32)
  --WatermarkHeight: int # (Optional) Sets the height of the watermark (in %) (nullable, format: int32)
  --EnabledResolutions: string # (Optional) Sets the enabled resolutions for the transcoding. At least one resolution should be enabled. Possible values: 240p, 360p, 480p, 720p, 1080p, 1440p, 2160p (nullable)
  --ViAiPublisherId: string # (Optional) Sets the vi.ai publisher ID (nullable)
  --VastTagUrl: string # (Optional) Sets the Vast tag URL (nullable)
  --WebhookUrl: string # (Optional) Sets the webhook API url (nullable)
  --CaptionsFontSize: int # (Optional) Sets the captions display font size (nullable, format: int32)
  --CaptionsFontColor: string # (Optional) Sets the captions display font color (nullable)
  --CaptionsBackground: string # (Optional) Sets the captions display background color (nullable)
  --UILanguage: string # (Optional) Sets the UI language of the video player. (nullable)
  --AllowEarlyPlay: string@bool-completer # (Optional) Determines if the Early-Play feature should be enabled. Enabling this will enable Expose Originals. (nullable)
  --PlayerTokenAuthenticationEnabled: string@bool-completer # (Optional) Determines if the token authentication should be enabled. (nullable)
  --BlockNoneReferrer: string@bool-completer # (Optional) Determines if requests without a referer should be blocked. (nullable)
  --EnableMP4Fallback: string@bool-completer # (Optional) Determines if MP4 fallback should be enabled for this library. (nullable)
  --KeepOriginalFiles: string@bool-completer # (Optional) Determines if the original file should be kept after the video is processed. (nullable)
  --AllowDirectPlay: string@bool-completer # (Optional) Determines if direct play URLs should be enabled for the library (nullable)
  --EnableDRM: string@bool-completer # (Optional) Determines if MediaCage DRM should be enabled for this library (nullable)
  --DrmVersion: any # (Optional) Determines MediaCage DRM version to be used for this library (nullable)
  --Controls: string # (Optional) The comma separated list of controls that will be displayed in the video player. Possible values: play-large, play, progress, current-time, mute, volume, captions, settings, pip, airplay, fullscreen. (nullable)
  --PlaybackSpeeds: string # (Optional) The comma separated list of playback speeds that will be available in the video player. Possible values: 0.25,0.5,0.75,1.0,1.25,1.5,1.75,2.0,2.5,3,3.5,4 (nullable)
  --Bitrate240p: int # (Optional) The bitrate used for encoding 240p videos (nullable, format: int32)
  --Bitrate360p: int # (Optional) The bitrate used for encoding 360p videos (nullable, format: int32)
  --Bitrate480p: int # (Optional) The bitrate used for encoding 480p videos (nullable, format: int32)
  --Bitrate720p: int # (Optional) The bitrate used for encoding 720p videos (nullable, format: int32)
  --Bitrate1080p: int # (Optional) The bitrate used for encoding 1080p videos (nullable, format: int32)
  --Bitrate1440p: int # (Optional) The bitrate used for encoding 1440p videos (nullable, format: int32)
  --Bitrate2160p: int # (Optional) The bitrate used for encoding 2160p videos (nullable, format: int32)
  --ShowHeatmap: string@bool-completer # (Optional) Determines if the video watch heatmap should be displayed in the player. (nullable)
  --EnableContentTagging: string@bool-completer # (Optional) Determines if content tagging should be enabled for this library. (nullable)
  --FontFamily: string # (Optional) The captions font family. (nullable)
  --EnableTranscribing: string@bool-completer # (Optional) Determines if the automatic audio transcribing is currently enabled for this zone. (nullable)
  --EnableTranscribingTitleGeneration: string@bool-completer # (Optional) Determines if automatic transcribing title generation is currently enabled. (nullable)
  --EnableTranscribingDescriptionGeneration: string@bool-completer # (Optional) Determines if automatic transcribing description generation is currently enabled. (nullable)
  --EnableTranscribingChaptersGeneration: string@bool-completer # (Optional) Determines if automatic transcribing chapters generation is currently enabled. (nullable)
  --EnableTranscribingMomentsGeneration: string@bool-completer # (Optional) Determines if automatic transcribing moments generation is currently enabled. (nullable)
  --TranscribingCaptionLanguages: list # (Optional) The list of languages that the captions will be automatically transcribed to. (nullable)
  --EnableCaptionsInPlaylist: string@bool-completer # (Optional) Determines if any associated captions will be automatically signaled in the HLS master playlist via EXT-X-MEDIA tags, allowing client players to show captions. (nullable)
  --RememberPlayerPosition: string@bool-completer # (Optional) Determines if the player will automatically remember the playback position. (nullable)
  --EnableMultiAudioTrackSupport: string@bool-completer # (Optional) Determines if multiple output audio track support is enabled on video library. (nullable)
  --UseSeparateAudioStream: string@bool-completer # (Optional) Determines whether output audio stream should be split from video stream segments. (nullable)
  --JitEncodingEnabled: string@bool-completer # (Optional) Determines whether JIT encoding should be used for the library. Supported in premium encoding only. (nullable)
  --EncodingTier: any # (Optional) Defines encoding tier to be used with video library. premium is a paid tier that offers either JIT encoding or prioritized encoding and extra codec support. (nullable)
  --OutputCodecs: string # (Optional) Specifies which video codecs are used for encoding, provided as a comma-separated (CSV) string. Free encoding tier supports only x264. A premium encoding tier adds support for vp9, hevc, and av1. (nullable)
  --AppleFairPlayDrm: any # (Optional) Configure Apple FairPlay DRM. Works only if Enterprise DRM is set up. (nullable)
  --GoogleWidevineDrm: any # (Optional) Configure Google Widevine DRM. Works only if Enterprise DRM is set up. (nullable)
  --PlayerVersion: int # (Optional) Sets player version used for this library (nullable, format: int32)
  --RemoveMetadataFromFallbackVideos: string@bool-completer # (Optional) Marks whether all potential video metadata should be removed from the fallback files (nullable)
  --ScaleVideoUsingBothDimensions: string@bool-completer # (Optional) Marks whether videos should be scaled using both dimensions. Prevents videos being upscaled or unexpected aspect ratio changes. (nullable)
  --ExposeOriginals: string@bool-completer # (Optional) Marks whether original video files should be exposed via CDN. Originals are not protected by DRM. Enabling Early-Play will enable this. (nullable)
  --ExposeVideoMetadata: string@bool-completer # (Optional) Marks whether video metadata in form of schema meta tags and LD+JSON should be exposed. (nullable)
  --EnableCompactControls: string@bool-completer # (Optional) Marks whether compact controls should be enabled for the player. (nullable)
]: any -> record<Id: int, Name: string, VideoCount: int, TrafficUsage: int, StorageUsage: int, DateCreated: string, DateModified: string, ReplicationRegions: list<string>, ApiKey: string, ReadOnlyApiKey: string, HasWatermark: bool, WatermarkPositionLeft: int, WatermarkPositionTop: int, WatermarkWidth: int, PullZoneId: int, StorageZoneId: int, WatermarkHeight: int, EnabledResolutions: string, ViAiPublisherId: string, VastTagUrl: string, WebhookUrl: string, CaptionsFontSize: int, CaptionsFontColor: string, CaptionsBackground: string, UILanguage: string, AllowEarlyPlay: bool, PlayerTokenAuthenticationEnabled: bool, AllowedReferrers: list<string>, BlockedReferrers: list<string>, BlockNoneReferrer: bool, EnableMP4Fallback: bool, KeepOriginalFiles: bool, AllowDirectPlay: bool, EnableDRM: bool, DrmVersion: any, AppleFairPlayDrm: any, GoogleWidevineDrm: any, Bitrate240p: int, Bitrate360p: int, Bitrate480p: int, Bitrate720p: int, Bitrate1080p: int, Bitrate1440p: int, Bitrate2160p: int, ApiAccessKey: string, ShowHeatmap: bool, EnableContentTagging: bool, PullZoneType: any, CustomHTML: string, Controls: string, PlaybackSpeeds: string, PlayerKeyColor: string, FontFamily: string, WatermarkVersion: int, EnableTranscribing: bool, EnableTranscribingTitleGeneration: bool, EnableTranscribingDescriptionGeneration: bool, EnableTranscribingChaptersGeneration: bool, EnableTranscribingMomentsGeneration: bool, TranscribingCaptionLanguages: list<string>, EnableCaptionsInPlaylist: bool, RememberPlayerPosition: bool, EnableMultiAudioTrackSupport: bool, UseSeparateAudioStream: bool, JitEncodingEnabled: bool, EncodingTier: any, OutputCodecs: string, DrmBasePriceOverride: float, DrmCostPerLicenseOverride: float, TranscribingPriceOverride: float, PremiumEncodingPriceOverride: float, MonthlyChargesTranscribing: float, MonthlyChargesPremiumEncoding: float, MonthlyChargesEnterpriseDrm: float, FeatureFlags: string, PlayerVersion: int, RemoveMetadataFromFallbackVideos: bool, ScaleVideoUsingBothDimensions: bool, ExposeOriginals: bool, ExposeVideoMetadata: bool, EnableCompactControls: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)")
  let body = {Name: $Name, CustomHTML: $CustomHTML, PlayerKeyColor: $PlayerKeyColor, EnableTokenAuthentication: $EnableTokenAuthentication, EnableTokenIPVerification: $EnableTokenIPVerification, ResetToken: $ResetToken, WatermarkPositionLeft: $WatermarkPositionLeft, WatermarkPositionTop: $WatermarkPositionTop, WatermarkWidth: $WatermarkWidth, WatermarkHeight: $WatermarkHeight, EnabledResolutions: $EnabledResolutions, ViAiPublisherId: $ViAiPublisherId, VastTagUrl: $VastTagUrl, WebhookUrl: $WebhookUrl, CaptionsFontSize: $CaptionsFontSize, CaptionsFontColor: $CaptionsFontColor, CaptionsBackground: $CaptionsBackground, UILanguage: $UILanguage, AllowEarlyPlay: $AllowEarlyPlay, PlayerTokenAuthenticationEnabled: $PlayerTokenAuthenticationEnabled, BlockNoneReferrer: $BlockNoneReferrer, EnableMP4Fallback: $EnableMP4Fallback, KeepOriginalFiles: $KeepOriginalFiles, AllowDirectPlay: $AllowDirectPlay, EnableDRM: $EnableDRM, DrmVersion: $DrmVersion, Controls: $Controls, PlaybackSpeeds: $PlaybackSpeeds, Bitrate240p: $Bitrate240p, Bitrate360p: $Bitrate360p, Bitrate480p: $Bitrate480p, Bitrate720p: $Bitrate720p, Bitrate1080p: $Bitrate1080p, Bitrate1440p: $Bitrate1440p, Bitrate2160p: $Bitrate2160p, ShowHeatmap: $ShowHeatmap, EnableContentTagging: $EnableContentTagging, FontFamily: $FontFamily, EnableTranscribing: $EnableTranscribing, EnableTranscribingTitleGeneration: $EnableTranscribingTitleGeneration, EnableTranscribingDescriptionGeneration: $EnableTranscribingDescriptionGeneration, EnableTranscribingChaptersGeneration: $EnableTranscribingChaptersGeneration, EnableTranscribingMomentsGeneration: $EnableTranscribingMomentsGeneration, TranscribingCaptionLanguages: $TranscribingCaptionLanguages, EnableCaptionsInPlaylist: $EnableCaptionsInPlaylist, RememberPlayerPosition: $RememberPlayerPosition, EnableMultiAudioTrackSupport: $EnableMultiAudioTrackSupport, UseSeparateAudioStream: $UseSeparateAudioStream, JitEncodingEnabled: $JitEncodingEnabled, EncodingTier: $EncodingTier, OutputCodecs: $OutputCodecs, AppleFairPlayDrm: $AppleFairPlayDrm, GoogleWidevineDrm: $GoogleWidevineDrm, PlayerVersion: $PlayerVersion, RemoveMetadataFromFallbackVideos: $RemoveMetadataFromFallbackVideos, ScaleVideoUsingBothDimensions: $ScaleVideoUsingBothDimensions, ExposeOriginals: $ExposeOriginals, ExposeVideoMetadata: $ExposeVideoMetadata, EnableCompactControls: $EnableCompactControls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Languages
#
# GET /videolibrary/languages
# operationId: GetVideoLibraryLanguagesEndpoint_GetVideoLibraryLanguages
export def "videolibrary-languages GetVideoLibraryLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<ShortCode: string, Name: string, SupportPlayerTranslation: bool, SupportTranscribing: bool, TranscribingAccuracy: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videolibrary/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Allowed Referer
#
# POST /videolibrary/{id}/removeAllowedReferrer
# operationId: RemoveAllowedReferrerEndpoint_RemoveAllowedReferrer
export def "videolibrary-remove-allowed-referrer RemoveAllowedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be removed as an allowed referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/removeAllowedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Blocked Referer
#
# POST /videolibrary/{id}/removeBlockedReferrer
# operationId: RemoveBlockedReferrerEndpoint_RemoveBlockedReferrer
export def "videolibrary-remove-blocked-referrer RemoveBlockedReferrer" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Hostname: string # The hostname that will be removed as a blocked referer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/removeBlockedReferrer")
  let body = {Hostname: $Hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset API Key
#
# POST /videolibrary/{id}/resetApiKey
# operationId: ResetVideoLibraryApiKeyEndpoint_ResetVideoLibraryApiKey
export def "videolibrary-reset-api-key ResetVideoLibraryApiKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/resetApiKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Read Only API Key
#
# POST /videolibrary/{id}/resetReadOnlyApiKey
# operationId: ResetVideoLibraryReadOnlyApiKeyEndpoint_ResetVideoLibraryReadOnlyApiKey
export def "videolibrary-reset-read-only-api-key ResetVideoLibraryReadOnlyApiKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/resetReadOnlyApiKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Library Transcribing Statistics
#
# GET /videolibrary/{id}/transcribing/statistics
# operationId: GetTranscribingStatisticsEndpoint_Statistics
export def "videolibrary-transcribing-statistics Statistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 14 days will be returned (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, current date will be used (nullable, format: date-time)
]: nothing -> record<TotalTranscriptionSeconds: int, TranscriptionSecondsChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videolibrary/($id)/transcribing/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Live Thumbnail
#
# PUT /videolibrary/{id}/live/thumbnail
# operationId: AddLiveThumbnailEndpoint_AddThumbnail
export def "videolibrary-live-thumbnail AddThumbnail" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/live/thumbnail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Live Thumbnail
#
# DELETE /videolibrary/{id}/live/thumbnail
# operationId: DeleteLiveThumbnailEndpoint_DeleteThumbnail
export def "videolibrary-live-thumbnail DeleteThumbnail" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/live/thumbnail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Live Watermark
#
# PUT /videolibrary/{id}/live/watermark
# operationId: AddLiveWatermarkEndpoint_AddWatermark
export def "videolibrary-live-watermark AddWatermark" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/live/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Live Watermark
#
# DELETE /videolibrary/{id}/live/watermark
# operationId: DeleteLiveWatermarkEndpoint_DeleteWatermark
export def "videolibrary-live-watermark DeleteWatermark" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videolibrary/($id)/live/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Library DRM Statistics
#
# GET /videolibrary/{id}/drm/statistics
# operationId: GetDrmStatisticsEndpoint_Statistics
export def "videolibrary-drm-statistics Statistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 14 days will be returned (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, current date will be used (nullable, format: date-time)
]: nothing -> record<TotalLicensesIssued: int, LicensesIssuedChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videolibrary/($id)/drm/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close the account
#
# POST /user/closeaccount
# operationId: CloseAccountEndpoint_CloseAccount
export def "user-closeaccount CloseAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Password: string # nullable
  --Reason: string # nullable
]: any -> record<Success: bool, Message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/closeaccount")
  let body = {Password: $Password, Reason: $Reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /user/audit/{date}
#
# operationId: GetUserAuditLogEndpoint_GetUserAuditLog
export def "user-audit GetUserAuditLog" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Product: list # nullable
  --ResourceType: list # nullable
  --ResourceId: list # nullable
  --ActorId: list # nullable
  --Order: string@Order-completer
  --ContinuationToken: string # nullable
  --Limit: int # format: int32
]: nothing -> record<Logs: table<Timestamp: string, Product: string, ResourceType: string, ResourceId: string, ResourceOwner: string, Action: string, ActorId: string, ActorType: string, Diff: string>, HasMoreData: bool, ContinuationToken: string, StartToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Product" $Product "multi") (serialize-qp "ResourceType" $ResourceType "multi") (serialize-qp "ResourceId" $ResourceId "multi") (serialize-qp "ActorId" $ActorId "multi") (serialize-qp "Order" $Order "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "Limit" $Limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/audit/($date)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Storage Zone Regions
#
# GET /storagezone/regions
# operationId: GetStoragezoneRegionsEndpoint_GetStorageZoneRegions
export def "storagezone-regions GetStorageZoneRegions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Id: string, Name: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storagezone/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Storage Zone Statistics
#
# GET /storagezone/{id}/statistics
# operationId: GetStoragezoneStatisticsEndpoint_StorageZoneStatistics
export def "storagezone-statistics StorageZoneStatistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
]: nothing -> record<StorageUsedChart: record, FileCountChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storagezone/($id)/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get optimizer statistics
#
# GET /pullzone/{pullZoneId}/optimizer/statistics
# operationId: GetOptimizerStatisticsEndpoint_GetOptimizerStatistics
export def "pullzone-optimizer-statistics GetOptimizerStatistics" [
  pullZoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --hourly: string@bool-completer # (Optional) If true, the statistics data will be returned in hourly groupping. (default: false)
]: nothing -> record<RequestsOptimizedChart: record, AverageCompressionChart: record, TrafficSavedChart: record, AverageProcessingTimeChart: record, TotalRequestsOptimized: float, TotalTrafficSaved: float, AverageProcessingTime: float, AverageCompressionRatio: float> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/optimizer/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Origin Shield Queue Statistics
#
# GET /pullzone/{pullZoneId}/originshield/queuestatistics
# operationId: GetOriginShieldConcurrencyStatisticsEndpoint_GetOriginShieldConcurrencyStatistics
export def "pullzone-originshield-queuestatistics GetOriginShieldConcurrencyStatistics" [
  pullZoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --hourly: string@bool-completer # (Optional) If true, the statistics data will be returned in hourly groupping. (default: false)
]: nothing -> record<ConcurrentRequestsChart: record, QueuedRequestsChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/originshield/queuestatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SafeHop Statistics
#
# GET /pullzone/{pullZoneId}/safehop/statistics
# operationId: GetSafeHopStatisticsEndpoint_GetSafeHopStatistics
export def "pullzone-safehop-statistics GetSafeHopStatistics" [
  pullZoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --hourly: string@bool-completer # (Optional) If true, the statistics data will be returned in hourly groupping. (default: false)
]: nothing -> record<RequestsRetriedChart: record, RequestsSavedChart: record, TotalRequestsRetried: float, TotalRequestsSaved: float> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pullzone/($pullZoneId)/safehop/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Statistics
#
# GET /statistics
# operationId: StatisticsPublic_GetStatistics
export def "statistics GetStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned. (nullable, format: date-time)
  --pullZone: int # (Optional) If set, the statistics will be only returned for the given Pull Zone (format: int64, default: -1)
  --serverZoneId: int # (Optional) If set, the statistics will be only returned for the given region ID (format: int64, default: -1)
  --loadErrors: string@bool-completer # (Optional) If set, the respose will contain the non-2xx response (default: false)
  --hourly: string@bool-completer # (Optional) If true, the statistics data will be returned in hourly groupping. (default: false)
  --exactRange: string@bool-completer # (Optional) If true and hourly=true, the exact hour components of dateFrom and dateTo will be preserved instead of rounding to full-day boundaries. (default: false)
  --loadOriginResponseTimes: string@bool-completer # Load Origin Response Times (default: false)
  --loadOriginTraffic: string@bool-completer # Load Origin Traffic (default: false)
  --loadRequestsServed: string@bool-completer # Load Requests Served (default: false)
  --loadBandwidthUsed: string@bool-completer # Load Bandwidth Used (default: false)
  --loadOriginShieldBandwidth: string@bool-completer # Load Origin Shield Bandwidth (default: false)
  --loadGeographicTrafficDistribution: string@bool-completer # Load Geographic Traffic Distribution (default: false)
  --loadUserBalanceHistory: string@bool-completer # Load User Balance History (default: false)
]: nothing -> record<TotalBandwidthUsed: int, TotalOriginTraffic: int, AverageOriginResponseTime: int, OriginResponseTimeChart: record, TotalRequestsServed: int, CacheHitRate: float, BandwidthUsedChart: record, BandwidthCachedChart: record, CacheHitRateChart: record, RequestsServedChart: record, PullRequestsPulledChart: record, OriginShieldBandwidthUsedChart: record, OriginShieldInternalBandwidthUsedChart: record, OriginTrafficChart: record, UserBalanceHistoryChart: record, GeoTrafficDistribution: record, Error3xxChart: record, Error4xxChart: record, Error5xxChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "pullZone" $pullZone "scalar") (serialize-qp "serverZoneId" $serverZoneId "scalar") (serialize-qp "loadErrors" $loadErrors "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "exactRange" $exactRange "scalar") (serialize-qp "loadOriginResponseTimes" $loadOriginResponseTimes "scalar") (serialize-qp "loadOriginTraffic" $loadOriginTraffic "scalar") (serialize-qp "loadRequestsServed" $loadRequestsServed "scalar") (serialize-qp "loadBandwidthUsed" $loadBandwidthUsed "scalar") (serialize-qp "loadOriginShieldBandwidth" $loadOriginShieldBandwidth "scalar") (serialize-qp "loadGeographicTrafficDistribution" $loadGeographicTrafficDistribution "scalar") (serialize-qp "loadUserBalanceHistory" $loadUserBalanceHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Global Search
#
# GET /search
# operationId: SearchPublic_GlobalSearchEndpoint
export def "search GlobalSearchEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # nullable
  --qp-from: int # format: int32, default: 0
  --size: int # format: int32, default: 20
]: nothing -> record<Query: string, Total: int, From: int, Size: int, SearchResults: table<Type: string, Id: int, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DNS Query Statistics
#
# GET /dnszone/{id}/statistics
# operationId: GetDnsZoneStatisticsEndpoint_Statistics
export def "dnszone-statistics Statistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # (Optional) The start date of the statistics. If no value is passed, the last 30 days will be returned (nullable, format: date-time)
  --dateTo: string # (Optional) The end date of the statistics. If no value is passed, the last 30 days will be returned (nullable, format: date-time)
]: nothing -> record<TotalQueriesServed: int, QueriesServedChart: record, NormalQueriesServedChart: record, SmartQueriesServedChart: record, QueriesByTypeChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dnszone/($id)/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable DNSSEC on a DNS Zone
#
# POST /dnszone/{id}/dnssec
# operationId: ManageDnsZoneDnsSecEndpoint_EnableDnsSecDnsZone
export def "dnszone-dnssec EnableDnsSecDnsZone" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Enabled: bool, DsRecord: string, Digest: string, DigestType: string, Algorithm: int, PublicKey: string, KeyTag: int, Flags: int, DsConfigured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)/dnssec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable DNSSEC on a DNS Zone
#
# DELETE /dnszone/{id}/dnssec
# operationId: ManageDnsZoneDnsSecEndpoint_DisableDnsSecDnsZone
export def "dnszone-dnssec DisableDnsSecDnsZone" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Enabled: bool, DsRecord: string, Digest: string, DigestType: string, Algorithm: int, PublicKey: string, KeyTag: int, Flags: int, DsConfigured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($id)/dnssec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a background scan for pre-existing DNS records. Can use ZoneId for existing zones or Domain for pre-zone creation scenarios.
#
# POST /dnszone/records/scan
# operationId: TriggerDnsZoneRecordScanEndpoint_TriggerScan
export def "dnszone-records-scan TriggerScan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ZoneId: int # The ID of the DNS Zone to scan. Either ZoneId or Domain must be provided, but not both. (nullable, format: int64)
  --Domain: string # The domain name to scan. Either ZoneId or Domain must be provided, but not both. Can be used even before creating the DNS zone. (nullable)
]: any -> record<JobId: string, Status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnszone/records/scan")
  let body = {ZoneId: $ZoneId, Domain: $Domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest DNS record scan result for a DNS Zone
#
# GET /dnszone/{zoneId}/records/scan
# operationId: TriggerDnsZoneRecordScanEndpoint_GetLatestScan
export def "dnszone-records-scan GetLatestScan" [
  zoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<JobId: string, ZoneId: int, Domain: string, AccountId: string, Status: int, CreatedAt: string, CompletedAt: string, Records: table<Name: string, Type: any, Ttl: int, Value: string, Priority: int, Weight: int, Port: int, IsProxied: bool>, Error: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dnszone/($zoneId)/records/scan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Billing Details
#
# GET /billing
# operationId: GetBillingDetailsEndpoint_GetBillingDetails
export def "billing GetBillingDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Balance: float, ThisMonthCharges: float, LastRechargeBalance: float, BillingRecords: table<Id: int, PaymentId: string, Amount: float, Payer: string, Timestamp: string, Type: any, InvoiceAvailable: bool, DocumentDownloadUrl: string, DetailedDocumentDownloadUrl: string>, BillingHistoryChart: record, MonthlyChargesEUTraffic: float, MonthlyChargesUSTraffic: float, MonthlyChargesASIATraffic: float, MonthlyChargesAFTraffic: float, MonthlyChargesSATraffic: float, MonthlyChargesStorage: float, MonthlyChargesDNS: float, MonthlyChargesOptimizer: float, MonthlyChargesTranscribe: float, MonthlyChargesPremiumEncoding: float, MonthlyChargesExtraPullZones: float, MonthlyChargesExtraStorageZones: float, MonthlyChargesExtraDnsZones: float, MonthlyChargesExtraVideoLibraries: float, MonthlyChargesScripting: float, MonthlyChargesScriptingRequests: float, MonthlyChargesScriptingCpu: float, MonthlyChargesDrm: float, MonthlyChargesMagicContainers: float, MonthlyMcCpu: any, MonthlyMcMemory: any, MonthlyMcIp: any, MonthlyMcIngressTraffic: any, MonthlyMcEgressTraffic: any, MonthlyMcVolumes: any, MonthlyChargesShield: float, MonthlyChargesTaxes: float, MonthlyChargesWebSockets: float, MonthlyChargesDB: float, MonthlyDBWrites: any, MonthlyDBReads: any, MonthlyDBStorage: any, MonthlyDBReplica: any, MonthlyBandwidthUsed: int, MonthlyDnsSmartQueriesServed: int, MonthlyDnsNormalQueriesServed: int, MonthlyTranscriptionMinutes: int, MonthlyPremiumEncodingBillableMinutes: int, MonthlyDRMLicensesIssued: int, MonthlyScriptingRequests: int, MonthlyScriptingCpuTime: int, BillingEnabled: bool, MinimumMonthlyCommit: float, VATRate: float, NextMonthVATRate: float, AutomaticPaymentImageUrl: string, AutomaticPaymentCardType: string, AutomaticPaymentIdentifier: string, AutomaticPaymentAmount: float, AutomaticRechargeTreshold: float, AutomaticRechargeEnabled: bool, AutomaticPaymentFailureCount: int, SavedPaymentMethods: table<Token: string, ImageUrl: string, ExpirationDate: string, LastFour: string, Email: string>, EUUSDiscount: int, SouthAmericaDiscount: int, AfricaDiscount: int, AsiaOceaniaDiscount: int, OptimizerMonthlyPrice: float, DrmBaseMonthlyPrice: float, DrmCostPerLicense: float> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Payment Request Invoice PDF
#
# GET /billing/payment-request-invoice/{id}/pdf
# operationId: DownloadPaymentRequestInvoicePdfEndpoint_DownloadPaymentRequestInvoicePdf
export def "billing-payment-request-invoice-pdf DownloadPaymentRequestInvoicePdf" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/payment-request-invoice/($id)/pdf")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pending Payment Requests
#
# GET /billing/payment-requests
# operationId: GetPaymentRequestsEndpoint_GetPaymentRequests
export def "billing-payment-requests GetPaymentRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Id: int, Amount: float, DateGenerated: string, DateDue: string, Description: string, Paid: bool, DatePaid: string, BillingInvoiceId: int, BillingInvoiceDownloadLink: string, BankTransferReference: string, TaxRate: float, TaxedAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/payment-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Billing Summary Document
#
# GET /billing/summary/{billingRecordId}/pdf
# operationId: BillingSummaryPublic_GetBillingSummaryPdf
export def "billing-summary-pdf GetBillingSummaryPdf" [
  billingRecordId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/summary/($billingRecordId)/pdf")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Billing Summary
#
# GET /billing/summary
# operationId: GetBillingSummaryEndpoint_GetSummaryEndpoint
export def "billing-summary GetSummaryEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<PullZoneId: int, MonthlyUsage: float, MonthlyBandwidthUsed: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API Keys
#
# GET /apikey
# operationId: ApiKeyPublic_GetApiKeysByAccountEndpoint
export def "apikey GetApiKeysByAccountEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --perPage: int # format: int32, default: 1000
]: nothing -> record<Items: table<Id: int, Key: string, Roles: list>, CurrentPage: int, TotalItems: int, HasMoreItems: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get affiliate details
#
# GET /billing/affiliate
# operationId: GetAffiliateDetailsEndpoint_AffiliateDetails
export def "billing-affiliate AffiliateDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AffiliateBalance: float, AffiliateUrl: string, ClaimBonusPercentage: float, MinimumPayoutAmount: float, AffiliateClicksChart: record, AffiliateSignupsChart: record, AffiliateConversionsChart: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/affiliate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
