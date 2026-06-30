# Auto-generated client for Master Data API - v2 v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Master-Data-API-/1.0/openapi.json
# Auth: --token flag or $env.MASTER_DATA_API_V2_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MASTER_DATA_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dataentities/Address/documents" $qp $auth.query)
  let req_body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete customer address
#
# DELETE /api/dataentities/Address/documents/{id}
# operationId: DeleteCustomerAddress
export def "dataentities-address-documents delete-customer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Address/documents/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Update customer address
#
# PATCH /api/dataentities/Address/documents/{id}
# operationId: UpdateCustomerAddress
export def "dataentities-address-documents update-customer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Address/documents/{id}") $qp $auth.query)
  let req_body = {"addressName": $address_name, "addressType": $address_type, "city": $city, "complement": $complement, "country": $country, "neighborhood": $neighborhood, "number": $number, "postalCode": $postal_code, "receiverName": $receiver_name, "reference": $reference, "state": $state, "street": $street, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create new customer profile
#
# POST /api/dataentities/Client/documents
# operationId: CreateNewCustomerProfilev2
export def "dataentities-client-documents create-new-customer-profilev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dataentities/Client/documents" $qp $auth.query)
  let req_body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete customer profile
#
# DELETE /api/dataentities/Client/documents/{id}
# operationId: DeleteCustomerProfile
export def "dataentities-client-documents delete-customer-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Client/documents/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Update customer profile
#
# PATCH /api/dataentities/Client/documents/{id}
# operationId: UpdateCustomerProfile
export def "dataentities-client-documents update-customer-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/dataentities/Client/documents/{id}") $qp $auth.query)
  let req_body = {"document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "isNewsletterOptIn": $is_newsletter_opt_in, "lastName": $last_name, "localeDefault": $locale_default, "phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents
# operationId: Createorupdatepartialdocument
export def "dataentities-documents create-orupdatepartialdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create new document
#
# POST /api/dataentities/{dataEntityName}/documents
# operationId: Createnewdocument
export def "dataentities-documents create-newdocument" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/documents") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete document
#
# DELETE /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Deletedocument
export def "dataentities-documents delete" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get document
#
# GET /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Getdocument
export def "dataentities-documents get" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<accountId: string, accountName: string, dataEntityId: string, id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update partial document
#
# PATCH /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Updatepartialdocument
export def "dataentities-documents update-partialdocument" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"_where": $qp_where, "_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update entire document
#
# PUT /api/dataentities/{dataEntityName}/documents/{id}
# operationId: Updateentiredocument
export def "dataentities-documents update-entiredocument" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"_where": $qp_where, "_schema": $schema} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Validate document by clusters
#
# POST /api/dataentities/{dataEntityName}/documents/{id}/clusters
# operationId: Validatedocumentbyclusters
export def "dataentities-documents-clusters create-validatedocumentbyclusters" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/clusters") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List versions
#
# GET /api/dataentities/{dataEntityName}/documents/{id}/versions
# operationId: Listversions
export def "dataentities-documents-versions list" [
  data_entity_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "load" $load "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"load": $load, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<author: string, document: record<accountId: string, accountName: string, carttag: string, checkouttag: string, dataEntityId: string, departmentVisitedTag: record<DisplayValue: string, Scores: record>, email: string, followers: list<string>, id: string, rclastsession: string, rclastsessiondate: string>, id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id), version_id: (encode-path-segment $version_id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<Href: string, Id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), id: (encode-path-segment $id), version_id: (encode-path-segment $version_id)} | format pattern "/api/dataentities/{data_entity_name}/documents/{id}/versions/{version_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get indices
#
# GET /api/dataentities/{dataEntityName}/indices
# operationId: Getindices
export def "dataentities-indices get" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/indices") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Put indices
#
# PUT /api/dataentities/{dataEntityName}/indices
# operationId: Putindices
export def "dataentities-indices update" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/indices") $auth.query)
  let req_body = {"fields": $fields, "multiple": $multiple, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete index by name
#
# DELETE /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Deleteindexbyname
export def "dataentities-indices delete-indexbyname" [
  data_entity_name: string
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'index_name' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), index_name: (encode-path-segment $index_name)} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get index by name
#
# GET /api/dataentities/{dataEntityName}/indices/{index_name}
# operationId: Getindexbyname
export def "dataentities-indices get-indexbyname" [
  data_entity_name: string
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'index_name' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), index_name: (encode-path-segment $index_name)} | format pattern "/api/dataentities/{data_entity_name}/indices/{index_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get schemas
#
# GET /api/dataentities/{dataEntityName}/schemas
# operationId: Getschemas
export def "dataentities-schemas get" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete schema by name
#
# DELETE /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Deleteschemabyname
export def "dataentities-schemas delete-schemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get schema by name
#
# GET /api/dataentities/{dataEntityName}/schemas/{schemaName}
# operationId: Getschemabyname
export def "dataentities-schemas get-schemabyname" [
  data_entity_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  properties: record # e.g. {name: {type: string}} — shape: {name: record}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schemaName' must be non-empty" } }
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/api/dataentities/{data_entity_name}/schemas/{schema_name}") $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Scroll documents
#
# GET /api/dataentities/{dataEntityName}/scroll
# operationId: Scrolldocuments
export def "dataentities-scroll get-scrolldocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_token" $qp_token "scalar") (serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/scroll") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"_token": $qp_token, "_fields": $fields, "_where": $qp_where, "_schema": $schema, "_keyword": $keyword, "_sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search documents
#
# GET /api/dataentities/{dataEntityName}/search
# operationId: Searchdocuments
export def "dataentities-search get-searchdocuments" [
  data_entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o MASTER_DATA_API_V2_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o MASTER_DATA_API_V2_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($data_entity_name | is-empty) { error make --unspanned { msg: "path parameter 'dataEntityName' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "scalar") (serialize-qp "_where" $qp_where "scalar") (serialize-qp "_schema" $schema "scalar") (serialize-qp "_keyword" $keyword "scalar") (serialize-qp "_sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_entity_name: (encode-path-segment $data_entity_name)} | format pattern "/api/dataentities/{data_entity_name}/search") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "REST-Range": $rest_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"_fields": $fields, "_where": $qp_where, "_schema": $schema, "_keyword": $keyword, "_sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
