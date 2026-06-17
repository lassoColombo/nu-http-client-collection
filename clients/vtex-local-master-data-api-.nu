# Auto-generated client for Master Data API - v2 v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Master-Data-API-/1.0/openapi.json
# Auth: --token flag or $env.MASTER_DATA_API_V2_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MASTER_DATA_API_V2_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dataentities-address-documents create-new-customer" } } | get name | first)
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

# Create new customer address
#
# POST /api/dataentities/Address/documents
# operationId: CreateNewCustomerAddress
export def "dataentities-address-documents create-new-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --address-name: string # Address name. (nullable, e.g. My house)
  --address-type: string # Type of address. For example, `Residential` or `Pickup`, among others. (nullable, e.g. residential)
  --city: string # City of the shipping address. (nullable, e.g. Rio de Janeiro)
  --complement: string # Complement to the shipping address in case it applies. (nullable, e.g. 3rd floor)
  --country: string # Three letter ISO code of the country of the shipping address. (nullable, e.g. BRA)
  --neighborhood: string # Neighborhood of the address. (nullable, e.g. Botafogo)
  --number: string # Number of the building, house or apartment in the shipping address. (nullable, e.g. 300)
  --postal-code: string # Postal Code. (nullable, e.g. 12345-000)
  --receiver-name: string # Name of the person who is going to receive the order. (nullable, e.g. Clark Kent.)
  --reference: string # Complement that might help locate the shipping address more precisely in case of delivery. (nullable, e.g. Grey building)
  --state: string # State of the shipping address. (nullable, e.g. Rio de Janeiro)
  --street: string # Street of the address. (nullable, e.g. Praia de Botafogo)
  --user-id: string # ID of the customer to whom the address belongs. (nullable, e.g. 7e03m794-a33a-11e9-84rt6-0adfa64s5a8e)
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dataentities/Address/documents" $qp)
  let body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete customer address
#
# DELETE /api/dataentities/Address/documents/{id}
# operationId: DeleteCustomerAddress
export def "dataentities-address-documents delete-customer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/dataentities/Address/documents/{id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update customer address
#
# PATCH /api/dataentities/Address/documents/{id}
# operationId: UpdateCustomerAddress
export def "dataentities-address-documents update-customer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --address-name: string # Address name. (nullable, e.g. My house)
  --address-type: string # Type of address. For example, `Residential` or `Pickup`, among others. (nullable, e.g. residential)
  --city: string # City of the shipping address. (nullable, e.g. Rio de Janeiro)
  --complement: string # Complement to the shipping address in case it applies. (nullable, e.g. 3rd floor)
  --country: string # Three letter ISO code of the country of the shipping address. (nullable, e.g. BRA)
  --neighborhood: string # Neighborhood of the address. (nullable, e.g. Botafogo)
  --number: string # Number of the building, house or apartment in the shipping address. (nullable, e.g. 300)
  --postal-code: string # Postal Code. (nullable, e.g. 12345-000)
  --receiver-name: string # Name of the person who is going to receive the order. (nullable, e.g. Clark Kent.)
  --reference: string # Complement that might help locate the shipping address more precisely in case of delivery. (nullable, e.g. Grey building)
  --state: string # State of the shipping address. (nullable, e.g. Rio de Janeiro)
  --street: string # Street of the address. (nullable, e.g. Praia de Botafogo)
  --user-id: string # ID of the customer to whom the address belongs. (nullable, e.g. 7e03m794-a33a-11e9-84rt6-0adfa64s5a8e)
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/dataentities/Address/documents/{id}") $qp)
  let body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new customer profile
#
# POST /api/dataentities/Client/documents
# operationId: CreateNewCustomerProfilev2
export def "dataentities-client-documents create-new-customer-profilev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --document: string # Client document. (nullable, e.g. 12345678900)
  --document-type: string # Client document type. (nullable, e.g. CPF)
  --email: string # Client email address. (nullable, e.g. clark.kent@examplemail.com)
  --first-name: string # Client first name. (nullable, e.g. Clark)
  --is-corporate: oneof<nothing, bool> # Indicates whether client is corporate. (nullable, e.g. false)
  --is-newsletter-opt-in: oneof<nothing, bool> # Indicates whether client otped to receive the store newsletter. (nullable, e.g. false)
  --last-name: string # Client last name. (nullable, e.g. Kent)
  --locale-default: string # Default locale, used to set store language and currency, for example. (nullable, e.g. en-US)
  --phone: string # Client telephone number. (nullable, e.g. +12025550195)
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dataentities/Client/documents" $qp)
  let body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete customer profile
#
# DELETE /api/dataentities/Client/documents/{id}
# operationId: DeleteCustomerProfile
export def "dataentities-client-documents delete-customer-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/dataentities/Client/documents/{id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update customer profile
#
# PATCH /api/dataentities/Client/documents/{id}
# operationId: UpdateCustomerProfile
export def "dataentities-client-documents update-customer-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --document: string # Client document. (nullable, e.g. 12345678900)
  --document-type: string # Client document type. (nullable, e.g. CPF)
  --email: string # Client email address. (nullable, e.g. clark.kent@examplemail.com)
  --first-name: string # Client first name. (nullable, e.g. Clark)
  --is-corporate: oneof<nothing, bool> # Indicates whether client is corporate. (nullable, e.g. false)
  --is-newsletter-opt-in: oneof<nothing, bool> # Indicates whether client otped to receive the store newsletter. (nullable, e.g. false)
  --last-name: string # Client last name. (nullable, e.g. Kent)
  --locale-default: string # Default locale, used to set store language and currency, for example. (nullable, e.g. en-US)
  --phone: string # Client telephone number. (nullable, e.g. +12025550195)
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/dataentities/Client/documents/{id}") $qp)
  let body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents
# operationId: Createorupdatepartialdocument
export def "dataentities-documents create-orupdatepartialdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new document
#
# POST /api/dataentities/{dataEntityName}/documents
# operationId: Createnewdocument
export def "dataentities-documents create-newdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete document
#
# DELETE /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Deletedocument
export def "dataentities-documents delete" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get document
#
# GET /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Getdocument
export def "dataentities-documents get" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<accountId: string, accountName: string, dataEntityId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Updatepartialdocument
export def "dataentities-documents update-partialdocument" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update entire document
#
# PUT /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Updateentiredocument
export def "dataentities-documents update-entiredocument" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate document by clusters
#
# POST /api/dataentities/{dataEntityName}/documents/{id}/clusters
# operationId: Validatedocumentbyclusters
export def "dataentities-documents-clusters validate-documentbyclusters" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/clusters"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List versions
#
# GET /api/dataentities/{dataEntityName}/documents/{id}/versions
# operationId: Listversions
export def "dataentities-documents-versions list" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --load: oneof<nothing, bool> # If true, return all the fields in each version of the document (default: true)
  --fields: string # If `load` is true, the response will return only these specific fields (default: id,dataEntityId,isNewsletterOptIn,createdBy)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<date: string, document: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "load" $load "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}
# operationId: Getversion
export def "dataentities-documents-versions get" [
  data_entity_name: string
  id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<author: string, document: record<accountId: string, accountName: string, carttag: string, checkouttag: string, dataEntityId: string, departmentVisitedTag: record<DisplayValue: string, Scores: record>, email: string, followers: list<string>, id: string, rclastsession: string, rclastsessiondate: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id, version_id: $version_id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Put version
#
# PUT /api/dataentities/{dataEntityName}/documents/{id}/versions/{versionId}
# operationId: Putversion
export def "dataentities-documents-versions update" [
  data_entity_name: string
  id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, id: $id, version_id: $version_id} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get indices
#
# GET /api/dataentities/{dataEntityName}/indices
# operationId: Getindices
export def "dataentities-indices get" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/indices"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Put indices
#
# PUT /api/dataentities/{dataEntityName}/indices
# operationId: Putindices
export def "dataentities-indices update" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: string # Comma-separted fields of the index
  --multiple: oneof<nothing, bool> # Determines whether the values need to be unique. If false, values must be unique.
  name: string # Name to identify the index
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/indices"))
  let body = {"fields": $fields, "multiple": $multiple, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete index by name
#
# DELETE /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Deleteindexbyname
export def "dataentities-indices delete-indexbyname" [
  data_entity_name: string
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, index_name: $index_name} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get index by name
#
# GET /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Getindexbyname
export def "dataentities-indices get-indexbyname" [
  data_entity_name: string
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, index_name: $index_name} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schemas
#
# GET /api/dataentities/{dataEntityName}/schemas
# operationId: Getschemas
export def "dataentities-schemas get" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/schemas"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete schema by name
#
# DELETE /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Deleteschemabyname
export def "dataentities-schemas delete-schemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, schema_name: $schema_name} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schema by name
#
# GET /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Getschemabyname
export def "dataentities-schemas get-schemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, schema_name: $schema_name} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save schema by name
#
# PUT /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Saveschemabyname
# --properties shape: {name: record}
export def "dataentities-schemas put" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  properties: record # e.g. {name: {type: string}} — shape: {name: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_entity_name: $data_entity_name, schema_name: $schema_name} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Scroll documents
#
# GET /api/dataentities/{dataEntityName}/scroll
# operationId: Scrolldocuments
export def "dataentities-scroll get" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Value of the header `X-VTEX-MD-TOKEN` returned in your first request. Send its value in this query string in the subsequent requests. The token has a timeout of 10 minutes, which refreshes after each new request. (default: {tokenValueExample})
  --fields: string # Fields that should be returned by document. Separate fields' names with commas. For example `_fields=email,firstName,document`. You can also use `_all` to fetch all fields. (default: email,firstName,document)
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --keyword: string # String to search. Use quotes for a partial query. For example, `_keyword=Maria` or `_keyword="Maria"`. (e.g. String to search)
  --qp-sort: string # Sets sorting mode in two parts. The first part is the name of the field you want to sort by. In the second part, use `ASC` for ascending or `DESC` for descending. (default: firstName ASC)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --rest-range: string # Defines the collection of documents to be returned. A range within the collection limited by 100 documents per query. (e.g. resources=0-10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_token" $qp_token "scalar") (serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/scroll") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search documents
#
# GET /api/dataentities/{dataEntityName}/search
# operationId: Searchdocuments
export def "dataentities-search list-documents" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Fields that should be returned by document. Separate fields' names with commas. For example `_fields=email,firstName,document`. You can also use `_all` to fetch all fields. (default: email,firstName,document)
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --keyword: string # String to search. Use quotes for a partial query. For example, `_keyword=Maria` or `_keyword="Maria"`. (e.g. String to search)
  --qp-sort: string # Sets sorting mode in two parts. The first part is the name of the field you want to sort by. In the second part, use `ASC` for ascending or `DESC` for descending. (default: firstName ASC)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --rest-range: string # Defines the collection of documents to be returned. A range within the collection limited by 100 documents per query. (e.g. resources=0-10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: $data_entity_name} | format pattern "/api/dataentities/{data_entity_name}/search") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
