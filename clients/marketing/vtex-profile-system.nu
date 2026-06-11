# Auto-generated client for Profile System v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Profile-System/1.0/openapi.json
# Auth: --token flag or $env.PROFILE_SYSTEM_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROFILE_SYSTEM_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "storage-profile-system-profiles CreateClientProfile" } } | get name | first)
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

# Create client profile
#
# POST /api/storage/profile-system/profiles
# operationId: CreateClientProfile
export def "storage-profile-system-profiles CreateClientProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema.  > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --birthDate: string # Client's birth date in ISO 8601 format. (e.g. 1925-11-17)
  document: string # Client's document. (e.g. 12345678900)
  documentType: string # Type of document informed in `document`. (e.g. CPF)
  email: string # Client's email address. (e.g. john.doe@example.com)
  firstName: string # Client's first name. (e.g. John)
  lastName: string # Client's last name. (e.g. Doe)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/storage/profile-system/profiles" $qp)
  let body = {birthDate: $birthDate, document: $document, documentType: $documentType, email: $email, firstName: $firstName, lastName: $lastName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update profile schema
#
# PUT /api/storage/profile-system/profiles/schema
# operationId: CreateOrUpdateProfileSchema
# --properties shape: {{fieldName}?: record}
export def "storage-profile-system-profiles-schema CreateOrUpdateProfileSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  description: string # Schema's human readable description. (e.g. This schema describes a b2c customer profile.)
  --documentTTL: int # Document time to live, in days. After this many days from its creation or update, any document cerated from this schema will be deleted. (e.g. 1825)
  properties: record # Object describing each field in your desired schema. In this object, each property is a new object, describing the field according to: `type` (string); `sensitive` (boolean); `pii` (boolean) and; `items.type` (if field is array). — shape: {{fieldName}?: record}
  required: list # Schema required fields. (e.g. [firstName, lastName, email, document, documentType])
  title: string # Schema title. (e.g. Client profile schema)
  type: string # Schema type. (e.g. object)
  --v-indexed: list # e.g. [email, document]
  --v-unique: list # e.g. [email, document]
  --version: int # Schema version. (e.g. 1)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/storage/profile-system/profiles/schema")
  let body = {description: $description, documentTTL: $documentTTL, properties: $properties, required: $required, title: $title, type: $type, v-indexed: $v_indexed, v-unique: $v_unique, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete client profile
#
# DELETE /api/storage/profile-system/profiles/{profileId}
# operationId: DeleteClientProfile
export def "storage-profile-system-profiles DeleteClientProfile" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get profile
#
# GET /api/storage/profile-system/profiles/{profileId}
# operationId: GetProfile
export def "storage-profile-system-profiles GetProfile" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates client profile
#
# PATCH /api/storage/profile-system/profiles/{profileId}
# operationId: UpdateClientProfile
export def "storage-profile-system-profiles UpdateClientProfile" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --ttl: int # This parameter sets the the Time To Live (TTL), in days, of the specific document being created or updated with this request. After this period of time from the moment of the request, the document is deleted. By sending this parameter you override the TTL set for the schema.  > Currently, the available default document schemas have no TTL. This means that documents are stored indefinitely, unless a TTL is sent when creating or updating. (e.g. 365)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --birthDate: any
  --document: any
  --documentType: any
  --email: any
  --firstName: any
  --lastName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar") (serialize-qp "ttl" $ttl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)" $qp)
  let body = {birthDate: $birthDate, document: $document, documentType: $documentType, email: $email, firstName: $firstName, lastName: $lastName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses
# operationId: GetClientAddresses
export def "storage-profile-system-profiles-addresses GetClientAddresses" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create client address
#
# POST /api/storage/profile-system/profiles/{profileId}/addresses
# operationId: CreateClientAddress
export def "storage-profile-system-profiles-addresses CreateClientAddress" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  administrativeAreaLevel1: string # Name of administrative area, such as the state or province. (e.g. RJ)
  --countryCode: string # Two letter country code. (e.g. BR)
  countryName: string # Name of the address country. (e.g. Brasil)
  locality: string # Name of address locality, such as the city. (e.g. Locality)
  localityAreaLevel1: string # Name of the address locality area, such as the neighborhood or district. (e.g. Locality area)
  postalCode: string # Address postal code. (e.g. 20200-000)
  route: string # Address route or street name. (e.g. 51)
  streetNumber: string # Address street number. (e.g. 999)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses" $qp)
  let body = {administrativeAreaLevel1: $administrativeAreaLevel1, countryCode: $countryCode, countryName: $countryName, locality: $locality, localityAreaLevel1: $localityAreaLevel1, postalCode: $postalCode, route: $route, streetNumber: $streetNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get unmasked client addresses
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/unmask
# operationId: GetUnmaskedClientAddresses
export def "storage-profile-system-profiles-addresses-unmask GetUnmaskedClientAddresses" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete address
#
# DELETE /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: DeleteAddress
export def "storage-profile-system-profiles-addresses DeleteAddress" [
  profileId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: GetAddress
export def "storage-profile-system-profiles-addresses GetAddress" [
  profileId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update client address
#
# PATCH /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}
# operationId: UpdateClientAddress
export def "storage-profile-system-profiles-addresses UpdateClientAddress" [
  profileId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --administrativeAreaLevel1: any
  --countryCode: any
  --countryName: any
  --locality: any
  --localityAreaLevel1: any
  --postalCode: any
  --route: any
  --streetNumber: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)" $qp)
  let body = {administrativeAreaLevel1: $administrativeAreaLevel1, countryCode: $countryCode, countryName: $countryName, locality: $locality, localityAreaLevel1: $localityAreaLevel1, postalCode: $postalCode, route: $route, streetNumber: $streetNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get unmasked address
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/unmask
# operationId: GetUnmaskedAddress
export def "storage-profile-system-profiles-addresses-unmask GetUnmaskedAddress" [
  profileId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}
# operationId: GetAddressByVersion
export def "storage-profile-system-profiles-addresses-versions GetAddressByVersion" [
  profileId: string
  addressId: string
  addressVersionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)/versions/($addressVersionId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get unmasked address by version
#
# GET /api/storage/profile-system/profiles/{profileId}/addresses/{addressId}/versions/{addressVersionId}/unmask
# operationId: GetUnmaskedAddressByVersion
export def "storage-profile-system-profiles-addresses-versions-unmask GetUnmaskedAddressByVersion" [
  profileId: string
  addressId: string
  addressVersionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/addresses/($addressId)/versions/($addressVersionId)/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete purchase information
#
# DELETE /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: DeletePurchaseInformation
export def "storage-profile-system-profiles-purchase-info DeletePurchaseInformation" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/purchase-info" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: GetPurchaseInformation
export def "storage-profile-system-profiles-purchase-info GetPurchaseInformation" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/purchase-info" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update purchase information
#
# PATCH /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: UpdatePurchaseInformation
export def "storage-profile-system-profiles-purchase-info UpdatePurchaseInformation" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/purchase-info" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create purchase information
#
# POST /api/storage/profile-system/profiles/{profileId}/purchase-info
# operationId: CreatePurchaseInformation
export def "storage-profile-system-profiles-purchase-info CreatePurchaseInformation" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/purchase-info" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get unmasked purchase information
#
# GET /api/storage/profile-system/profiles/{profileId}/purchase-info/unmask
# operationId: GetUnmaskedPurchaseInformation
export def "storage-profile-system-profiles-purchase-info-unmask GetUnmaskedPurchaseInformation" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/purchase-info/unmask")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get unmasked profile
#
# GET /api/storage/profile-system/profiles/{profileId}/unmask
# operationId: GetUnmaskedProfile
export def "storage-profile-system-profiles-unmask GetUnmaskedProfile" [
  profileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --alternativeKey: string # The `profileId` path parameter may be substituted by other profile fields in this request. When making this request, send the `alternativeKey` parameter with a value equal to the key of the field you wish to use as `profileId`.  > Currently, there are two possible values for this parameter: `email` and `document`. (e.g. email)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "alternativeKey" $alternativeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}
# operationId: GetProfileByVersion
export def "storage-profile-system-profiles-versions GetProfileByVersion" [
  profileId: string
  profileVersionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/versions/($profileVersionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get unmasked profile by version
#
# GET /api/storage/profile-system/profiles/{profileId}/versions/{profileVersionId}/unmask
# operationId: GetUnmaskedProfileByVersion
export def "storage-profile-system-profiles-versions-unmask GetUnmaskedProfileByVersion" [
  profileId: string
  profileVersionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/profiles/($profileId)/versions/($profileVersionId)/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create prospect
#
# POST /api/storage/profile-system/prospects
# operationId: CreateProspect
export def "storage-profile-system-prospects CreateProspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/storage/profile-system/prospects")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete prospect
#
# DELETE /api/storage/profile-system/prospects/{prospectId}
# operationId: DeleteProspect
export def "storage-profile-system-prospects DeleteProspect" [
  prospectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/prospects/($prospectId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}
# operationId: GetProspect
export def "storage-profile-system-prospects GetProspect" [
  prospectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/prospects/($prospectId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update prospect
#
# PATCH /api/storage/profile-system/prospects/{prospectId}
# operationId: UpdateProspect
export def "storage-profile-system-prospects UpdateProspect" [
  prospectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/storage/profile-system/prospects/($prospectId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get unmasked prospect
#
# GET /api/storage/profile-system/prospects/{prospectId}/unmask
# operationId: GetUnmaskedProspect
export def "storage-profile-system-prospects-unmask GetUnmaskedProspect" [
  prospectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/storage/profile-system/prospects/($prospectId)/unmask" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
