# Auto-generated client for Master Data API - v2 v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Master-Data-API-/1.0/openapi.json
# Auth: --token flag or $env.MASTER_DATA_API_V2_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MASTER_DATA_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Address/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Address/documents/{id}") $qp)
  let req_body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Client/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Client/documents/{id}") $qp)
  let req_body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<accountId: string, accountName: string, dataEntityId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"_where": $qp_where, "_schema": $schema} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter specification. (e.g. firstName is not null.)
  --schema: string # Name of the schema the document to be created needs to be compliant with. (e.g. schema)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: record
]: any -> record<Href: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"_where": $qp_where, "_schema": $schema} | compact), body: $req_body}
}

# Validate document by clusters
#
# POST /api/dataentities/{dataEntityName}/documents/{id}/clusters
# operationId: Validatedocumentbyclusters
export def "dataentities-documents-clusters create-validatedocumentbyclusters" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/clusters"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --load: oneof<nothing, bool> # If true, return all the fields in each version of the document (default: true)
  --fields: string # If `load` is true, the response will return only these specific fields (default: id,dataEntityId,isNewsletterOptIn,createdBy)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<date: string, document: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "load" $load "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"load": $load, "fields": $fields} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<author: string, document: record<accountId: string, accountName: string, carttag: string, checkouttag: string, dataEntityId: string, departmentVisitedTag: record<DisplayValue: string, Scores: record>, email: string, followers: list<string>, id: string, rclastsession: string, rclastsessiondate: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id), version_id: (encode-path-segment $version_id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id), version_id: (encode-path-segment $version_id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/indices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: string # Comma-separted fields of the index
  --multiple: oneof<nothing, bool> # Determines whether the values need to be unique. If false, values must be unique.
  name: string # Name to identify the index
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/indices"))
  let req_body = {"fields": $fields, "multiple": $multiple, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'index_name' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), index_name: (encode-path-segment $index_name)} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'index_name' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), index_name: (encode-path-segment $index_name)} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Save schema by name
#
# PUT /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Saveschemabyname
# --properties shape: {name: record}
export def "dataentities-schemas update-saveschemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  properties: record # e.g. {name: {type: string}} — shape: {name: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}"))
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Scroll documents
#
# GET /api/dataentities/{dataEntityName}/scroll
# operationId: Scrolldocuments
export def "dataentities-scroll get-scrolldocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_token" $qp_token "scalar") (serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/scroll") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_token": $qp_token, "_fields": $fields, "_where": $qp_where, "_schema": $schema, "_keyword": $keyword, "_sort": $qp_sort} | compact), body: null}
}

# Search documents
#
# GET /api/dataentities/{dataEntityName}/search
# operationId: Searchdocuments
export def "dataentities-search get-searchdocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_fields": $fields, "_where": $qp_where, "_schema": $schema, "_keyword": $keyword, "_sort": $qp_sort} | compact), body: null}
}
