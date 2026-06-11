# Auto-generated client for Shippo external API. v2018-02-08
# Source: https://docs.goshippo.com/spec/shippoapi/public-api.yaml
# Auth: --token flag or $env.SHIPPO_EXTERNAL_API_TOKEN

const BASE_URL = "https://api.goshippo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIPPO_EXTERNAL_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.goshippo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def label-filetype-completer [] { ["PDF" "PDF_2.3x7.5" "PDF_4x6" "PDF_4x8" "PDF_A4" "PDF_A5" "PDF_A6" "PNG" "PNG_2.3x7.5" "ZPLII"] }
def carrier-completer [] { ["canada_post" "chronopost" "colissimo" "correos" "deutsche_post" "dhl_express" "dpd_de" "dpd_uk" "fedex" "hermes_uk" "mondial_relay" "poste_italiane" "royal_mail" "royal_mail_sf" "ups" "usps"] }
def carrier-completer-1 [] { ["canada_post" "ups" "usps"] }
def mass-unit-completer [] { ["g" "kg" "lb" "oz"] }
def order-status-completer [] { ["AWAITPAY" "CANCELLED" "PAID" "PARTIALLY_FULFILLED" "REFUNDED" "SHIPPED" "UNKNOWN"] }
def weight-unit-completer [] { ["g" "kg" "lb" "oz"] }
def include-completer [] { ["all" "enabled" "user"] }
def type-completer [] { ["FLAT_RATE" "FREE_SHIPPING" "LIVE_RATE"] }
def label-file-type-completer [] { ["PDF" "PDF_2.3x7.5" "PDF_4x6" "PDF_4x8" "PDF_A4" "PDF_A5" "PDF_A6" "PNG" "PNG_2.3x7.5" "ZPLII"] }
def distance-unit-completer [] { ["cm" "ft" "in" "m" "mm" "yd"] }
def event-completer [] { ["all" "batch_created" "batch_purchased" "track_updated" "transaction_created" "transaction_updated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addresses ListAddresses" } } | get name | first)
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

# List all addresses
#
# GET /addresses
# operationId: ListAddresses
export def "addresses ListAddresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100, default 5) (format: int64, default: 5)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addresses" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new address
#
# POST /addresses
# operationId: CreateAddress
export def "addresses CreateAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --name: string # **required for purchase**<br> First and Last Name of the addressee  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Either company or name required; No length validation (first 35 chars printed on label) | (e.g. Shwan Ippotle)
  --company: string # Company Name  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Max 35 characters; Either company or name required | (e.g. Shippo)
  --street1: string # **required for purchase**<br> First street line. Usually street number and street name (except for DHL Germany, see street_no).  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | At least one street line required; Max 35 characters per line | (e.g. 215 Clayton St.)
  --street2: string # Second street line.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | At least one street line required; Max 35 characters per line |
  --street3: string # Third street line. Only accepted for USPS international shipments, UPS domestic and UPS international shipments.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | At least one street line required; Max 35 characters per line | (e.g. )
  --street-no: string # Street number of the addressed building.  This field can be included in street1 for all carriers except for DHL Germany. (e.g. )
  --city: string # **required for purchase**<br> Name of a city. When creating a Quote Address, sending a city is optional but will yield more accurate Rates. Please bear in mind that city names may be ambiguous (there are 34 Springfields in the US). Pass in a state or a ZIP code (see below), if known, it will yield more accurate results.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Required; Max 35 characters | (e.g. San Francisco)
  --state: string # **required for purchase for some countries**<br> State/Province values are required for shipments from/to the US, AU, and CA. UPS requires province for some countries (i.e Ireland). To receive more accurate quotes, passing this field is recommended. Most carriers only accept two or three character state abbreviations.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Required if country requires state; Max 2 characters for US, CA, PR | (e.g. CA)
  --zip: string # **required for purchase**<br> Postal code of an Address. When creating a Quote Addresses, sending a ZIP is optional but will yield more accurate Rates.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Max 10 characters | (e.g. 94117)
  country: string # ISO 3166-1 alpha-2 country codes and country names can be used. For most consistent results, we recommend using country codes like `US` or `DE`. If using country names, please ensure they are spelled correctly and in English. Country names are converted to country codes. Refer to this <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements" target="_blank">guide</a> for a list of country codes. Sending a country is always required. (e.g. US)
  --phone: string # Addresses containing a phone number allow carriers to call the recipient when delivering the Parcel. This increases the probability of delivery and helps to avoid accessorial charges after a Parcel has been shipped.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Required; Min 1, max 15 characters | | USPS | Sender phone required for shipments during label purchase; Min 8, max 15 digits | (e.g. +1 555 341 9393)
  --email: string # E-mail address of the contact person, RFC3696/5321-compliant.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Max 80 characters | | USPS | Sender email required for shipments during label purchase | (e.g. shippotle@shippo.com)
  --is-residential: string@bool-completer # e.g. true
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you want  to attach to the object. (e.g. Customer ID 123456)
  --validate: string@bool-completer # Set to true to validate Address object. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addresses")
  let body = {name: $name, company: $company, street1: $street1, street2: $street2, street3: $street3, street_no: $street_no, city: $city, state: $state, zip: $zip, country: $country, phone: $phone, email: $email, is_residential: $is_residential, metadata: $metadata, validate: $validate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an address
#
# GET /addresses/{AddressId}
# operationId: GetAddress
export def "addresses GetAddress" [
  AddressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addresses/($AddressId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate an address
#
# GET /addresses/{AddressId}/validate
# operationId: ValidateAddress
export def "addresses-validate ValidateAddress" [
  AddressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addresses/($AddressId)/validate")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a batch
#
# POST /batches
# operationId: CreateBatch
# --batch_shipments item shape: {carrier_account?: string, metadata?: string, servicelevel_token?: string, shipment: any}
export def "batches CreateBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  default_carrier_account: string # ID of the Carrier Account object to use as the default for all shipments in this Batch.  The carrier account can be changed on a per-shipment basis by changing the carrier_account in the  corresponding BatchShipment object. (e.g. 078870331023437cb917f5187429b093)
  default_servicelevel_token: string # Token of the service level to use as the default for all shipments in this Batch.  The servicelevel can be changed on a per-shipment basis by changing the servicelevel_token in the  corresponding BatchShipment object. <a href="/shippoapi/public-api/service-levels">Servicelevel tokens can be found here.</a> (e.g. usps_priority)
  --label-filetype: string@label-filetype-completer # Print format of the <a href="https://docs.goshippo.com/docs/shipments/shippinglabelsizes/">label</a>. If empty, will use the default format set from  <a href="https://apps.goshippo.com/settings/labels">the Shippo dashboard.</a> (e.g. PDF_4x6)
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you want to attach to the object. (e.g. BATCH #1)
  batch_shipments: list # Array of BatchShipment objects. The response keeps the same order as in the request array. — item shape: {carrier_account?: string, metadata?: string, servicelevel_token?: string, shipment: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batches")
  let body = {default_carrier_account: $default_carrier_account, default_servicelevel_token: $default_servicelevel_token, label_filetype: $label_filetype, metadata: $metadata, batch_shipments: $batch_shipments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a batch
#
# GET /batches/{BatchId}
# operationId: GetBatch
export def "batches GetBatch" [
  BatchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100, default 5) (format: int64, default: 5)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/batches/($BatchId)" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add shipments to a batch
#
# POST /batches/{BatchId}/add_shipments
# operationId: AddShipmentsToBatch
export def "batches-add-shipments AddShipmentsToBatch" [
  BatchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($BatchId)/add_shipments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purchase a batch
#
# POST /batches/{BatchId}/purchase
# operationId: PurchaseBatch
export def "batches-purchase PurchaseBatch" [
  BatchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($BatchId)/purchase")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove shipments from a batch
#
# POST /batches/{BatchId}/remove_shipments
# operationId: RemoveShipmentsFromBatch
export def "batches-remove-shipments RemoveShipmentsFromBatch" [
  BatchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($BatchId)/remove_shipments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all carrier accounts
#
# GET /carrier_accounts
# operationId: ListCarrierAccounts
export def "carrier-accounts ListCarrierAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service-levels: string@bool-completer # Appends the property `service_levels` to each returned carrier account
  --carrier: string # Filter the response by the specified carrier
  --account-id: string # Filter the response by the specified carrier account Id
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100, default 5) (format: int64, default: 5)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service_levels" $service_levels "scalar") (serialize-qp "carrier" $carrier "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/carrier_accounts" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new carrier account
#
# POST /carrier_accounts
# operationId: CreateCarrierAccount
export def "carrier-accounts CreateCarrierAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  account_id: string # e.g. 321123
  --active: string@bool-completer
  carrier: string # e.g. fedex
  --metadata: string # e.g. FEDEX Account
  parameters: any
  --test: string@bool-completer # e.g. false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier_accounts")
  let body = {account_id: $account_id, active: $active, carrier: $carrier, metadata: $metadata, parameters: $parameters, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a carrier account
#
# GET /carrier_accounts/{CarrierAccountId}
# operationId: GetCarrierAccount
export def "carrier-accounts GetCarrierAccount" [
  CarrierAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/carrier_accounts/($CarrierAccountId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a carrier account
#
# PUT /carrier_accounts/{CarrierAccountId}
# operationId: UpdateCarrierAccount
export def "carrier-accounts UpdateCarrierAccount" [
  CarrierAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  account_id: string # Unique identifier of the account. Please check the <a href="https://docs.goshippo.com/docs/carriers/carrieraccounts/">carrier accounts tutorial</a>  page for the `account_id` per carrier.<br>  To protect account information, this field will be masked in any API response. (e.g. ****)
  --active: string@bool-completer # Determines whether the account is active. When creating a shipment, if no `carrier_accounts` are explicitly  passed Shippo will query all carrier accounts that have this field set. By default, this is set to True.
  carrier: string # Carrier token, see <a href="/shippoapi/public-api/carriers">Carriers</a><br> Please check the <a href="https://docs.goshippo.com/docs/carriers/carrieraccounts/">carrier accounts tutorial</a> page for all supported carriers. (e.g. usps)
  --parameters: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/carrier_accounts/($CarrierAccountId)")
  let body = {account_id: $account_id, active: $active, carrier: $carrier, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Connect an existing carrier account using OAuth 2.0
#
# GET /carrier_accounts/{CarrierAccountObjectId}/signin/initiate
# operationId: InitiateOauth2Signin
export def "carrier-accounts-signin-initiate InitiateOauth2Signin" [
  CarrierAccountObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirect-uri: string # Callback URL. The URL that tells the authorization server where to send the user back to after they approve the request. (format: uri)
  --state: string # A random string generated by the consuming application and included in the request to prevent CSRF attacks. The consuming application checks that the same value is returned after the user authorizes Shippo.
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/carrier_accounts/($CarrierAccountObjectId)/signin/initiate" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Shippo carrier account
#
# POST /carrier_accounts/register/new
# Discriminator (request): carrier = canada_post, chronopost, colissimo, correos, deutsche_post, dhl_express, dpd_de, dpd_uk, fedex, hermes_uk, mondial_relay, poste_italiane, ups, usps, royal_mail, royal_mail_sf
# operationId: RegisterCarrierAccount
# --parameters shape: {canada_post_terms: bool, company: string, email: string, full_name: string, phone: string}
export def "carrier-accounts-register-new RegisterCarrierAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  carrier: string@carrier-completer
  --parameters: record # shape: {canada_post_terms: bool, company: string, email: string, full_name: string, phone: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/carrier_accounts/register/new")
  let body = {carrier: $carrier, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Carrier Registration status
#
# GET /carrier_accounts/reg-status
# operationId: GetCarrierRegistrationStatus
export def "carrier-accounts-reg-status GetCarrierRegistrationStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier: string@carrier-completer-1 # filter by specific carrier
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier" $carrier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/carrier_accounts/reg-status" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customs declarations
#
# GET /customs/declarations
# operationId: ListCustomsDeclarations
export def "customs-declarations ListCustomsDeclarations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100, default 5) (format: int64, default: 5)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customs/declarations" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new customs declaration
#
# POST /customs/declarations
# operationId: CreateCustomsDeclaration
# --duties_payor shape: {account?: string, type?: "SENDER"|"RECIPIENT"|"THIRD_PARTY", address?: record}
# --exporter_identification shape: {eori_number?: string, tax_id?: record}
# --address_importer shape: {name?: string, company?: string, street1?: string, street2?: string, street3?: string, street_no?: string, city?: string, state?: string, zip?: string, country?: string, phone?: string, email?: string, is_residential?: bool}
# --items item shape: {description: string, eccn_ear99?: string, mass_unit: "g"|"kg"|"lb"|"oz", metadata?: string, net_weight: string, origin_country: string, quantity: int, sku_code?: string, hs_code?: string, tariff_number?: string, value_amount: string, value_currency: string}
export def "customs-declarations CreateCustomsDeclaration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --aes-itn: string # **required if eel_pfc is `AES_ITN`**<br> AES / ITN reference of the shipment.
  --b13a-filing-option: any
  --b13a-number: string # **must be provided if and only if b13a_filing_option is provided**<br> Represents:<br> the Proof of Report (POR) Number when b13a_filing_option is `FILED_ELECTRONICALLY`;<br>  the Summary ID Number when b13a_filing_option is `SUMMARY_REPORTING`;<br>  or the Exemption Number when b13a_filing_option is `NOT_REQUIRED`.
  --certificate: string # Certificate reference of the shipment.
  --certify: string@bool-completer # Expresses that the certify_signer has provided all information of this customs declaration truthfully. (e.g. true)
  certify_signer: string # Name of the person who created the customs declaration and is responsible for the validity of all  information provided. (e.g. Shawn Ippotle)
  --commercial-invoice: string@bool-completer
  --contents-explanation: string # **required if contents_type is `OTHER`**<br> Explanation of the type of goods of the shipment. (e.g. T-Shirt purchase)
  --disclaimer: string # Disclaimer for the shipment and customs information that have been provided.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Max 554 characters |
  --duties-payor: record # Specifies who will pay the duties for the shipment. Only accepted for FedEx shipments. — shape: {account?: string, type?: "SENDER"|"RECIPIENT"|"THIRD_PARTY", address?: record}
  --exporter-identification: record # Additional exporter identification that may be required to ship in certain countries — shape: {eori_number?: string, tax_id?: record}
  --exporter-reference: string # Exporter reference of an export shipment.
  --importer-reference: string # Importer reference of an import shipment.
  --is-vat-collected: string@bool-completer # Indicates whether the shipment's destination VAT has been collected. May be required for some destinations.
  --invoice: string # Invoice reference of the shipment. (e.g. #123123)
  --license: string # License reference of the shipment.
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you  want to attach to the object. (e.g. Order ID #123123)
  --notes: string # Additional notes to be included in the customs declaration.
  --address-importer: record # Object that represents the address of the importer — shape: {name?: string, company?: string, street1?: string, street2?: string, street3?: string, street_no?: string, city?: string, state?: string, zip?: string, country?: string, phone?: string, email?: string, is_residential?: bool}
  contents_type: any
  --eel-pfc: any
  --incoterm: any
  items: list # item shape: {description: string, eccn_ear99?: string, mass_unit: "g"|"kg"|"lb"|"oz", metadata?: string, net_weight: string, origin_country: string, quantity: int, sku_code?: string, hs_code?: string, tariff_number?: string, value_amount: string, value_currency: string}
  non_delivery_option: any
  --test: string@bool-completer # e.g. true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customs/declarations")
  let body = {aes_itn: $aes_itn, b13a_filing_option: $b13a_filing_option, b13a_number: $b13a_number, certificate: $certificate, certify: $certify, certify_signer: $certify_signer, commercial_invoice: $commercial_invoice, contents_explanation: $contents_explanation, disclaimer: $disclaimer, duties_payor: $duties_payor, exporter_identification: $exporter_identification, exporter_reference: $exporter_reference, importer_reference: $importer_reference, is_vat_collected: $is_vat_collected, invoice: $invoice, license: $license, metadata: $metadata, notes: $notes, address_importer: $address_importer, contents_type: $contents_type, eel_pfc: $eel_pfc, incoterm: $incoterm, items: $items, non_delivery_option: $non_delivery_option, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a customs declaration
#
# GET /customs/declarations/{CustomsDeclarationId}
# operationId: GetCustomsDeclaration
export def "customs-declarations GetCustomsDeclaration" [
  CustomsDeclarationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customs/declarations/($CustomsDeclarationId)" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all customs items
#
# GET /customs/items
# operationId: ListCustomsItems
export def "customs-items ListCustomsItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customs/items" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new customs item
#
# POST /customs/items
# operationId: CreateCustomsItem
export def "customs-items CreateCustomsItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  description: string # Text description of your item. (e.g. T-Shirt)
  --eccn-ear99: string # Export Control Classification Number, required on some exports from the United States.
  mass_unit: string@mass-unit-completer # The unit used for weight. (e.g. lb)
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you  want to attach to the object. (e.g. Order ID "123454")
  net_weight: string # Total weight of this item, i.e. quantity * weight per item. (e.g. 5)
  origin_country: string # Country of origin of the item. Example: `US` or `DE`.  All accepted values can be found on the <a href="http://www.iso.org/" target="_blank">Official ISO Website</a>.
  quantity: int # Quantity of this item in the shipment you send.  Must be greater than 0. (format: int64, e.g. 20)
  --sku-code: string # SKU code of the item, which is required by some carriers. (e.g. HM-123)
  --hs-code: string # HS code of the item, which is required by some carriers. If `tariff_number` is not provided, `hs_code` will be used.  If both `hs_code` and `tariff_number` are provided, `tariff_number` will be used. 50 character limit. (e.g. 0901.21)
  --tariff-number: string # The tariff number of the item. If `tariff_number` is not provided, `hs_code` will be used. If both `hs_code` and `tariff_number` are provided, `tariff_number` will be used. 12 character limit.
  value_amount: string # Total value of this item, i.e. quantity * value per item. (e.g. 200)
  value_currency: string # Currency used for value_amount. The <a href="http://www.xe.com/iso4217.php">official ISO 4217</a>  currency codes are used, e.g.  `USD` or `EUR`. (e.g. USD)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customs/items")
  let body = {description: $description, eccn_ear99: $eccn_ear99, mass_unit: $mass_unit, metadata: $metadata, net_weight: $net_weight, origin_country: $origin_country, quantity: $quantity, sku_code: $sku_code, hs_code: $hs_code, tariff_number: $tariff_number, value_amount: $value_amount, value_currency: $value_currency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a customs item
#
# GET /customs/items/{CustomsItemId}
# operationId: GetCustomsItem
export def "customs-items GetCustomsItem" [
  CustomsItemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customs/items/($CustomsItemId)" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a live rates request
#
# POST /live-rates
# operationId: CreateLiveRate
# --line_items item shape: {currency?: string, manufacture_country?: string, max_delivery_time?: string, max_ship_time?: string, quantity?: int, sku?: string, title?: string, total_price?: string, variant_title?: string, weight?: string, weight_unit?: "g"|"kg"|"lb"|"oz", object_id?: string}
export def "live-rates CreateLiveRate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --address-from: any # The sender address, which includes your name, company name, street address, city, state, zip code,  country, phone number, and email address (strings). Special characters should not be included in  any address element, especially name, company, and email.
  address_to: any # The recipient address, which includes the recipient's name, company name, street address, city, state, zip code,  country, phone number, and email address (strings). Special characters should not be included in  any address element, especially name, company, and email.
  line_items: list # Array of Line Item objects — item shape: {currency?: string, manufacture_country?: string, max_delivery_time?: string, max_ship_time?: string, quantity?: int, sku?: string, title?: string, total_price?: string, variant_title?: string, weight?: string, weight_unit?: "g"|"kg"|"lb"|"oz", object_id?: string}
  --parcel: any # Object ID for an existing User Parcel Template OR a fully formed Parcel object. (e.g. 5df144dca289442cv7a06)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-rates")
  let body = {address_from: $address_from, address_to: $address_to, line_items: $line_items, parcel: $parcel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show current default parcel template
#
# GET /live-rates/settings/parcel-template
# operationId: GetDefaultParcelTemplate
export def "live-rates-settings-parcel-template GetDefaultParcelTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-rates/settings/parcel-template")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update default parcel template
#
# PUT /live-rates/settings/parcel-template
# operationId: UpdateDefaultParcelTemplate
export def "live-rates-settings-parcel-template UpdateDefaultParcelTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --object-id: string # e.g. b958d3690bb04bb8b2986724872750f5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-rates/settings/parcel-template")
  let body = {object_id: $object_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear current default parcel template
#
# DELETE /live-rates/settings/parcel-template
# operationId: DeleteDefaultParcelTemplate
export def "live-rates-settings-parcel-template DeleteDefaultParcelTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-rates/settings/parcel-template")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all manifests
#
# GET /manifests
# operationId: ListManifests
export def "manifests ListManifests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100, default 5) (format: int64, default: 5)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/manifests" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new manifest
#
# POST /manifests
# operationId: CreateManifest
export def "manifests CreateManifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  carrier_account: string # ID of carrier account (e.g. adcfdddf8ec64b84ad22772bce3ea37a)
  shipment_date: string # All shipments to be submitted on this day will be closed out.  Must be in the format `2014-01-18T00:35:03.463Z` (ISO 8601 date). (e.g. 2014-05-16T23:59:59Z)
  --transactions: list # IDs transactions to use. If you set this to null or not send this parameter,  Shippo will automatically assign all applicable transactions. (e.g. [adcfdddf8ec64b84ad22772bce3ea37a])
  address_from: any
  --async: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manifests")
  let body = {carrier_account: $carrier_account, shipment_date: $shipment_date, transactions: $transactions, address_from: $address_from, async: $async} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a manifest
#
# GET /manifests/{ManifestId}
# operationId: GetManifest
export def "manifests GetManifest" [
  ManifestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manifests/($ManifestId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all orders
#
# GET /orders
# operationId: ListOrders
export def "orders ListOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --order-status: list # Filter orders by order status
  --shop-app: string # Filter orders by shop app
  --start-date: string # Filter orders created after the input date and time (ISO 8601 UTC format).  This is based on the  `placed_at` field, meaning when the order has been placed, not when the order object was created.
  --end-date: string # Filter orders created before the input date and time (ISO 8601 UTC format).  This is based on the  `placed_at` field, meaning when the order has been placed, not when the order object was created.
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar") (serialize-qp "order_status[]" $order_status "multi") (serialize-qp "shop_app" $shop_app "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new order
#
# POST /orders
# operationId: CreateOrder
# --line_items item shape: {currency?: string, manufacture_country?: string, max_delivery_time?: string, max_ship_time?: string, quantity?: int, sku?: string, title?: string, total_price?: string, variant_title?: string, weight?: string, weight_unit?: "g"|"kg"|"lb"|"oz"}
export def "orders CreateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --currency: string # **Required if total_price is provided**<br> Currency of the <code>total_price</code> and <code>total_tax</code> amounts. (e.g. USD)
  --notes: string # Custom buyer- or seller-provided notes about the order. (e.g. This customer is a VIP)
  --order-number: string # An alphanumeric identifier for the order used by the seller/buyer. This identifier doesn't need to be unique. (e.g. #1068)
  --order-status: string@order-status-completer # Current state of the order. See the <a href="https://docs.goshippo.com/docs/orders/orders/">orders tutorial</a>  for the logic of how the status is handled. (e.g. PAID)
  placed_at: string # Date and time when the order was placed. This datetime can be different from the datetime of the order object creation on Shippo. (e.g. 2016-09-23T01:28:12Z)
  --shipping-cost: string # Amount paid by the buyer for shipping. This amount can be different from the price the seller will actually pay for shipping. (e.g. 12.83)
  --shipping-cost-currency: string # **Required if shipping_cost is provided**<br> Currency of the <code>shipping_cost</code> amount. (e.g. USD)
  --shipping-method: string # Shipping method (carrier + service or other free text description) chosen by the buyer.  This value can be different from the shipping method the seller will actually choose. (e.g. USPS First Class Package)
  --subtotal-price: string # e.g. 12.1
  --total-price: string # Total amount paid by the buyer for this order. (e.g. 24.93)
  --total-tax: string # Total tax amount paid by the buyer for this order. (e.g. 0.0)
  --weight: string # Total weight of the order. (e.g. 0.4)
  --weight-unit: string@weight-unit-completer # The unit used for weight. (e.g. lb)
  --from-address: any # <a href="/shippoapi/public-api/addresses">Address</a> object of the sender / seller. Will be returned expanded by default..
  to_address: any # <a href="/shippoapi/public-api/addresses">Address</a> object of the recipient / buyer. Will be returned expanded by default.
  --line-items: list # Array of <a href="/shippoapi/public-api/orders/lineitem">line item</a> objects representing the items in this order.  All objects will be returned expanded by default. — item shape: {currency?: string, manufacture_country?: string, max_delivery_time?: string, max_ship_time?: string, quantity?: int, sku?: string, title?: string, total_price?: string, variant_title?: string, weight?: string, weight_unit?: "g"|"kg"|"lb"|"oz"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {currency: $currency, notes: $notes, order_number: $order_number, order_status: $order_status, placed_at: $placed_at, shipping_cost: $shipping_cost, shipping_cost_currency: $shipping_cost_currency, shipping_method: $shipping_method, subtotal_price: $subtotal_price, total_price: $total_price, total_tax: $total_tax, weight: $weight, weight_unit: $weight_unit, from_address: $from_address, to_address: $to_address, line_items: $line_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an order
#
# GET /orders/{OrderId}
# operationId: GetOrder
export def "orders GetOrder" [
  OrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($OrderId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all carrier parcel templates
#
# GET /parcel-templates
# operationId: ListCarrierParcelTemplates
export def "parcel-templates ListCarrierParcelTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer # filter by user or enabled
  --carrier: string # filter by specific carrier (e.g. fedex)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "carrier" $carrier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parcel-templates" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a carrier parcel templates
#
# GET /parcel-templates/{CarrierParcelTemplateToken}
# operationId: GetCarrierParcelTemplate
export def "parcel-templates GetCarrierParcelTemplate" [
  CarrierParcelTemplateToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parcel-templates/($CarrierParcelTemplateToken)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all parcels
#
# GET /parcels
# operationId: ListParcels
export def "parcels ListParcels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parcels" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new parcel
#
# POST /parcels
# operationId: CreateParcel
export def "parcels CreateParcel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parcels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an existing parcel
#
# GET /parcels/{ParcelId}
# operationId: GetParcel
export def "parcels GetParcel" [
  ParcelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parcels/($ParcelId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pickup
#
# POST /pickups
# operationId: CreatePickup
# --location shape: {address: any, building_location_type: "Back Door"|"Ring Bell"|"Security Deck"|"Shipping Dock"|"Front Door"|"Knock on Door"|"In/At Mailbox"|"Mail Room"|"Office"|"Other"|"Reception"|"Side Door", building_type?: "apartment"|"building"|"department"|"floor"|"room"|"suite", instructions?: string}
export def "pickups CreatePickup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  carrier_account: string # The object ID of your USPS or DHL Express carrier account.  You can retrieve this from your Rate requests or our <a href="/shippoapi/public-api/carrier-accounts">Carrier Accounts</a> endpoint. (e.g. adcfdddf8ec64b84ad22772bce3ea37a)
  location: record # Location where the parcel(s) will be picked up. — shape: {address: any, building_location_type: "Back Door"|"Ring Bell"|"Security Deck"|"Shipping Dock"|"Front Door"|"Knock on Door"|"In/At Mailbox"|"Mail Room"|"Office"|"Other"|"Reception"|"Side Door", building_type?: "apartment"|"building"|"department"|"floor"|"room"|"suite", instructions?: string}
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you  want to attach to the object.
  requested_end_time: string # The latest that you requested your parcels to be available for pickup.  Expressed in the timezone specified in the response. (format: date-time)
  requested_start_time: string # The earliest that you requested your parcels to be ready for pickup.  Expressed in the timezone specified in the response. (format: date-time)
  transactions: list # The transaction(s) object ID(s) for the parcel(s) that need to be picked up. (e.g. [adcfdddf8ec64b84ad22772bce3ea37a])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pickups")
  let body = {carrier_account: $carrier_account, location: $location, metadata: $metadata, requested_end_time: $requested_end_time, requested_start_time: $requested_start_time, transactions: $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a rate
#
# GET /rates/{RateId}
# operationId: GetRate
export def "rates GetRate" [
  RateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rates/($RateId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a refund
#
# POST /refunds
# operationId: CreateRefund
export def "refunds CreateRefund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --async: string@bool-completer # e.g. false
  transaction: string # e.g. 915d94940ea54c3a80cbfa328722f5a1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refunds")
  let body = {async: $async, transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all refunds
#
# GET /refunds/
# operationId: ListRefunds
export def "refunds ListRefunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refunds/")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a refund
#
# GET /refunds/{RefundId}
# operationId: GetRefund
export def "refunds GetRefund" [
  RefundId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refunds/($RefundId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all service groups
#
# GET /service-groups
# operationId: ListServiceGroups
export def "service-groups ListServiceGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service-groups")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new service group
#
# POST /service-groups
# operationId: CreateServiceGroup
# --service_levels item shape: {account_object_id?: string, service_level_token?: string}
export def "service-groups CreateServiceGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  description: string # Description for the service group (e.g. USPS shipping options)
  --flat-rate: string # String representation of an amount to be returned as the flat rate if 1. The service group is of type `LIVE_RATE` and no matching rates were found; or 2. The service group is of type `FLAT_RATE`. Either integers or decimals are accepted. Required unless type is `FREE_SHIPPING` (e.g. 5)
  --flat-rate-currency: string # required unless type is `FREE_SHIPPING`. (ISO 4217 currency) (e.g. USD)
  --free-shipping-threshold-currency: string # optional unless type is `FREE_SHIPPING`. (ISO 4217 currency) (e.g. USD)
  --free-shipping-threshold-min: string # For service groups of type `FREE_SHIPPING`, this field must be required to configure the minimum  cart total (total cost of items in the cart) for this service group to be returned for rates at  checkout. Optional unless type is `FREE_SHIPPING` (e.g. 5)
  name: string # Name for the service group that will be shown to customers in the response (e.g. USPS Shipping)
  --rate-adjustment: int # The amount in percent (%) that the service group's returned rate should be adjusted. For example, if this field is set to 5 and the matched rate price is $5.00, the returned value of the service group will be $5.25. Negative integers are also accepted and will discount the rate price by the defined percentage amount. (format: int64, e.g. 15)
  type: string@type-completer # The type of the service group.<br>  `LIVE_RATE` - Shippo will make a rating request and return real-time rates for the shipping group, only falling back to the specified flat rate amount if no rates match a service level in the service group.<br>  `FLAT_RATE` - Returns a shipping option with the specified flat rate amount.<br>  `FREE_SHIPPING` - Returns a shipping option with a price of $0 only if the total cost of items exceeds the amount defined by `free_shipping_threshold_min` (e.g. FLAT_RATE)
  service_levels: list # item shape: {account_object_id?: string, service_level_token?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service-groups")
  let body = {description: $description, flat_rate: $flat_rate, flat_rate_currency: $flat_rate_currency, free_shipping_threshold_currency: $free_shipping_threshold_currency, free_shipping_threshold_min: $free_shipping_threshold_min, name: $name, rate_adjustment: $rate_adjustment, type: $type, service_levels: $service_levels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing service group
#
# PUT /service-groups
# operationId: UpdateServiceGroup
# --service_levels item shape: {account_object_id?: string, service_level_token?: string}
export def "service-groups UpdateServiceGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  description: string # Description for the service group (e.g. USPS shipping options)
  --flat-rate: string # String representation of an amount to be returned as the flat rate if 1. The service group is of type `LIVE_RATE` and no matching rates were found; or 2. The service group is of type `FLAT_RATE`. Either integers or decimals are accepted. Required unless type is `FREE_SHIPPING` (e.g. 5)
  --flat-rate-currency: string # required unless type is `FREE_SHIPPING`. (ISO 4217 currency) (e.g. USD)
  --free-shipping-threshold-currency: string # optional unless type is `FREE_SHIPPING`. (ISO 4217 currency) (e.g. USD)
  --free-shipping-threshold-min: string # For service groups of type `FREE_SHIPPING`, this field must be required to configure the minimum  cart total (total cost of items in the cart) for this service group to be returned for rates at  checkout. Optional unless type is `FREE_SHIPPING` (e.g. 5)
  name: string # Name for the service group that will be shown to customers in the response (e.g. USPS Shipping)
  --rate-adjustment: int # The amount in percent (%) that the service group's returned rate should be adjusted. For example, if this field is set to 5 and the matched rate price is $5.00, the returned value of the service group will be $5.25. Negative integers are also accepted and will discount the rate price by the defined percentage amount. (format: int64, e.g. 15)
  type: string@type-completer # The type of the service group.<br>  `LIVE_RATE` - Shippo will make a rating request and return real-time rates for the shipping group, only falling back to the specified flat rate amount if no rates match a service level in the service group.<br>  `FLAT_RATE` - Returns a shipping option with the specified flat rate amount.<br>  `FREE_SHIPPING` - Returns a shipping option with a price of $0 only if the total cost of items exceeds the amount defined by `free_shipping_threshold_min` (e.g. FLAT_RATE)
  object_id: string # The unique identifier of the given Service Group object. (e.g. 80feb1633d4a43c898f005850)
  --is-active: string@bool-completer # True if the service group is enabled, false otherwise. (e.g. true)
  service_levels: list # item shape: {account_object_id?: string, service_level_token?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service-groups")
  let body = {description: $description, flat_rate: $flat_rate, flat_rate_currency: $flat_rate_currency, free_shipping_threshold_currency: $free_shipping_threshold_currency, free_shipping_threshold_min: $free_shipping_threshold_min, name: $name, rate_adjustment: $rate_adjustment, type: $type, object_id: $object_id, is_active: $is_active, service_levels: $service_levels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a service group
#
# DELETE /service-groups/{ServiceGroupId}
# operationId: DeleteServiceGroup
export def "service-groups DeleteServiceGroup" [
  ServiceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-groups/($ServiceGroupId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all shipments
#
# GET /shipments
# operationId: ListShipments
export def "shipments ListShipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string # The page token for paginated results
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --object-created-gt: string # Object(s) created greater than a provided date and time.
  --object-created-gte: string # Object(s) created greater than or equal to a provided date and time.
  --object-created-lt: string # Object(s) created lesser than a provided date and time.
  --object-created-lte: string # Object(s) created lesser than or equal to a provided date and time.
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_token" $page_token "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar") (serialize-qp "object_created_gt" $object_created_gt "scalar") (serialize-qp "object_created_gte" $object_created_gte "scalar") (serialize-qp "object_created_lt" $object_created_lt "scalar") (serialize-qp "object_created_lte" $object_created_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new shipment
#
# POST /shipments
# operationId: CreateShipment
# --extra shape: {accounts_receivable_customer_account?: any, alcohol?: record, ancillary_endorsement?: "FORWARDING_SERVICE_REQUESTED"|"RETURN_SERVICE_REQUESTED", appropriation_number?: any, authority_to_leave?: bool, bill_of_lading_number?: any, billing?: record, bypass_address_validation?: bool, carbon_neutral?: bool, carrier_hub_id?: string, carrier_hub_travel_time?: int, COD?: record, cod_number?: any, container_type?: string, critical_pull_time?: string, customer_branch?: string, customer_reference?: record, dangerous_goods?: record, dangerous_goods_code?: "01"|"02"|"03"|"04"|"05"|"06"|"07"|"08"|"09", dealer_order_number?: any, delivery_instructions?: string, dept_number?: record, dry_ice?: record, fda_product_code?: any, fulfillment_center?: string, insurance?: record, invoice_number?: record, is_return?: bool, lasership_attrs?: list, lasership_declared_value?: string, manifest_number?: any, model_number?: any, part_number?: any, po_number?: record, preferred_delivery_timeframe?: "10001200"|"12001400"|"14001600"|"16001800"|"18002000"|"19002100", premium?: bool, production_code?: any, purchase_request_number?: any, qr_code_requested?: bool, reference_1?: string, reference_2?: string, request_retail_rates?: bool, return_service_type?: string, rma_number?: record, saturday_delivery?: bool, salesperson_number?: any, serial_number?: any, signature_confirmation?: "STANDARD"|"ADULT"|"CERTIFIED"|"INDIRECT"|"CARRIER_CONFIRMATION", store_number?: any, transaction_reference_number?: any, usmca_eligible?: bool}
export def "shipments CreateShipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --extra: record # An object holding optional extra services to be requested. — shape: {accounts_receivable_customer_account?: any, alcohol?: record, ancillary_endorsement?: "FORWARDING_SERVICE_REQUESTED"|"RETURN_SERVICE_REQUESTED", appropriation_number?: any, authority_to_leave?: bool, bill_of_lading_number?: any, billing?: record, bypass_address_validation?: bool, carbon_neutral?: bool, carrier_hub_id?: string, carrier_hub_travel_time?: int, COD?: record, cod_number?: any, container_type?: string, critical_pull_time?: string, customer_branch?: string, customer_reference?: record, dangerous_goods?: record, dangerous_goods_code?: "01"|"02"|"03"|"04"|"05"|"06"|"07"|"08"|"09", dealer_order_number?: any, delivery_instructions?: string, dept_number?: record, dry_ice?: record, fda_product_code?: any, fulfillment_center?: string, insurance?: record, invoice_number?: record, is_return?: bool, lasership_attrs?: list, lasership_declared_value?: string, manifest_number?: any, model_number?: any, part_number?: any, po_number?: record, preferred_delivery_timeframe?: "10001200"|"12001400"|"14001600"|"16001800"|"18002000"|"19002100", premium?: bool, production_code?: any, purchase_request_number?: any, qr_code_requested?: bool, reference_1?: string, reference_2?: string, request_retail_rates?: bool, return_service_type?: string, rma_number?: record, saturday_delivery?: bool, salesperson_number?: any, serial_number?: any, signature_confirmation?: "STANDARD"|"ADULT"|"CERTIFIED"|"INDIRECT"|"CARRIER_CONFIRMATION", store_number?: any, transaction_reference_number?: any, usmca_eligible?: bool}
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you want to attach to the object. (e.g. Customer ID 123456)
  --shipment-date: string # Date the shipment will be tendered to the carrier. Must be in the format `2014-01-18T00:35:03.463Z`.  Defaults to current date and time if no value is provided. Please note that some carriers require this value to be in the future, on a working day, or similar. (e.g. 2021-03-22T12:00:00Z)
  address_from: any
  --address-return: any
  address_to: any
  --customs-declaration: any
  --async: string@bool-completer
  --carrier-accounts: list # List of <a href="/shippoapi/public-api/carrier-accounts">Carrier Accounts</a> `object_id`s used to filter  the returned rates.  If set, only rates from these carriers will be returned. (e.g. [065a4a8c10d24a34ab932163a1b87f52, 73f706f4bdb94b54a337563840ce52b0])
  parcels: list # List of parcels to be shipped.  **Carrier-Specific Constraints:** | Carrier | Constraints | |:---|:---| | FedEx | Max 30 items |
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipments")
  let body = {extra: $extra, metadata: $metadata, shipment_date: $shipment_date, address_from: $address_from, address_return: $address_return, address_to: $address_to, customs_declaration: $customs_declaration, async: $async, carrier_accounts: $carrier_accounts, parcels: $parcels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a shipment
#
# GET /shipments/{ShipmentId}
# operationId: GetShipment
export def "shipments GetShipment" [
  ShipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($ShipmentId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve shipment rates
#
# GET /shipments/{ShipmentId}/rates
# operationId: ListShipmentRates
export def "shipments-rates ListShipmentRates" [
  ShipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($ShipmentId)/rates" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve shipment rates in currency
#
# GET /shipments/{ShipmentId}/rates/{CurrencyCode}
# operationId: ListShipmentRatesByCurrencyCode
export def "shipments-rates ListShipmentRatesByCurrencyCode" [
  ShipmentId: string
  CurrencyCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($ShipmentId)/rates/($CurrencyCode)" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a tracking webhook
#
# POST /tracks
# operationId: CreateTrack
export def "tracks CreateTrack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  carrier: string # Name of the carrier of the shipment to track. (e.g. usps)
  --metadata: string # A string of up to 100 characters that can be filled with any additional information you want to attach to the object. (e.g. Order 000123)
  tracking_number: string # Tracking number to track. (e.g. "9205590164917312751089")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracks")
  let body = {carrier: $carrier, metadata: $metadata, tracking_number: $tracking_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a tracking status
#
# GET /tracks/{Carrier}/{TrackingNumber}
# operationId: GetTrack
export def "tracks GetTrack" [
  TrackingNumber: string
  Carrier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracks/($Carrier)/($TrackingNumber)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all shipping labels
#
# GET /transactions
# operationId: ListTransactions
export def "transactions ListTransactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rate: string # Filter by rate ID
  --object-status: string # Filter by object status
  --tracking-status: string # Filter by tracking status
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rate" $rate "scalar") (serialize-qp "object_status" $object_status "scalar") (serialize-qp "tracking_status" $tracking_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a shipping label
#
# POST /transactions
# operationId: CreateTransaction
export def "transactions CreateTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --async: string@bool-completer # default: true, e.g. false
  --label-file-type: string@label-file-type-completer # Print format of the <a href="https://docs.goshippo.com/docs/shipments/shippinglabelsizes/">label</a>. If empty, will use the default format set from  <a href="https://apps.goshippo.com/settings/labels">the Shippo dashboard.</a> (e.g. PDF_4x6)
  --metadata: string # e.g. Order ID #12345
  --rate: string # e.g. ec9f0d3adc9441449c85d315f0997fd5
  --order: string # e.g. adcfdddf8ec64b84ad22772bce3ea37a
  --carrier-account: string # e.g. b741b99f95e841639b54272834bc478c
  --servicelevel-token: string # e.g. usps_priority
  --shipment: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions")
  let body = {async: $async, label_file_type: $label_file_type, metadata: $metadata, rate: $rate, order: $order, carrier_account: $carrier_account, servicelevel_token: $servicelevel_token, shipment: $shipment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a shipping label
#
# GET /transactions/{TransactionId}
# operationId: GetTransaction
export def "transactions GetTransaction" [
  TransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($TransactionId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all user parcel templates
#
# GET /user-parcel-templates
# operationId: ListUserParcelTemplates
export def "user-parcel-templates ListUserParcelTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-parcel-templates")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user parcel template
#
# POST /user-parcel-templates
# operationId: CreateUserParcelTemplate
export def "user-parcel-templates CreateUserParcelTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  --template: string # The object representing the carrier parcel template
  --weight: string # The weight of the package, in units specified by the weight_unit attribute. (e.g. 12)
  --weight-unit: string@weight-unit-completer # The unit used for weight. (e.g. lb)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-parcel-templates")
  let body = {template: $template, weight: $weight, weight_unit: $weight_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user parcel template
#
# DELETE /user-parcel-templates/{UserParcelTemplateObjectId}
# operationId: DeleteUserParcelTemplate
export def "user-parcel-templates DeleteUserParcelTemplate" [
  UserParcelTemplateObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-parcel-templates/($UserParcelTemplateObjectId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a user parcel template
#
# GET /user-parcel-templates/{UserParcelTemplateObjectId}
# operationId: GetUserParcelTemplate
export def "user-parcel-templates GetUserParcelTemplate" [
  UserParcelTemplateObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-parcel-templates/($UserParcelTemplateObjectId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing user parcel template
#
# PUT /user-parcel-templates/{UserParcelTemplateObjectId}
# operationId: UpdateUserParcelTemplate
export def "user-parcel-templates UpdateUserParcelTemplate" [
  UserParcelTemplateObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  distance_unit: string@distance-unit-completer # The measure unit used for length, width and height. (e.g. in)
  height: string # The height of the package, in units specified by the `distance_unit` attribute. Required, but if using a preset carrier template then this field must be empty. (e.g. 6)
  length: string # The length of the package, in units specified by the `distance_unit` attribute. Required, but if using a preset carrier template then this field must be empty. (e.g. 10)
  name: string # The name of the User Parcel Template (e.g. My Custom Template)
  --weight: string # The weight of the package, in units specified by the weight_unit attribute. (e.g. 12)
  --weight-unit: string@weight-unit-completer # The unit used for weight. (e.g. lb)
  width: string # The width of the package, in units specified by the `distance_unit` attribute. Required, but if using a preset carrier template then this field must be empty. (e.g. 8)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-parcel-templates/($UserParcelTemplateObjectId)")
  let body = {distance_unit: $distance_unit, height: $height, length: $length, name: $name, weight: $weight, weight_unit: $weight_unit, width: $width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all Shippo Accounts
#
# GET /shippo-accounts
# operationId: ListShippoAccounts
export def "shippo-accounts ListShippoAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number you want to select (format: int64, default: 1)
  --results: int # The number of results to return per page (max 100) (format: int64, default: 25)
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "results" $results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shippo-accounts" $qp)
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Shippo Account
#
# POST /shippo-accounts
# operationId: CreateShippoAccount
export def "shippo-accounts CreateShippoAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  email: string # e.g. hippo@shippo.com
  first_name: string # e.g. Shippo
  last_name: string # e.g. Meister
  company_name: string # e.g. Acme
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shippo-accounts")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, company_name: $company_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Shippo Account
#
# GET /shippo-accounts/{ShippoAccountId}
# operationId: GetShippoAccount
export def "shippo-accounts GetShippoAccount" [
  ShippoAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shippo-accounts/($ShippoAccountId)")
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Shippo Account
#
# PUT /shippo-accounts/{ShippoAccountId}
# operationId: UpdateShippoAccount
export def "shippo-accounts UpdateShippoAccount" [
  ShippoAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SHIPPO-API-VERSION: string # Optional string used to pick a non-default API version to use. See our <a href="https://docs.goshippo.com/docs/api_concepts/apiversioning/">API version</a> guide. (e.g. 2018-02-08)
  email: string # e.g. hippo@shippo.com
  first_name: string # e.g. Shippo
  last_name: string # e.g. Meister
  company_name: string # e.g. Acme
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shippo-accounts/($ShippoAccountId)")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, company_name: $company_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"SHIPPO-API-VERSION": $SHIPPO_API_VERSION} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new webhook
#
# POST /webhooks
# operationId: createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: string@event-completer # Type of event that triggered the webhook.
  --body-url: string # URL webhook events are sent to. (e.g. https://example.com/shippo-webhook)
  --active: string@bool-completer # Determines whether the webhook is active or not. (e.g. true)
  --is-test: string@bool-completer # Determines whether the webhook is a test webhook or not. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {event: $event, url: $body_url, active: $active, is_test: $is_test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all webhooks
#
# GET /webhooks
# operationId: listWebhooks
export def "webhooks listWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific webhook
#
# GET /webhooks/{webhookId}
# operationId: getWebhook
export def "webhooks get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing webhook
#
# PUT /webhooks/{webhookId}
# operationId: updateWebhook
export def "webhooks updateWebhook" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: string@event-completer # Type of event that triggered the webhook.
  --body-url: string # URL webhook events are sent to. (e.g. https://example.com/shippo-webhook)
  --active: string@bool-completer # Determines whether the webhook is active or not. (e.g. true)
  --is-test: string@bool-completer # Determines whether the webhook is a test webhook or not. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {event: $event, url: $body_url, active: $active, is_test: $is_test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific webhook
#
# DELETE /webhooks/{webhookId}
# operationId: deleteWebhook
export def "webhooks delete" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
