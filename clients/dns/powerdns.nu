# Auto-generated client for PowerDNS Authoritative HTTP API v0.0.13
# Source: https://api.apis.guru/v2/specs/powerdns.local/0.0.13/swagger.json
# Auth: --token flag or $env.POWERDNS_AUTHORITATIVE_HTTP_API_TOKEN

const BASE_URL = "https://localhost/api/v1"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POWERDNS_AUTHORITATIVE_HTTP_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://localhost/api/v1"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def kind-completer [] { ["Master" "Native" "Slave"] }
def keytype-completer [] { ["csk" "ksk" "zsk"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "servers listServers" } } | get name | first)
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

# List all servers
#
# GET /servers
# operationId: listServers
export def "servers listServers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<config_url: string, daemon_type: string, id: string, type: string, url: string, version: string, zones_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a server
#
# GET /servers/{server_id}
# operationId: listServer
export def "servers listServer" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config_url: string, daemon_type: string, id: string, type: string, url: string, version: string, zones_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flush a cache-entry by name
#
# PUT /servers/{server_id}/cache/flush
# operationId: cacheFlushByName
export def "servers-cache-flush cacheFlushByName" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # The domain name to flush from the cache
]: nothing -> record<count: float, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/cache/flush" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all ConfigSettings for a single server
#
# GET /servers/{server_id}/config
# operationId: getConfig
export def "servers-config list" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a specific ConfigSetting for a single server
#
# GET /servers/{server_id}/config/{config_setting_name}
# operationId: getConfigSetting
export def "servers-config get" [
  server_id: string
  config_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/config/($config_setting_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search the data inside PowerDNS
#
# GET /servers/{server_id}/search-data
# operationId: searchData
export def "servers-search-data searchData" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # The string to search for
  --max: int # Maximum number of entries to return
  --object-type: string # Type of data to search for, one of “all”, “zone”, “record”, “comment”
]: nothing -> table<content: string, disabled: bool, name: string, object_type: string, ttl: int, type: string, zone: string, zone_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "object_type" $object_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/search-data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query statistics.
#
# GET /servers/{server_id}/statistics
# operationId: getStats
export def "servers-statistics get" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statistic: string # When set to the name of a specific statistic, only this value is returned. If no statistic with that name exists, the response has a 422 status and an error message.
  --includerings: string@bool-completer # “true” (default) or “false”, whether to include the Ring items, which can contain thousands of log messages or queried domains. Setting this to ”false” may make the response a lot smaller. (default: true)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistic" $statistic "scalar") (serialize-qp "includerings" $includerings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all TSIGKeys on the server, except the actual key
#
# GET /servers/{server_id}/tsigkeys
# operationId: listTSIGKeys
export def "servers-tsigkeys listTSIGKeys" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<algorithm: string, id: string, key: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/tsigkeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a TSIG key
#
# POST /servers/{server_id}/tsigkeys
# operationId: createTSIGKey
export def "servers-tsigkeys createTSIGKey" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # The algorithm of the TSIG key
  --key: string # The Base64 encoded secret key, empty when listing keys. MAY be empty when POSTing to have the server generate the key material
  --name: string # The name of the key
]: any -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/tsigkeys")
  let body = {algorithm: $algorithm, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the TSIGKey with tsigkey_id
#
# DELETE /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: deleteTSIGKey
export def "servers-tsigkeys delete" [
  server_id: string
  tsigkey_id: string
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
  let full_url = (build-url $base $"/servers/($server_id)/tsigkeys/($tsigkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific TSIGKeys on the server, including the actual key
#
# GET /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: getTSIGKey
export def "servers-tsigkeys get" [
  server_id: string
  tsigkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/tsigkeys/($tsigkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The TSIGKey at tsigkey_id can be changed in multiple ways:  * Changing the Name, this will remove the key with tsigkey_id after adding.  * Changing the Algorithm  * Changing the Key  Only the relevant fields have to be provided in the request body.
#
# PUT /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: putTSIGKey
export def "servers-tsigkeys put" [
  server_id: string
  tsigkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algorithm: string # The algorithm of the TSIG key
  --key: string # The Base64 encoded secret key, empty when listing keys. MAY be empty when POSTing to have the server generate the key material
  --name: string # The name of the key
]: any -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/tsigkeys/($tsigkey_id)")
  let body = {algorithm: $algorithm, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all Zones in a server
#
# GET /servers/{server_id}/zones
# operationId: listZones
export def "servers-zones listZones" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --zone: string # When set to the name of a zone, only this zone is returned. If no zone with that name exists, the response is an empty array. This can e.g. be used to check if a zone exists in the database without having to guess/encode the zone's id or to check if a zone exists.
  --dnssec: string@bool-completer # “true” (default) or “false”, whether to include the “dnssec” and ”edited_serial” fields in the Zone objects. Setting this to ”false” will make the query a lot faster. (default: true)
]: nothing -> table<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: list<record>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "zone" $zone "scalar") (serialize-qp "dnssec" $dnssec "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new domain, returns the Zone on creation.
#
# POST /servers/{server_id}/zones
# operationId: createZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones createZone" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rrsets: string@bool-completer # “true” (default) or “false”, whether to include the “rrsets” in the response Zone object. (default: true) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: string@bool-completer #  Whether or not the zone will be rectified on data changes via the API
  --dnssec: string@bool-completer # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list # The id of the TSIG keys used for master operation in this zone
  --masters: list #  List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: string@bool-completer # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: string@bool-completer # Whether or not the zone is pre-signed
  --rrsets: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --body-url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> record<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: table<changetype: string, comments: list, name: string, records: list, ttl: int, type: string>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rrsets" $rrsets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/zones" $qp)
  let body = {account: $account, api_rectify: $api_rectify, dnssec: $dnssec, edited_serial: $edited_serial, id: $id, kind: $kind, master_tsig_key_ids: $master_tsig_key_ids, masters: $masters, name: $name, nameservers: $nameservers, notified_serial: $notified_serial, nsec3narrow: $nsec3narrow, nsec3param: $nsec3param, presigned: $presigned, rrsets: $rrsets, serial: $serial, slave_tsig_key_ids: $slave_tsig_key_ids, soa_edit: $soa_edit, soa_edit_api: $soa_edit_api, type: $type, url: $body_url, zone: $zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes this zone, all attached metadata and rrsets.
#
# DELETE /servers/{server_id}/zones/{zone_id}
# operationId: deleteZone
export def "servers-zones delete" [
  server_id: string
  zone_id: string
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
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# zone managed by a server
#
# GET /servers/{server_id}/zones/{zone_id}
# operationId: listZone
export def "servers-zones listZone" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rrsets: string@bool-completer # “true” (default) or “false”, whether to include the “rrsets” in the response Zone object. (default: true)
]: nothing -> record<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: table<changetype: string, comments: list, name: string, records: list, ttl: int, type: string>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rrsets" $rrsets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates/modifies/deletes RRsets present in the payload and their comments. Returns 204 No Content on success.
#
# PATCH /servers/{server_id}/zones/{zone_id}
# operationId: patchZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones patch" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: string@bool-completer #  Whether or not the zone will be rectified on data changes via the API
  --dnssec: string@bool-completer # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list # The id of the TSIG keys used for master operation in this zone
  --masters: list #  List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: string@bool-completer # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: string@bool-completer # Whether or not the zone is pre-signed
  --rrsets: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --body-url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)")
  let body = {account: $account, api_rectify: $api_rectify, dnssec: $dnssec, edited_serial: $edited_serial, id: $id, kind: $kind, master_tsig_key_ids: $master_tsig_key_ids, masters: $masters, name: $name, nameservers: $nameservers, notified_serial: $notified_serial, nsec3narrow: $nsec3narrow, nsec3param: $nsec3param, presigned: $presigned, rrsets: $rrsets, serial: $serial, slave_tsig_key_ids: $slave_tsig_key_ids, soa_edit: $soa_edit, soa_edit_api: $soa_edit_api, type: $type, url: $body_url, zone: $zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies basic zone data.
#
# PUT /servers/{server_id}/zones/{zone_id}
# operationId: putZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones put" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: string@bool-completer #  Whether or not the zone will be rectified on data changes via the API
  --dnssec: string@bool-completer # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list # The id of the TSIG keys used for master operation in this zone
  --masters: list #  List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: string@bool-completer # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: string@bool-completer # Whether or not the zone is pre-signed
  --rrsets: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --body-url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)")
  let body = {account: $account, api_rectify: $api_rectify, dnssec: $dnssec, edited_serial: $edited_serial, id: $id, kind: $kind, master_tsig_key_ids: $master_tsig_key_ids, masters: $masters, name: $name, nameservers: $nameservers, notified_serial: $notified_serial, nsec3narrow: $nsec3narrow, nsec3param: $nsec3param, presigned: $presigned, rrsets: $rrsets, serial: $serial, slave_tsig_key_ids: $slave_tsig_key_ids, soa_edit: $soa_edit, soa_edit_api: $soa_edit_api, type: $type, url: $body_url, zone: $zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve slave zone from its master.
#
# PUT /servers/{server_id}/zones/{zone_id}/axfr-retrieve
# operationId: axfrRetrieveZone
export def "servers-zones-axfr-retrieve axfrRetrieveZone" [
  server_id: string
  zone_id: string
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
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/axfr-retrieve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all CryptoKeys for a zone, except the privatekey
#
# GET /servers/{server_id}/zones/{zone_id}/cryptokeys
# operationId: listCryptokeys
export def "servers-zones-cryptokeys listCryptokeys" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/cryptokeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Cryptokey
#
# POST /servers/{server_id}/zones/{zone_id}/cryptokeys
# operationId: createCryptokey
export def "servers-zones-cryptokeys createCryptokey" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Whether or not the key is in active use
  --algorithm: string # The name of the algorithm of the key, should be a mnemonic
  --bits: int # The size of the key
  --dnskey: string # The DNSKEY record for this key
  --ds: list # An array of DS records for this key
  --id: int # The internal identifier, read only
  --keytype: string@keytype-completer
  --privatekey: string # The private key in ISC format
  --published: string@bool-completer # Whether or not the DNSKEY record is published in the zone
  --type: string # set to "Cryptokey"
]: any -> record<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/cryptokeys")
  let body = {active: $active, algorithm: $algorithm, bits: $bits, dnskey: $dnskey, ds: $ds, id: $id, keytype: $keytype, privatekey: $privatekey, published: $published, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method deletes a key specified by cryptokey_id.
#
# DELETE /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: deleteCryptokey
export def "servers-zones-cryptokeys delete" [
  server_id: string
  zone_id: string
  cryptokey_id: string
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
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/cryptokeys/($cryptokey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all data about the CryptoKey, including the privatekey.
#
# GET /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: getCryptokey
export def "servers-zones-cryptokeys get" [
  server_id: string
  zone_id: string
  cryptokey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/cryptokeys/($cryptokey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method (de)activates a key from zone_name specified by cryptokey_id
#
# PUT /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: modifyCryptokey
export def "servers-zones-cryptokeys modifyCryptokey" [
  server_id: string
  zone_id: string
  cryptokey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Whether or not the key is in active use
  --algorithm: string # The name of the algorithm of the key, should be a mnemonic
  --bits: int # The size of the key
  --dnskey: string # The DNSKEY record for this key
  --ds: list # An array of DS records for this key
  --id: int # The internal identifier, read only
  --keytype: string@keytype-completer
  --privatekey: string # The private key in ISC format
  --published: string@bool-completer # Whether or not the DNSKEY record is published in the zone
  --type: string # set to "Cryptokey"
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/cryptokeys/($cryptokey_id)")
  let body = {active: $active, algorithm: $algorithm, bits: $bits, dnskey: $dnskey, ds: $ds, id: $id, keytype: $keytype, privatekey: $privatekey, published: $published, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the zone in AXFR format.
#
# GET /servers/{server_id}/zones/{zone_id}/export
# operationId: axfrExportZone
export def "servers-zones-export axfrExportZone" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the Metadata associated with the zone.
#
# GET /servers/{server_id}/zones/{zone_id}/metadata
# operationId: listMetadata
export def "servers-zones-metadata listMetadata" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<kind: string, metadata: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a set of metadata entries
#
# POST /servers/{server_id}/zones/{zone_id}/metadata
# operationId: createMetadata
export def "servers-zones-metadata createMetadata" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Name of the metadata
  --metadata: list # Array with all values for this metadata kind.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/metadata")
  let body = {kind: $kind, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all items of a single kind of domain metadata.
#
# DELETE /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: deleteMetadata
export def "servers-zones-metadata delete" [
  server_id: string
  zone_id: string
  metadata_kind: string
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
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/metadata/($metadata_kind)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the content of a single kind of domain metadata as a Metadata object.
#
# GET /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: getMetadata
export def "servers-zones-metadata get" [
  server_id: string
  zone_id: string
  metadata_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, metadata: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/metadata/($metadata_kind)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace the content of a single kind of domain metadata.
#
# PUT /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: modifyMetadata
export def "servers-zones-metadata modifyMetadata" [
  server_id: string
  zone_id: string
  metadata_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Name of the metadata
  --metadata: list # Array with all values for this metadata kind.
]: any -> record<kind: string, metadata: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/metadata/($metadata_kind)")
  let body = {kind: $kind, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a DNS NOTIFY to all slaves.
#
# PUT /servers/{server_id}/zones/{zone_id}/notify
# operationId: notifyZone
export def "servers-zones-notify notifyZone" [
  server_id: string
  zone_id: string
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
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/notify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rectify the zone data.
#
# PUT /servers/{server_id}/zones/{zone_id}/rectify
# operationId: rectifyZone
export def "servers-zones-rectify rectifyZone" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($server_id)/zones/($zone_id)/rectify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
