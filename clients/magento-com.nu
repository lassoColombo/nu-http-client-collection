# Auto-generated client for Magento B2B v2.2.10
# Source: https://api.apis.guru/v2/specs/magento.com/2.2.10/openapi.json
# Auth: --token flag or $env.MAGENTO_B2B_TOKEN

const BASE_URL = "https://example.com/rest/default"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MAGENTO_B2B_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://example.com/rest/default"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1-addresses delete-customer-address-repository-by-delete" } } | get name | first)
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

# addresses/{addressId}
#
# DELETE /V1/addresses/{addressId}
# operationId: customerAddressRepositoryV1DeleteByIdDelete
export def "v1-addresses delete-customer-address-repository-by-delete" [
  address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({address_id: (encode-path-segment $address_id)} | format pattern "/V1/addresses/{address_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# amazon-billing-address/{amazonOrderReferenceId}
#
# PUT /V1/amazon-billing-address/{amazonOrderReferenceId}
# operationId: amazonPaymentAddressManagementV1GetBillingAddressPut
export def "v1-amazon-billing-address get-payment-management-update" [
  amazon_order_reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_consent_token: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({amazon_order_reference_id: (encode-path-segment $amazon_order_reference_id)} | format pattern "/V1/amazon-billing-address/{amazon_order_reference_id}"))
  let req_body = {"addressConsentToken": $address_consent_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# amazon-shipping-address/{amazonOrderReferenceId}
#
# PUT /V1/amazon-shipping-address/{amazonOrderReferenceId}
# operationId: amazonPaymentAddressManagementV1GetShippingAddressPut
export def "v1-amazon-shipping-address get-payment-management-update" [
  amazon_order_reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_consent_token: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({amazon_order_reference_id: (encode-path-segment $amazon_order_reference_id)} | format pattern "/V1/amazon-shipping-address/{amazon_order_reference_id}"))
  let req_body = {"addressConsentToken": $address_consent_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# amazon/order-ref
#
# DELETE /V1/amazon/order-ref
# operationId: amazonPaymentOrderInformationManagementV1RemoveOrderReferenceDelete
export def "v1-amazon-order-ref delete-payment-information-management-reference-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/amazon/order-ref")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# analytics/link
#
# GET /V1/analytics/link
# operationId: analyticsLinkProviderV1GetGet
export def "v1-analytics-link get-provider-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<initialization_vector: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/analytics/link")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customer
#
# GET /V1/attributeMetadata/customer
# operationId: customerCustomerMetadataV1GetAllAttributesMetadataGet
export def "v1-attribute-metadata-customer get-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/attributeMetadata/customer")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/attribute/{attributeCode}
#
# GET /V1/attributeMetadata/customer/attribute/{attributeCode}
# operationId: customerCustomerMetadataV1GetAttributeMetadataGet
export def "v1-attribute-metadata-customer-attribute get-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/attributeMetadata/customer/attribute/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/custom
#
# GET /V1/attributeMetadata/customer/custom
# operationId: customerCustomerMetadataV1GetCustomAttributesMetadataGet
export def "v1-attribute-metadata-customer-custom get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-interface-name: string
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataInterfaceName" $data_interface_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/attributeMetadata/customer/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/form/{formCode}
#
# GET /V1/attributeMetadata/customer/form/{formCode}
# operationId: customerCustomerMetadataV1GetAttributesGet
export def "v1-attribute-metadata-customer-form get-get" [
  form_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({form_code: (encode-path-segment $form_code)} | format pattern "/V1/attributeMetadata/customer/form/{form_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress
#
# GET /V1/attributeMetadata/customerAddress
# operationId: customerAddressMetadataV1GetAllAttributesMetadataGet
export def "v1-attribute-metadata-customer-address get-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/attributeMetadata/customerAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/attribute/{attributeCode}
#
# GET /V1/attributeMetadata/customerAddress/attribute/{attributeCode}
# operationId: customerAddressMetadataV1GetAttributeMetadataGet
export def "v1-attribute-metadata-customer-address-attribute get-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/attributeMetadata/customerAddress/attribute/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/custom
#
# GET /V1/attributeMetadata/customerAddress/custom
# operationId: customerAddressMetadataV1GetCustomAttributesMetadataGet
export def "v1-attribute-metadata-customer-address-custom get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-interface-name: string
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataInterfaceName" $data_interface_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/attributeMetadata/customerAddress/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/form/{formCode}
#
# GET /V1/attributeMetadata/customerAddress/form/{formCode}
# operationId: customerAddressMetadataV1GetAttributesGet
export def "v1-attribute-metadata-customer-address-form get-get" [
  form_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({form_code: (encode-path-segment $form_code)} | format pattern "/V1/attributeMetadata/customerAddress/form/{form_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/detailed-status
#
# GET /V1/bulk/{bulkUuid}/detailed-status
# operationId: asynchronousOperationsBulkStatusV1GetBulkDetailedStatusGet
export def "v1-bulk-detailed-status get-asynchronous-operations-get" [
  bulk_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<bulk_id: string, description: string, extension_attributes: record, operation_count: int, operations_list: table<bulk_uuid: string, error_code: int, extension_attributes: record, id: int, result_message: string, result_serialized_data: string, serialized_data: string, status: int, topic_name: string>, start_time: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bulk_uuid: (encode-path-segment $bulk_uuid)} | format pattern "/V1/bulk/{bulk_uuid}/detailed-status"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/operation-status/{status}
#
# GET /V1/bulk/{bulkUuid}/operation-status/{status}
# operationId: asynchronousOperationsBulkStatusV1GetOperationsCountByBulkIdAndStatusGet
export def "v1-bulk-operation-status get-asynchronous-count-by-and-get" [
  bulk_uuid: string
  status: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bulk_uuid: (encode-path-segment $bulk_uuid), status: (encode-path-segment $status)} | format pattern "/V1/bulk/{bulk_uuid}/operation-status/{status}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/status
#
# GET /V1/bulk/{bulkUuid}/status
# operationId: asynchronousOperationsBulkStatusV1GetBulkShortStatusGet
export def "v1-bulk-status get-asynchronous-operations-short-get" [
  bulk_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<bulk_id: string, description: string, extension_attributes: record, operation_count: int, operations_list: table<error_code: int, id: int, result_message: string, status: int>, start_time: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bulk_uuid: (encode-path-segment $bulk_uuid)} | format pattern "/V1/bulk/{bulk_uuid}/status"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/options/add
#
# POST /V1/bundle-products/options/add
# operationId: bundleProductOptionManagementV1SavePost
# --option shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
export def "v1-bundle-products-options-add create-management-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/bundle-products/options/add")
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# bundle-products/options/types
#
# GET /V1/bundle-products/options/types
# operationId: bundleProductOptionTypeListV1GetItemsGet
export def "v1-bundle-products-options-types list-get-items-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/bundle-products/options/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/options/{optionId}
#
# PUT /V1/bundle-products/options/{optionId}
# operationId: bundleProductOptionManagementV1SavePut
# --option shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
export def "v1-bundle-products-options update-management-save" [
  option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({option_id: (encode-path-segment $option_id)} | format pattern "/V1/bundle-products/options/{option_id}"))
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# bundle-products/{productSku}/children
#
# GET /V1/bundle-products/{productSku}/children
# operationId: bundleProductLinkManagementV1GetChildrenGet
export def "v1-bundle-products-children get-link-management-get" [
  product_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --option-id: int
]: nothing -> table<can_change_quantity: int, extension_attributes: record, id: string, is_default: bool, option_id: int, position: int, price: float, price_type: int, qty: float, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "optionId" $option_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_sku: (encode-path-segment $product_sku)} | format pattern "/V1/bundle-products/{product_sku}/children") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/links/{id}
#
# PUT /V1/bundle-products/{sku}/links/{id}
# operationId: bundleProductLinkManagementV1SaveChildPut
# --linkedProduct shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
export def "v1-bundle-products-links update-management-save-child" [
  sku: string
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
  linked_product: record # Interface LinkInterface — shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/bundle-products/{sku}/links/{id}"))
  let req_body = {"linkedProduct": $linked_product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# bundle-products/{sku}/links/{optionId}
#
# POST /V1/bundle-products/{sku}/links/{optionId}
# operationId: bundleProductLinkManagementV1AddChildByProductSkuPost
# --linkedProduct shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
export def "v1-bundle-products-links create-management-child-by-create" [
  sku: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  linked_product: record # Interface LinkInterface — shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id)} | format pattern "/V1/bundle-products/{sku}/links/{option_id}"))
  let req_body = {"linkedProduct": $linked_product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# bundle-products/{sku}/options/all
#
# GET /V1/bundle-products/{sku}/options/all
# operationId: bundleProductOptionRepositoryV1GetListGet
export def "v1-bundle-products-options-all get-repository-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, option_id: int, position: int, product_links: list<record>, required: bool, sku: string, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/bundle-products/{sku}/options/all"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}
#
# DELETE /V1/bundle-products/{sku}/options/{optionId}
# operationId: bundleProductOptionRepositoryV1DeleteByIdDelete
export def "v1-bundle-products-options delete-repository-by-delete" [
  sku: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id)} | format pattern "/V1/bundle-products/{sku}/options/{option_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}
#
# GET /V1/bundle-products/{sku}/options/{optionId}
# operationId: bundleProductOptionRepositoryV1GetGet
export def "v1-bundle-products-options get-repository-get" [
  sku: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, option_id: int, position: int, product_links: table<can_change_quantity: int, extension_attributes: record, id: string, is_default: bool, option_id: int, position: int, price: float, price_type: int, qty: float, sku: string>, required: bool, sku: string, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id)} | format pattern "/V1/bundle-products/{sku}/options/{option_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}/children/{childSku}
#
# DELETE /V1/bundle-products/{sku}/options/{optionId}/children/{childSku}
# operationId: bundleProductLinkManagementV1RemoveChildDelete
export def "v1-bundle-products-options-children delete-link-management-child-delete" [
  sku: string
  option_id: int
  child_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id), child_sku: (encode-path-segment $child_sku)} | format pattern "/V1/bundle-products/{sku}/options/{option_id}/children/{child_sku}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/
#
# POST /V1/carts/
# operationId: quoteCartManagementV1CreateEmptyCartPost
export def "v1-carts create-quote-management-empty-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/guest-carts/{cartId}/checkGiftCard/{giftCardCode}
#
# GET /V1/carts/guest-carts/{cartId}/checkGiftCard/{giftCardCode}
# operationId: giftCardAccountGuestGiftCardAccountManagementV1CheckGiftCardGet
export def "v1-carts-guest-carts-check-gift-card get-account-account-management" [
  cart_id: string
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/carts/guest-carts/{cart_id}/checkGiftCard/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/guest-carts/{cartId}/giftCards
#
# POST /V1/carts/guest-carts/{cartId}/giftCards
# operationId: giftCardAccountGuestGiftCardAccountManagementV1AddGiftCardPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-guest-carts-gift-cards create-account-account-management-create" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_card_account_data: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/guest-carts/{cart_id}/giftCards"))
  let req_body = {"giftCardAccountData": $gift_card_account_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/guest-carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/carts/guest-carts/{cartId}/giftCards/{giftCardCode}
# operationId: giftCardAccountGuestGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-carts-guest-carts-gift-cards delete-account-account-management-by-quote-delete" [
  cart_id: string
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/carts/guest-carts/{cart_id}/giftCards/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/licence
#
# GET /V1/carts/licence
# operationId: checkoutAgreementsCheckoutAgreementsRepositoryV1GetListGet
export def "v1-carts-licence get-checkout-agreements-checkout-agreements-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<agreement_id: int, checkbox_text: string, content: string, content_height: string, extension_attributes: record, is_active: bool, is_html: bool, mode: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/licence")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine
#
# GET /V1/carts/mine
# operationId: quoteCartManagementV1GetCartForCustomerGet
export def "v1-carts-mine get-quote-management-for-customer-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine
#
# POST /V1/carts/mine
# operationId: quoteCartManagementV1CreateEmptyCartForCustomerPost
export def "v1-carts-mine create-quote-management-empty-for-customer-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine
#
# PUT /V1/carts/mine
# operationId: quoteCartRepositoryV1SavePut
# --quote shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
export def "v1-carts-mine update-quote-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  quote: record # Interface CartInterface — shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let req_body = {"quote": $quote} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/balance/apply
#
# POST /V1/carts/mine/balance/apply
# operationId: customerBalanceBalanceManagementFromQuoteV1ApplyPost
export def "v1-carts-mine-balance-apply create-customer-management-from-quote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/balance/apply")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/balance/unapply
#
# POST /V1/carts/mine/balance/unapply
# operationId: customerBalanceBalanceManagementFromQuoteV1UnapplyPost
export def "v1-carts-mine-balance-unapply create-customer-management-from-quote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/balance/unapply")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/billing-address
#
# GET /V1/carts/mine/billing-address
# operationId: quoteBillingAddressManagementV1GetGet
export def "v1-carts-mine-billing-address get-quote-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/billing-address")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/billing-address
#
# POST /V1/carts/mine/billing-address
# operationId: quoteBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-mine-billing-address assign-quote-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  --use-for-shipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/billing-address")
  let req_body = {"address": $address, "useForShipping": $use_for_shipping} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/checkGiftCard/{giftCardCode}
#
# GET /V1/carts/mine/checkGiftCard/{giftCardCode}
# operationId: giftCardAccountGiftCardAccountManagementV1CheckGiftCardGet
export def "v1-carts-mine-check-gift-card get-account-account-management" [
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/carts/mine/checkGiftCard/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/checkout-fields
#
# POST /V1/carts/mine/checkout-fields
# operationId: temandoShippingQuoteCartCheckoutFieldManagementV1SaveCheckoutFieldsPost
# --serviceSelection item shape: {attribute_code: string, value: string}
export def "v1-carts-mine-checkout-fields create-temando-shipping-quote-management-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  service_selection: list # item shape: {attribute_code: string, value: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/checkout-fields")
  let req_body = {"serviceSelection": $service_selection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/collect-totals
#
# PUT /V1/carts/mine/collect-totals
# operationId: quoteCartTotalManagementV1CollectTotalsPut
# --additionalData shape: {custom_attributes?: list, extension_attributes?: record}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-collect-totals update-quote-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --additional-data: record # Additional data for totals collection. — shape: {custom_attributes?: list, extension_attributes?: record}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
  --shipping-carrier-code: string # The carrier code.
  --shipping-method-code: string # The shipping method code.
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collect-totals")
  let req_body = {"additionalData": $additional_data, "paymentMethod": $payment_method, "shippingCarrierCode": $shipping_carrier_code, "shippingMethodCode": $shipping_method_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/collection-point/search-request
#
# DELETE /V1/carts/mine/collection-point/search-request
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1DeleteSearchRequestDelete
export def "v1-carts-mine-collection-point-search-request delete-temando-shipping-management-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-request")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/collection-point/search-request
#
# PUT /V1/carts/mine/collection-point/search-request
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1SaveSearchRequestPut
export def "v1-carts-mine-collection-point-search-request update-temando-shipping-management-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  country_id: string
  postcode: string
]: any -> record<country_id: string, pending: bool, postcode: string, shipping_address_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-request")
  let req_body = {"countryId": $country_id, "postcode": $postcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/collection-point/search-result
#
# GET /V1/carts/mine/collection-point/search-result
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1GetCollectionPointsGet
export def "v1-carts-mine-collection-point-search-result get-temando-shipping-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<city: string, collection_point_id: string, country: string, entity_id: int, name: string, opening_hours: list<string>, postcode: string, recipient_address_id: int, region: string, selected: bool, shipping_experiences: list<string>, street: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-result")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/collection-point/select
#
# POST /V1/carts/mine/collection-point/select
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1SelectCollectionPointPost
export def "v1-carts-mine-collection-point-select create-temando-shipping-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/select")
  let req_body = {"entityId": $entity_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/coupons
#
# DELETE /V1/carts/mine/coupons
# operationId: quoteCouponManagementV1RemoveDelete
export def "v1-carts-mine-coupons delete-quote-management-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/coupons
#
# GET /V1/carts/mine/coupons
# operationId: quoteCouponManagementV1GetGet
export def "v1-carts-mine-coupons get-quote-management-get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/coupons/{couponCode}
#
# PUT /V1/carts/mine/coupons/{couponCode}
# operationId: quoteCouponManagementV1SetPut
export def "v1-carts-mine-coupons update-quote-management-update" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: (encode-path-segment $coupon_code)} | format pattern "/V1/carts/mine/coupons/{coupon_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/delivery-option
#
# POST /V1/carts/mine/delivery-option
# operationId: temandoShippingQuoteCartDeliveryOptionManagementV1SavePost
export def "v1-carts-mine-delivery-option create-temando-shipping-quote-management-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  selected_option: string
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/delivery-option")
  let req_body = {"selectedOption": $selected_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/estimate-shipping-methods
#
# POST /V1/carts/mine/estimate-shipping-methods
# operationId: quoteShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-mine-estimate-shipping-methods create-quote-shipment-estimation-by-extended-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/estimate-shipping-methods")
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/estimate-shipping-methods-by-address-id
#
# POST /V1/carts/mine/estimate-shipping-methods-by-address-id
# operationId: quoteShippingMethodManagementV1EstimateByAddressIdPost
export def "v1-carts-mine-estimate-shipping-methods-by-address-id create-quote-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_id: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/estimate-shipping-methods-by-address-id")
  let req_body = {"addressId": $address_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/gift-message
#
# GET /V1/carts/mine/gift-message
# operationId: giftMessageCartRepositoryV1GetGet
export def "v1-carts-mine-gift-message get-repository-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/gift-message")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/gift-message
#
# POST /V1/carts/mine/gift-message
# operationId: giftMessageCartRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-mine-gift-message create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/gift-message")
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/gift-message/{itemId}
#
# GET /V1/carts/mine/gift-message/{itemId}
# operationId: giftMessageItemRepositoryV1GetGet
export def "v1-carts-mine-gift-message get-item-repository-get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/mine/gift-message/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/gift-message/{itemId}
#
# POST /V1/carts/mine/gift-message/{itemId}
# operationId: giftMessageItemRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-mine-gift-message create-item-repository-save" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/mine/gift-message/{item_id}"))
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/giftCards
#
# POST /V1/carts/mine/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-mine-gift-cards create-account-account-management-save-by-quote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_card_account_data: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/giftCards")
  let req_body = {"giftCardAccountData": $gift_card_account_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/giftCards/{giftCardCode}
#
# DELETE /V1/carts/mine/giftCards/{giftCardCode}
# operationId: giftCardAccountGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-carts-mine-gift-cards delete-account-account-management-by-quote-delete" [
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/carts/mine/giftCards/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/items
#
# GET /V1/carts/mine/items
# operationId: quoteCartItemRepositoryV1GetListGet
export def "v1-carts-mine-items get-quote-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/items")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/items
#
# POST /V1/carts/mine/items
# operationId: quoteCartItemRepositoryV1SavePost
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-mine-items create-quote-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/items")
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/items/{itemId}
#
# DELETE /V1/carts/mine/items/{itemId}
# operationId: quoteCartItemRepositoryV1DeleteByIdDelete
export def "v1-carts-mine-items delete-quote-repository-by-delete" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/mine/items/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/items/{itemId}
#
# PUT /V1/carts/mine/items/{itemId}
# operationId: quoteCartItemRepositoryV1SavePut
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-mine-items update-quote-repository-save" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/mine/items/{item_id}"))
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/order
#
# PUT /V1/carts/mine/order
# operationId: quoteCartManagementV1PlaceOrderPut
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-order update-quote-management-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --payment-method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/order")
  let req_body = {"paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/payment-information
#
# GET /V1/carts/mine/payment-information
# operationId: checkoutPaymentInformationManagementV1GetPaymentInformationGet
export def "v1-carts-mine-payment-information get-checkout-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-information")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/payment-information
#
# POST /V1/carts/mine/payment-information
# operationId: checkoutPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-payment-information create-checkout-management-save-and-place-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-information")
  let req_body = {"billingAddress": $billing_address, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/payment-methods
#
# GET /V1/carts/mine/payment-methods
# operationId: quotePaymentMethodManagementV1GetListGet
export def "v1-carts-mine-payment-methods get-quote-management-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/selected-payment-method
#
# GET /V1/carts/mine/selected-payment-method
# operationId: quotePaymentMethodManagementV1GetGet
export def "v1-carts-mine-selected-payment-method get-quote-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/selected-payment-method")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/selected-payment-method
#
# PUT /V1/carts/mine/selected-payment-method
# operationId: quotePaymentMethodManagementV1SetPut
# --method shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-selected-payment-method update-quote-management-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/selected-payment-method")
  let req_body = {"method": $method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/set-payment-information
#
# POST /V1/carts/mine/set-payment-information
# operationId: checkoutPaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-set-payment-information create-checkout-management-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/set-payment-information")
  let req_body = {"billingAddress": $billing_address, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/shipping-information
#
# POST /V1/carts/mine/shipping-information
# operationId: checkoutShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-carts-mine-shipping-information create-checkout-management-save-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/shipping-information")
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/mine/shipping-methods
#
# GET /V1/carts/mine/shipping-methods
# operationId: quoteShippingMethodManagementV1GetListGet
export def "v1-carts-mine-shipping-methods get-quote-management-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/shipping-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/totals
#
# GET /V1/carts/mine/totals
# operationId: quoteCartTotalRepositoryV1GetGet
export def "v1-carts-mine-totals get-quote-repository-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/totals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/mine/totals-information
#
# POST /V1/carts/mine/totals-information
# operationId: checkoutTotalsInformationManagementV1CalculatePost
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-carts-mine-totals-information create-checkout-management-calculate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/totals-information")
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/search
#
# GET /V1/carts/search
# operationId: quoteCartRepositoryV1GetListGet
export def "v1-carts-search get-quote-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<billing_address: record, converted_at: string, created_at: string, currency: record, customer: record, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record, id: int, is_active: bool, is_virtual: bool, items: list, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/carts/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}
#
# GET /V1/carts/{cartId}
# operationId: quoteCartRepositoryV1GetGet
export def "v1-carts get-quote-repository-get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}
#
# PUT /V1/carts/{cartId}
# operationId: quoteCartManagementV1AssignCustomerPut
export def "v1-carts assign-quote-management-customer-update" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer_id: int # The customer ID.
  store_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}"))
  let req_body = {"customerId": $customer_id, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/billing-address
#
# GET /V1/carts/{cartId}/billing-address
export def "v1-carts-billing-address get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/billing-address"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/billing-address
#
# POST /V1/carts/{cartId}/billing-address
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-billing-address create" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  --use-for-shipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/billing-address"))
  let req_body = {"address": $address, "useForShipping": $use_for_shipping} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/coupons
#
# DELETE /V1/carts/{cartId}/coupons
export def "v1-carts-coupons delete" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/coupons"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/coupons
#
# GET /V1/carts/{cartId}/coupons
export def "v1-carts-coupons get" [
  cart_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/coupons"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/carts/{cartId}/coupons/{couponCode}
export def "v1-carts-coupons update" [
  cart_id: int
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), coupon_code: (encode-path-segment $coupon_code)} | format pattern "/V1/carts/{cart_id}/coupons/{coupon_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/estimate-shipping-methods
#
# POST /V1/carts/{cartId}/estimate-shipping-methods
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-estimate-shipping-methods create" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/estimate-shipping-methods"))
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/estimate-shipping-methods-by-address-id
#
# POST /V1/carts/{cartId}/estimate-shipping-methods-by-address-id
export def "v1-carts-estimate-shipping-methods-by-address-id create" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_id: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/estimate-shipping-methods-by-address-id"))
  let req_body = {"addressId": $address_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/gift-message
#
# GET /V1/carts/{cartId}/gift-message
export def "v1-carts-gift-message list" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/gift-message"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/gift-message
#
# POST /V1/carts/{cartId}/gift-message
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-gift-message create-by-cartId" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/gift-message"))
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/gift-message/{itemId}
#
# GET /V1/carts/{cartId}/gift-message/{itemId}
export def "v1-carts-gift-message get" [
  cart_id: int
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/{cart_id}/gift-message/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/gift-message/{itemId}
#
# POST /V1/carts/{cartId}/gift-message/{itemId}
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-gift-message create-by-cartId-itemId" [
  cart_id: int
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/{cart_id}/gift-message/{item_id}"))
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/giftCards
#
# PUT /V1/carts/{cartId}/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPut
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-gift-cards update-account-account-management-save-by-quote" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_card_account_data: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/giftCards"))
  let req_body = {"giftCardAccountData": $gift_card_account_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/carts/{cartId}/giftCards/{giftCardCode}
export def "v1-carts-gift-cards delete" [
  cart_id: int
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/carts/{cart_id}/giftCards/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/items
#
# GET /V1/carts/{cartId}/items
export def "v1-carts-items get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/items"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/items/{itemId}
#
# DELETE /V1/carts/{cartId}/items/{itemId}
export def "v1-carts-items delete" [
  cart_id: int
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/{cart_id}/items/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/items/{itemId}
#
# PUT /V1/carts/{cartId}/items/{itemId}
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-items update" [
  cart_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/carts/{cart_id}/items/{item_id}"))
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/order
#
# PUT /V1/carts/{cartId}/order
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-order update" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --payment-method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/order"))
  let req_body = {"paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/payment-methods
#
# GET /V1/carts/{cartId}/payment-methods
export def "v1-carts-payment-methods get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/payment-methods"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/selected-payment-method
#
# GET /V1/carts/{cartId}/selected-payment-method
export def "v1-carts-selected-payment-method get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/selected-payment-method"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/selected-payment-method
#
# PUT /V1/carts/{cartId}/selected-payment-method
# --method shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-selected-payment-method update" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/selected-payment-method"))
  let req_body = {"method": $method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/shipping-information
#
# POST /V1/carts/{cartId}/shipping-information
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-carts-shipping-information create" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/shipping-information"))
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{cartId}/shipping-methods
#
# GET /V1/carts/{cartId}/shipping-methods
export def "v1-carts-shipping-methods get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/shipping-methods"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/totals
#
# GET /V1/carts/{cartId}/totals
export def "v1-carts-totals get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/totals"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{cartId}/totals-information
#
# POST /V1/carts/{cartId}/totals-information
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-carts-totals-information create" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/carts/{cart_id}/totals-information"))
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# carts/{quoteId}/giftCards
#
# GET /V1/carts/{quoteId}/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1GetListByQuoteIdGet
export def "v1-carts-gift-cards get-account-account-management-list-by-quote-get" [
  quote_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/V1/carts/{quote_id}/giftCards"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# carts/{quoteId}/items
#
# POST /V1/carts/{quoteId}/items
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-items create" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/V1/carts/{quote_id}/items"))
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# categories
#
# GET /V1/categories
# operationId: catalogCategoryManagementV1GetTreeGet
export def "v1-categories get-catalog-category-management-tree-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --root-category-id: int
  --depth: int
]: nothing -> record<children_data: list<any>, id: int, is_active: bool, level: int, name: string, parent_id: int, position: int, product_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rootCategoryId" $root_category_id "scalar") (serialize-qp "depth" $depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories
#
# POST /V1/categories
# operationId: catalogCategoryRepositoryV1SavePost
# --category shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-categories create-catalog-category-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  category: record # shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/categories")
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# categories/attributes
#
# GET /V1/categories/attributes
# operationId: catalogCategoryAttributeRepositoryV1GetListGet
export def "v1-categories-attributes get-catalog-category-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<apply_to: list, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/attributes/{attributeCode}
#
# GET /V1/categories/attributes/{attributeCode}
# operationId: catalogCategoryAttributeRepositoryV1GetGet
export def "v1-categories-attributes get-catalog-category-repository-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/categories/attributes/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/attributes/{attributeCode}/options
#
# GET /V1/categories/attributes/{attributeCode}/options
# operationId: catalogCategoryAttributeOptionManagementV1GetItemsGet
export def "v1-categories-attributes-options get-catalog-category-management-items-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<is_default: bool, label: string, sort_order: int, store_labels: list<record>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/categories/attributes/{attribute_code}/options"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/list
#
# GET /V1/categories/list
# operationId: catalogCategoryListV1GetListGet
export def "v1-categories-list get-catalog-category-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<available_sort_by: list, children: string, created_at: string, custom_attributes: list, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/{categoryId}
#
# DELETE /V1/categories/{categoryId}
# operationId: catalogCategoryRepositoryV1DeleteByIdentifierDelete
export def "v1-categories delete-catalog-category-repository-by-identifier-delete" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/{categoryId}
#
# GET /V1/categories/{categoryId}
# operationId: catalogCategoryRepositoryV1GetGet
export def "v1-categories get-catalog-category-repository-get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --store-id: int
]: nothing -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/{categoryId}/move
#
# PUT /V1/categories/{categoryId}/move
# operationId: catalogCategoryManagementV1MovePut
export def "v1-categories-move update-catalog-category-management" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --after-id: int
  parent_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}/move"))
  let req_body = {"afterId": $after_id, "parentId": $parent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# categories/{categoryId}/products
#
# GET /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkManagementV1GetAssignedProductsGet
export def "v1-categories-products get-catalog-category-link-management-assigned-get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<category_id: string, extension_attributes: record, position: int, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}/products"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/{categoryId}/products
#
# POST /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkRepositoryV1SavePost
# --productLink shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
export def "v1-categories-products create-catalog-category-link-repository-save" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product_link: record # shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}/products"))
  let req_body = {"productLink": $product_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# categories/{categoryId}/products
#
# PUT /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkRepositoryV1SavePut
# --productLink shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
export def "v1-categories-products update-catalog-category-link-repository-save" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product_link: record # shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/V1/categories/{category_id}/products"))
  let req_body = {"productLink": $product_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# categories/{categoryId}/products/{sku}
#
# DELETE /V1/categories/{categoryId}/products/{sku}
# operationId: catalogCategoryLinkRepositoryV1DeleteByIdsDelete
export def "v1-categories-products delete-catalog-category-link-repository-by-delete" [
  category_id: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id), sku: (encode-path-segment $sku)} | format pattern "/V1/categories/{category_id}/products/{sku}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categories/{id}
#
# PUT /V1/categories/{id}
# operationId: catalogCategoryRepositoryV1SavePut
# --category shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-categories update-catalog-category-repository-save" [
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
  category: record # shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/categories/{id}"))
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# cmsBlock
#
# POST /V1/cmsBlock
# operationId: cmsBlockRepositoryV1SavePost
# --block shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
export def "v1-cms-block create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  block: record # CMS block interface. — shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/cmsBlock")
  let req_body = {"block": $block} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# cmsBlock/search
#
# GET /V1/cmsBlock/search
# operationId: cmsBlockRepositoryV1GetListGet
export def "v1-cms-block-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/cmsBlock/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# cmsBlock/{blockId}
#
# DELETE /V1/cmsBlock/{blockId}
# operationId: cmsBlockRepositoryV1DeleteByIdDelete
export def "v1-cms-block delete-repository-by-delete" [
  block_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({block_id: (encode-path-segment $block_id)} | format pattern "/V1/cmsBlock/{block_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# cmsBlock/{blockId}
#
# GET /V1/cmsBlock/{blockId}
# operationId: cmsBlockRepositoryV1GetByIdGet
export def "v1-cms-block get-repository-by-get" [
  block_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({block_id: (encode-path-segment $block_id)} | format pattern "/V1/cmsBlock/{block_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# cmsBlock/{id}
#
# PUT /V1/cmsBlock/{id}
# operationId: cmsBlockRepositoryV1SavePut
# --block shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
export def "v1-cms-block update-repository-save" [
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
  block: record # CMS block interface. — shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/cmsBlock/{id}"))
  let req_body = {"block": $block} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# cmsPage
#
# POST /V1/cmsPage
# operationId: cmsPageRepositoryV1SavePost
# --page shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
export def "v1-cms-page create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  page: record # CMS page interface. — shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/cmsPage")
  let req_body = {"page": $page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# cmsPage/search
#
# GET /V1/cmsPage/search
# operationId: cmsPageRepositoryV1GetListGet
export def "v1-cms-page-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/cmsPage/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# cmsPage/{id}
#
# PUT /V1/cmsPage/{id}
# operationId: cmsPageRepositoryV1SavePut
# --page shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
export def "v1-cms-page update-repository-save" [
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
  page: record # CMS page interface. — shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/cmsPage/{id}"))
  let req_body = {"page": $page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# cmsPage/{pageId}
#
# DELETE /V1/cmsPage/{pageId}
# operationId: cmsPageRepositoryV1DeleteByIdDelete
export def "v1-cms-page delete-repository-by-delete" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({page_id: (encode-path-segment $page_id)} | format pattern "/V1/cmsPage/{page_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# cmsPage/{pageId}
#
# GET /V1/cmsPage/{pageId}
# operationId: cmsPageRepositoryV1GetByIdGet
export def "v1-cms-page get-repository-by-get" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({page_id: (encode-path-segment $page_id)} | format pattern "/V1/cmsPage/{page_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/
#
# GET /V1/company/
# operationId: companyCompanyRepositoryV1GetListGet
export def "v1-company get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list, super_user_id: int, telephone: string, vat_tax_id: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/company/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/
#
# POST /V1/company/
# operationId: companyCompanyRepositoryV1SavePost
# --company shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-company create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  company: record # Interface for Company entity. — shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/")
  let req_body = {"company": $company} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# company/assignRoles
#
# PUT /V1/company/assignRoles
# operationId: companyAclV1AssignRolesPut
# --roles item shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-assign-roles update-acl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  roles: list # item shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
  user_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/assignRoles")
  let req_body = {"roles": $roles, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# company/role/
#
# GET /V1/company/role/
# operationId: companyRoleRepositoryV1GetListGet
export def "v1-company-role get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<company_id: int, extension_attributes: record, id: int, permissions: list, role_name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/company/role/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/role/
#
# POST /V1/company/role/
# operationId: companyRoleRepositoryV1SavePost
# --role shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-role create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  role: record # Role data transfer object interface. — shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
]: any -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/role/")
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# company/role/{id}
#
# PUT /V1/company/role/{id}
# operationId: companyRoleRepositoryV1SavePut
# --role shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-role update-repository-save" [
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
  role: record # Role data transfer object interface. — shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
]: any -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/company/role/{id}"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# company/role/{roleId}
#
# DELETE /V1/company/role/{roleId}
# operationId: companyRoleRepositoryV1DeleteDelete
export def "v1-company-role delete-repository-delete" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/V1/company/role/{role_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/role/{roleId}
#
# GET /V1/company/role/{roleId}
# operationId: companyRoleRepositoryV1GetGet
export def "v1-company-role get-repository-get" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/V1/company/role/{role_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/role/{roleId}/users
#
# GET /V1/company/role/{roleId}/users
# operationId: companyAclV1GetUsersByRoleIdGet
export def "v1-company-role-users get-acl-by-get" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/V1/company/role/{role_id}/users"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# DELETE /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1DeleteByIdDelete
export def "v1-company delete-repository-by-delete" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/V1/company/{company_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# GET /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1GetGet
export def "v1-company get-repository-get" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/V1/company/{company_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# PUT /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1SavePut
# --company shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-company update-repository-save" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  company: record # Interface for Company entity. — shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/V1/company/{company_id}"))
  let req_body = {"company": $company} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# companyCredits/
#
# GET /V1/companyCredits/
# operationId: companyCreditCreditLimitRepositoryV1GetListGet
export def "v1-company-credits get-limit-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<available_limit: float, balance: float, company_id: int, credit_limit: float, currency_code: string, exceed_limit: bool, id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/companyCredits/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# companyCredits/company/{companyId}
#
# GET /V1/companyCredits/company/{companyId}
# operationId: companyCreditCreditLimitManagementV1GetCreditByCompanyIdGet
export def "v1-company-credits-company get-limit-management-by-get" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/V1/companyCredits/company/{company_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# companyCredits/history
#
# GET /V1/companyCredits/history
# operationId: companyCreditCreditHistoryManagementV1GetListGet
export def "v1-company-credits-history get-management-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<amount: float, available_limit: float, balance: float, comment: string, company_credit_id: int, credit_limit: float, currency_credit: string, currency_operation: string, datetime: string, id: int, purchase_order: string, rate: float, rate_credit: float, type: int, user_id: int, user_type: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/companyCredits/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# companyCredits/history/{historyId}
#
# PUT /V1/companyCredits/history/{historyId}
# operationId: companyCreditCreditHistoryManagementV1UpdatePut
export def "v1-company-credits-history update-management-update" [
  history_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  --purchase-order: string # [optional]
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({history_id: (encode-path-segment $history_id)} | format pattern "/V1/companyCredits/history/{history_id}"))
  let req_body = {"comment": $comment, "purchaseOrder": $purchase_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# companyCredits/{creditId}
#
# GET /V1/companyCredits/{creditId}
# operationId: companyCreditCreditLimitRepositoryV1GetGet
export def "v1-company-credits get-limit-repository-get" [
  credit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reload: oneof<nothing, bool> # [optional]
]: nothing -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reload" $reload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_id: (encode-path-segment $credit_id)} | format pattern "/V1/companyCredits/{credit_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# companyCredits/{creditId}/decreaseBalance
#
# POST /V1/companyCredits/{creditId}/decreaseBalance
# operationId: companyCreditCreditBalanceManagementV1DecreasePost
# --options shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
export def "v1-company-credits-decrease-balance create-management" [
  credit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  currency: string
  operation_type: int
  --options: record # Credit balance data transfer object interface. — shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
  value: float
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_id: (encode-path-segment $credit_id)} | format pattern "/V1/companyCredits/{credit_id}/decreaseBalance"))
  let req_body = {"comment": $comment, "currency": $currency, "operationType": $operation_type, "options": $options, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# companyCredits/{creditId}/increaseBalance
#
# POST /V1/companyCredits/{creditId}/increaseBalance
# operationId: companyCreditCreditBalanceManagementV1IncreasePost
# --options shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
export def "v1-company-credits-increase-balance create-management" [
  credit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  currency: string
  operation_type: int
  --options: record # Credit balance data transfer object interface. — shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
  value: float
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_id: (encode-path-segment $credit_id)} | format pattern "/V1/companyCredits/{credit_id}/increaseBalance"))
  let req_body = {"comment": $comment, "currency": $currency, "operationType": $operation_type, "options": $options, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# companyCredits/{id}
#
# PUT /V1/companyCredits/{id}
# operationId: companyCreditCreditLimitRepositoryV1SavePut
# --creditLimit shape: {available_limit?: float, balance?: float, company_id?: int, credit_comment?: string, credit_limit?: float, currency_code?: string, exceed_limit: bool, extension_attributes?: record, id?: int}
export def "v1-company-credits update-limit-repository-save" [
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
  credit_limit: record # Credit Limit data transfer object interface. — shape: {available_limit?: float, balance?: float, company_id?: int, credit_comment?: string, credit_limit?: float, currency_code?: string, exceed_limit: bool, extension_attributes?: record, id?: int}
]: any -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/companyCredits/{id}"))
  let req_body = {"creditLimit": $credit_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# configurable-products/variation
#
# PUT /V1/configurable-products/variation
# operationId: configurableProductConfigurableProductManagementV1GenerateVariationPut
# --options item shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-configurable-products-variation generate-management-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  options: list # item shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> table<attribute_set_id: int, created_at: string, custom_attributes: list<record>, extension_attributes: record<bundle_product_options: list, category_links: list, configurable_product_links: list, configurable_product_options: list, downloadable_product_links: list, downloadable_product_samples: list, giftcard_amounts: list, stock_item: record, website_ids: list>, id: int, media_gallery_entries: list<record>, name: string, options: list<record>, price: float, product_links: list<record>, sku: string, status: int, tier_prices: list<record>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/configurable-products/variation")
  let req_body = {"options": $options, "product": $product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# configurable-products/{sku}/child
#
# POST /V1/configurable-products/{sku}/child
# operationId: configurableProductLinkManagementV1AddChildPost
export def "v1-configurable-products-child create-link-management-create" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  child_sku: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/configurable-products/{sku}/child"))
  let req_body = {"childSku": $child_sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# configurable-products/{sku}/children
#
# GET /V1/configurable-products/{sku}/children
# operationId: configurableProductLinkManagementV1GetChildrenGet
export def "v1-configurable-products-children get-link-management-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_set_id: int, created_at: string, custom_attributes: list<record>, extension_attributes: record<bundle_product_options: list, category_links: list, configurable_product_links: list, configurable_product_options: list, downloadable_product_links: list, downloadable_product_samples: list, giftcard_amounts: list, stock_item: record, website_ids: list>, id: int, media_gallery_entries: list<record>, name: string, options: list<record>, price: float, product_links: list<record>, sku: string, status: int, tier_prices: list<record>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/configurable-products/{sku}/children"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/children/{childSku}
#
# DELETE /V1/configurable-products/{sku}/children/{childSku}
# operationId: configurableProductLinkManagementV1RemoveChildDelete
export def "v1-configurable-products-children delete-link-management-child-delete" [
  sku: string
  child_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), child_sku: (encode-path-segment $child_sku)} | format pattern "/V1/configurable-products/{sku}/children/{child_sku}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options
#
# POST /V1/configurable-products/{sku}/options
# operationId: configurableProductOptionRepositoryV1SavePost
# --option shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
export def "v1-configurable-products-options create-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/configurable-products/{sku}/options"))
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# configurable-products/{sku}/options/all
#
# GET /V1/configurable-products/{sku}/options/all
# operationId: configurableProductOptionRepositoryV1GetListGet
export def "v1-configurable-products-options-all get-repository-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_id: string, extension_attributes: record, id: int, is_use_default: bool, label: string, position: int, product_id: int, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/configurable-products/{sku}/options/all"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# DELETE /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1DeleteByIdDelete
export def "v1-configurable-products-options delete-repository-by-delete" [
  sku: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/configurable-products/{sku}/options/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# GET /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1GetGet
export def "v1-configurable-products-options get-repository-get" [
  sku: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_id: string, extension_attributes: record, id: int, is_use_default: bool, label: string, position: int, product_id: int, values: table<extension_attributes: record, value_index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/configurable-products/{sku}/options/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# PUT /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1SavePut
# --option shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
export def "v1-configurable-products-options update-repository-save" [
  sku: string
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
  option: record # Interface OptionInterface — shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/configurable-products/{sku}/options/{id}"))
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# coupons
#
# POST /V1/coupons
# operationId: salesRuleCouponRepositoryV1SavePost
# --coupon shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
export def "v1-coupons create-sales-rule-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  coupon: record # Interface CouponInterface — shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
]: any -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons")
  let req_body = {"coupon": $coupon} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# coupons/deleteByCodes
#
# POST /V1/coupons/deleteByCodes
# operationId: salesRuleCouponManagementV1DeleteByCodesPost
export def "v1-coupons-delete-by-codes create-sales-rule-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  codes: list<string>
  --ignore-invalid-coupons: oneof<nothing, bool>
]: any -> record<failed_items: list<string>, missing_items: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/deleteByCodes")
  let req_body = {"codes": $codes, "ignoreInvalidCoupons": $ignore_invalid_coupons} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# coupons/deleteByIds
#
# POST /V1/coupons/deleteByIds
# operationId: salesRuleCouponManagementV1DeleteByIdsPost
export def "v1-coupons-delete-by-ids create-sales-rule-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  ids: list<int>
  --ignore-invalid-coupons: oneof<nothing, bool>
]: any -> record<failed_items: list<string>, missing_items: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/deleteByIds")
  let req_body = {"ids": $ids, "ignoreInvalidCoupons": $ignore_invalid_coupons} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# coupons/generate
#
# POST /V1/coupons/generate
# operationId: salesRuleCouponManagementV1GeneratePost
# --couponSpec shape: {delimiter?: string, delimiter_at_every?: int, extension_attributes?: record, format: string, length: int, prefix?: string, quantity: int, rule_id: int, suffix?: string}
export def "v1-coupons-generate create-sales-rule-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  coupon_spec: record # CouponGenerationSpecInterface — shape: {delimiter?: string, delimiter_at_every?: int, extension_attributes?: record, format: string, length: int, prefix?: string, quantity: int, rule_id: int, suffix?: string}
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/generate")
  let req_body = {"couponSpec": $coupon_spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# coupons/search
#
# GET /V1/coupons/search
# operationId: salesRuleCouponRepositoryV1GetListGet
export def "v1-coupons-search get-sales-rule-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/coupons/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# DELETE /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1DeleteByIdDelete
export def "v1-coupons delete-sales-rule-repository-by-delete" [
  coupon_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_id: (encode-path-segment $coupon_id)} | format pattern "/V1/coupons/{coupon_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# GET /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1GetByIdGet
export def "v1-coupons get-sales-rule-repository-by-get" [
  coupon_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_id: (encode-path-segment $coupon_id)} | format pattern "/V1/coupons/{coupon_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# PUT /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1SavePut
# --coupon shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
export def "v1-coupons update-sales-rule-repository-save" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  coupon: record # Interface CouponInterface — shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
]: any -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_id: (encode-path-segment $coupon_id)} | format pattern "/V1/coupons/{coupon_id}"))
  let req_body = {"coupon": $coupon} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# creditmemo
#
# POST /V1/creditmemo
# operationId: salesCreditmemoRepositoryV1SavePost
# --entity shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, ... (36 more fields)}
export def "v1-creditmemo create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Credit memo interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. — shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, ... (36 more fields)}
]: any -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/creditmemo")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# creditmemo/refund
#
# POST /V1/creditmemo/refund
# operationId: salesCreditmemoManagementV1RefundPost
# --creditmemo shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, ... (36 more fields)}
export def "v1-creditmemo-refund create-sales-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  creditmemo: record # Credit memo interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. — shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, ... (36 more fields)}
  --offline-requested: oneof<nothing, bool>
]: any -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/creditmemo/refund")
  let req_body = {"creditmemo": $creditmemo, "offlineRequested": $offline_requested} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# creditmemo/{id}
#
# GET /V1/creditmemo/{id}
# operationId: salesCreditmemoRepositoryV1GetGet
export def "v1-creditmemo get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/creditmemo/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creditmemo/{id}
#
# PUT /V1/creditmemo/{id}
# operationId: salesCreditmemoManagementV1CancelPut
export def "v1-creditmemo cancel-sales-management-update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/creditmemo/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creditmemo/{id}/comments
#
# GET /V1/creditmemo/{id}/comments
# operationId: salesCreditmemoManagementV1GetCommentsListGet
export def "v1-creditmemo-comments get-sales-management-list-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/creditmemo/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creditmemo/{id}/comments
#
# POST /V1/creditmemo/{id}/comments
# operationId: salesCreditmemoCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-creditmemo-comments create-sales-repository-save" [
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
  entity: record # Credit memo comment interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. A credit memo usually includes comments that detail why the credit memo amount was credited to the customer. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/creditmemo/{id}/comments"))
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# creditmemo/{id}/emails
#
# POST /V1/creditmemo/{id}/emails
# operationId: salesCreditmemoManagementV1NotifyPost
export def "v1-creditmemo-emails notify-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/creditmemo/{id}/emails"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# creditmemos
#
# GET /V1/creditmemos
# operationId: salesCreditmemoRepositoryV1GetListGet
export def "v1-creditmemos get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: list, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: list, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/creditmemos" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups
#
# POST /V1/customerGroups
# operationId: customerGroupRepositoryV1SavePost
# --group shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
export def "v1-customer-groups create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  group: record # Customer group interface. — shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
]: any -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customerGroups")
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customerGroups/default
#
# GET /V1/customerGroups/default
# operationId: customerGroupManagementV1GetDefaultGroupGet
export def "v1-customer-groups-default get-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --store-id: int
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customerGroups/default" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/default/{id}
#
# PUT /V1/customerGroups/default/{id}
# operationId: customerCustomerGroupConfigV1SetDefaultCustomerGroupPut
export def "v1-customer-groups-default update-config-update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/customerGroups/default/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/default/{storeId}
#
# GET /V1/customerGroups/default/{storeId}
export def "v1-customer-groups-default get" [
  store_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/V1/customerGroups/default/{store_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/search
#
# GET /V1/customerGroups/search
# operationId: customerGroupRepositoryV1GetListGet
export def "v1-customer-groups-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customerGroups/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# DELETE /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1DeleteByIdDelete
export def "v1-customer-groups delete-repository-by-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/customerGroups/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# GET /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1GetByIdGet
export def "v1-customer-groups get-repository-by-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/customerGroups/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# PUT /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1SavePut
# --group shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
export def "v1-customer-groups update-repository-save" [
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
  group: record # Customer group interface. — shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
]: any -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/customerGroups/{id}"))
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customerGroups/{id}/permissions
#
# GET /V1/customerGroups/{id}/permissions
# operationId: customerGroupManagementV1IsReadonlyGet
export def "v1-customer-groups-permissions get-management-is-readonly" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/customerGroups/{id}/permissions"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers
#
# POST /V1/customers
# operationId: customerAccountManagementV1CreateAccountPost
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers create-account-management-account-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --password: string
  --redirect-url: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers")
  let req_body = {"customer": $customer, "password": $password, "redirectUrl": $redirect_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/addresses/{addressId}
#
# GET /V1/customers/addresses/{addressId}
# operationId: customerAddressRepositoryV1GetByIdGet
export def "v1-customers-addresses get-address-repository-by-get" [
  address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({address_id: (encode-path-segment $address_id)} | format pattern "/V1/customers/addresses/{address_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/confirm
#
# POST /V1/customers/confirm
# operationId: customerAccountManagementV1ResendConfirmationPost
export def "v1-customers-confirm resend-account-management-confirmation-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string
  --redirect-url: string
  website_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/confirm")
  let req_body = {"email": $email, "redirectUrl": $redirect_url, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/isEmailAvailable
#
# POST /V1/customers/isEmailAvailable
# operationId: customerAccountManagementV1IsEmailAvailablePost
export def "v1-customers-is-email-available create-account-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer_email: string
  --website-id: int # If not set, will use the current websiteId
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/isEmailAvailable")
  let req_body = {"customerEmail": $customer_email, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/me
#
# GET /V1/customers/me
# operationId: customerCustomerRepositoryV1GetByIdGet
export def "v1-customers-me get-repository-by-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/me
#
# PUT /V1/customers/me
# operationId: customerCustomerRepositoryV1SavePut
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers-me update-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --password-hash: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me")
  let req_body = {"customer": $customer, "passwordHash": $password_hash} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/me/activate
#
# PUT /V1/customers/me/activate
# operationId: customerAccountManagementV1ActivateByIdPut
export def "v1-customers-me-activate update-account-management-by" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  confirmation_key: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/activate")
  let req_body = {"confirmationKey": $confirmation_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/me/billingAddress
#
# GET /V1/customers/me/billingAddress
# operationId: customerAccountManagementV1GetDefaultBillingAddressGet
export def "v1-customers-me-billing-address get-account-management-default-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/billingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/me/password
#
# PUT /V1/customers/me/password
# operationId: customerAccountManagementV1ChangePasswordByIdPut
export def "v1-customers-me-password update-account-management-change-by" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  current_password: string
  new_password: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/password")
  let req_body = {"currentPassword": $current_password, "newPassword": $new_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/me/shippingAddress
#
# GET /V1/customers/me/shippingAddress
# operationId: customerAccountManagementV1GetDefaultShippingAddressGet
export def "v1-customers-me-shipping-address get-account-management-default-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/shippingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/password
#
# PUT /V1/customers/password
# operationId: customerAccountManagementV1InitiatePasswordResetPut
export def "v1-customers-password reset-account-management-initiate-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string
  template: string
  --website-id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/password")
  let req_body = {"email": $email, "template": $template, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/resetPassword
#
# POST /V1/customers/resetPassword
# operationId: customerAccountManagementV1ResetPasswordPost
export def "v1-customers-reset-password create-account-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string # If empty value given then the customer will be matched by the RP token.
  new_password: string
  reset_token: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/resetPassword")
  let req_body = {"email": $email, "newPassword": $new_password, "resetToken": $reset_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/search
#
# GET /V1/customers/search
# operationId: customerCustomerRepositoryV1GetListGet
export def "v1-customers-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<addresses: list, confirmation: string, created_at: string, created_in: string, custom_attributes: list, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customers/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/validate
#
# PUT /V1/customers/validate
# operationId: customerAccountManagementV1ValidatePut
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers-validate update-account-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
]: any -> record<messages: list<string>, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/validate")
  let req_body = {"customer": $customer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/{customerId}
#
# DELETE /V1/customers/{customerId}
# operationId: customerCustomerRepositoryV1DeleteByIdDelete
export def "v1-customers delete-repository-by-delete" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}
#
# GET /V1/customers/{customerId}
export def "v1-customers get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}
#
# PUT /V1/customers/{customerId}
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers update" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --password-hash: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}"))
  let req_body = {"customer": $customer, "passwordHash": $password_hash} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# customers/{customerId}/billingAddress
#
# GET /V1/customers/{customerId}/billingAddress
export def "v1-customers-billing-address get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}/billingAddress"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}/carts
#
# POST /V1/customers/{customerId}/carts
export def "v1-customers-carts create" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}/carts"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}/confirm
#
# GET /V1/customers/{customerId}/confirm
# operationId: customerAccountManagementV1GetConfirmationStatusGet
export def "v1-customers-confirm get-account-management-confirmation-status-get" [
  customer_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}/confirm"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}/password/resetLinkToken/{resetPasswordLinkToken}
#
# GET /V1/customers/{customerId}/password/resetLinkToken/{resetPasswordLinkToken}
# operationId: customerAccountManagementV1ValidateResetPasswordLinkTokenGet
export def "v1-customers-password-reset-link-token validate-account-management-get" [
  customer_id: int
  reset_password_link_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), reset_password_link_token: (encode-path-segment $reset_password_link_token)} | format pattern "/V1/customers/{customer_id}/password/resetLinkToken/{reset_password_link_token}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}/permissions/readonly
#
# GET /V1/customers/{customerId}/permissions/readonly
# operationId: customerAccountManagementV1IsReadonlyGet
export def "v1-customers-permissions-readonly get-account-management-is" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}/permissions/readonly"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{customerId}/shippingAddress
#
# GET /V1/customers/{customerId}/shippingAddress
export def "v1-customers-shipping-address get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/V1/customers/{customer_id}/shippingAddress"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# customers/{email}/activate
#
# PUT /V1/customers/{email}/activate
# operationId: customerAccountManagementV1ActivatePut
export def "v1-customers-activate update-account-management" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  confirmation_key: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({email: (encode-path-segment $email)} | format pattern "/V1/customers/{email}/activate"))
  let req_body = {"confirmationKey": $confirmation_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# directory/countries
#
# GET /V1/directory/countries
# operationId: directoryCountryInformationAcquirerV1GetCountriesInfoGet
export def "v1-directory-countries get-country-information-acquirer-get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<available_regions: list<record>, extension_attributes: record, full_name_english: string, full_name_locale: string, id: string, three_letter_abbreviation: string, two_letter_abbreviation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/directory/countries")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# directory/countries/{countryId}
#
# GET /V1/directory/countries/{countryId}
# operationId: directoryCountryInformationAcquirerV1GetCountryInfoGet
export def "v1-directory-countries get-country-information-acquirer-country-get-get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_regions: table<code: string, extension_attributes: record, id: string, name: string>, extension_attributes: record, full_name_english: string, full_name_locale: string, id: string, three_letter_abbreviation: string, two_letter_abbreviation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/V1/directory/countries/{country_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# directory/currency
#
# GET /V1/directory/currency
# operationId: directoryCurrencyInformationAcquirerV1GetCurrencyInfoGet
export def "v1-directory-currency get-information-acquirer-get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_currency_codes: list<string>, base_currency_code: string, base_currency_symbol: string, default_display_currency_code: string, default_display_currency_symbol: string, exchange_rates: table<currency_to: string, extension_attributes: record, rate: float>, extension_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/directory/currency")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# eav/attribute-sets
#
# POST /V1/eav/attribute-sets
# operationId: eavAttributeSetManagementV1CreatePost
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-eav-attribute-sets create-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute_set: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
  entity_type_code: string
  skeleton_id: int
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/eav/attribute-sets")
  let req_body = {"attributeSet": $attribute_set, "entityTypeCode": $entity_type_code, "skeletonId": $skeleton_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# eav/attribute-sets/list
#
# GET /V1/eav/attribute-sets/list
# operationId: eavAttributeSetRepositoryV1GetListGet
export def "v1-eav-attribute-sets-list get-repository-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/eav/attribute-sets/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# DELETE /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1DeleteByIdDelete
export def "v1-eav-attribute-sets delete-repository-by-delete" [
  attribute_set_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/eav/attribute-sets/{attribute_set_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# GET /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1GetGet
export def "v1-eav-attribute-sets get-repository-get" [
  attribute_set_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/eav/attribute-sets/{attribute_set_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# PUT /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1SavePut
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-eav-attribute-sets update-repository-save" [
  attribute_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute_set: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/eav/attribute-sets/{attribute_set_id}"))
  let req_body = {"attributeSet": $attribute_set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# gift-wrappings
#
# GET /V1/gift-wrappings
# operationId: giftWrappingWrappingRepositoryV1GetListGet
export def "v1-gift-wrappings get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list, wrapping_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/gift-wrappings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# gift-wrappings
#
# POST /V1/gift-wrappings
# operationId: giftWrappingWrappingRepositoryV1SavePost
# --data shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list<int>, wrapping_id?: int}
export def "v1-gift-wrappings create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  data: record # Interface WrappingInterface — shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list<int>, wrapping_id?: int}
  --store-id: int
]: any -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/gift-wrappings")
  let req_body = {"data": $data, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# gift-wrappings/{id}
#
# DELETE /V1/gift-wrappings/{id}
# operationId: giftWrappingWrappingRepositoryV1DeleteByIdDelete
export def "v1-gift-wrappings delete-repository-by-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/gift-wrappings/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# gift-wrappings/{id}
#
# GET /V1/gift-wrappings/{id}
# operationId: giftWrappingWrappingRepositoryV1GetGet
export def "v1-gift-wrappings get-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --store-id: int
]: nothing -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/gift-wrappings/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# gift-wrappings/{wrappingId}
#
# PUT /V1/gift-wrappings/{wrappingId}
# operationId: giftWrappingWrappingRepositoryV1SavePut
# --data shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list<int>, wrapping_id?: int}
export def "v1-gift-wrappings update-repository-save" [
  wrapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  data: record # Interface WrappingInterface — shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list<int>, wrapping_id?: int}
  --store-id: int
]: any -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({wrapping_id: (encode-path-segment $wrapping_id)} | format pattern "/V1/gift-wrappings/{wrapping_id}"))
  let req_body = {"data": $data, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# giftregistry/mine/estimate-shipping-methods
#
# POST /V1/giftregistry/mine/estimate-shipping-methods
# operationId: giftRegistryShippingMethodManagementV1EstimateByRegistryIdPost
export def "v1-giftregistry-mine-estimate-shipping-methods create-gift-registry-management-by-registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  registry_id: int # The estimate registry id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/giftregistry/mine/estimate-shipping-methods")
  let req_body = {"registryId": $registry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts
#
# POST /V1/guest-carts
# operationId: quoteGuestCartManagementV1CreateEmptyCartPost
export def "v1-guest-carts create-quote-management-empty-create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/guest-carts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}
#
# GET /V1/guest-carts/{cartId}
# operationId: quoteGuestCartRepositoryV1GetGet
export def "v1-guest-carts get-quote-repository-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}
#
# PUT /V1/guest-carts/{cartId}
# operationId: quoteGuestCartManagementV1AssignCustomerPut
export def "v1-guest-carts assign-quote-management-customer-update" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  customer_id: int # The customer ID.
  store_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}"))
  let req_body = {"customerId": $customer_id, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/billing-address
#
# GET /V1/guest-carts/{cartId}/billing-address
# operationId: quoteGuestBillingAddressManagementV1GetGet
export def "v1-guest-carts-billing-address get-quote-management-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/billing-address"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/billing-address
#
# POST /V1/guest-carts/{cartId}/billing-address
# operationId: quoteGuestBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-guest-carts-billing-address assign-quote-management-create" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  --use-for-shipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/billing-address"))
  let req_body = {"address": $address, "useForShipping": $use_for_shipping} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/checkout-fields
#
# POST /V1/guest-carts/{cartId}/checkout-fields
# operationId: temandoShippingQuoteGuestCartCheckoutFieldManagementV1SaveCheckoutFieldsPost
# --serviceSelection item shape: {attribute_code: string, value: string}
export def "v1-guest-carts-checkout-fields create-temando-shipping-quote-management-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  service_selection: list # item shape: {attribute_code: string, value: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/checkout-fields"))
  let req_body = {"serviceSelection": $service_selection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/collect-totals
#
# PUT /V1/guest-carts/{cartId}/collect-totals
# operationId: quoteGuestCartTotalManagementV1CollectTotalsPut
# --additionalData shape: {custom_attributes?: list, extension_attributes?: record}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-collect-totals update-quote-management" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --additional-data: record # Additional data for totals collection. — shape: {custom_attributes?: list, extension_attributes?: record}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
  --shipping-carrier-code: string # The carrier code.
  --shipping-method-code: string # The shipping method code.
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/collect-totals"))
  let req_body = {"additionalData": $additional_data, "paymentMethod": $payment_method, "shippingCarrierCode": $shipping_carrier_code, "shippingMethodCode": $shipping_method_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/collection-point/search-request
#
# DELETE /V1/guest-carts/{cartId}/collection-point/search-request
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1DeleteSearchRequestDelete
export def "v1-guest-carts-collection-point-search-request delete-temando-shipping-management-delete" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/collection-point/search-request"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/collection-point/search-request
#
# PUT /V1/guest-carts/{cartId}/collection-point/search-request
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1SaveSearchRequestPut
export def "v1-guest-carts-collection-point-search-request update-temando-shipping-management-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  country_id: string
  postcode: string
]: any -> record<country_id: string, pending: bool, postcode: string, shipping_address_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/collection-point/search-request"))
  let req_body = {"countryId": $country_id, "postcode": $postcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/collection-point/search-result
#
# GET /V1/guest-carts/{cartId}/collection-point/search-result
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1GetCollectionPointsGet
export def "v1-guest-carts-collection-point-search-result get-temando-shipping-management-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<city: string, collection_point_id: string, country: string, entity_id: int, name: string, opening_hours: list<string>, postcode: string, recipient_address_id: int, region: string, selected: bool, shipping_experiences: list<string>, street: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/collection-point/search-result"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/collection-point/select
#
# POST /V1/guest-carts/{cartId}/collection-point/select
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1SelectCollectionPointPost
export def "v1-guest-carts-collection-point-select create-temando-shipping-management" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/collection-point/select"))
  let req_body = {"entityId": $entity_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/coupons
#
# DELETE /V1/guest-carts/{cartId}/coupons
# operationId: quoteGuestCouponManagementV1RemoveDelete
export def "v1-guest-carts-coupons delete-quote-management-delete" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/coupons"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/coupons
#
# GET /V1/guest-carts/{cartId}/coupons
# operationId: quoteGuestCouponManagementV1GetGet
export def "v1-guest-carts-coupons get-quote-management-get" [
  cart_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/coupons"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/guest-carts/{cartId}/coupons/{couponCode}
# operationId: quoteGuestCouponManagementV1SetPut
export def "v1-guest-carts-coupons update-quote-management-update" [
  cart_id: string
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), coupon_code: (encode-path-segment $coupon_code)} | format pattern "/V1/guest-carts/{cart_id}/coupons/{coupon_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/delivery-option
#
# POST /V1/guest-carts/{cartId}/delivery-option
# operationId: temandoShippingQuoteGuestCartDeliveryOptionManagementV1SavePost
export def "v1-guest-carts-delivery-option create-temando-shipping-quote-management-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  selected_option: string
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/delivery-option"))
  let req_body = {"selectedOption": $selected_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/estimate-shipping-methods
#
# POST /V1/guest-carts/{cartId}/estimate-shipping-methods
# operationId: quoteGuestShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-guest-carts-estimate-shipping-methods create-quote-shipment-estimation-by-extended-address" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/estimate-shipping-methods"))
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/gift-message
#
# GET /V1/guest-carts/{cartId}/gift-message
# operationId: giftMessageGuestCartRepositoryV1GetGet
export def "v1-guest-carts-gift-message get-repository-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/gift-message"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/gift-message
#
# POST /V1/guest-carts/{cartId}/gift-message
# operationId: giftMessageGuestCartRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-guest-carts-gift-message create-repository-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/gift-message"))
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/gift-message/{itemId}
#
# GET /V1/guest-carts/{cartId}/gift-message/{itemId}
# operationId: giftMessageGuestItemRepositoryV1GetGet
export def "v1-guest-carts-gift-message get-item-repository-get" [
  cart_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/guest-carts/{cart_id}/gift-message/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/gift-message/{itemId}
#
# POST /V1/guest-carts/{cartId}/gift-message/{itemId}
# operationId: giftMessageGuestItemRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-guest-carts-gift-message create-item-repository-save" [
  cart_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_message: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/guest-carts/{cart_id}/gift-message/{item_id}"))
  let req_body = {"giftMessage": $gift_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/items
#
# GET /V1/guest-carts/{cartId}/items
# operationId: quoteGuestCartItemRepositoryV1GetListGet
export def "v1-guest-carts-items get-quote-repository-list-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/items"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/items
#
# POST /V1/guest-carts/{cartId}/items
# operationId: quoteGuestCartItemRepositoryV1SavePost
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-guest-carts-items create-quote-repository-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/items"))
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/items/{itemId}
#
# DELETE /V1/guest-carts/{cartId}/items/{itemId}
# operationId: quoteGuestCartItemRepositoryV1DeleteByIdDelete
export def "v1-guest-carts-items delete-quote-repository-by-delete" [
  cart_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/guest-carts/{cart_id}/items/{item_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/items/{itemId}
#
# PUT /V1/guest-carts/{cartId}/items/{itemId}
# operationId: quoteGuestCartItemRepositoryV1SavePut
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-guest-carts-items update-quote-repository-save" [
  cart_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  cart_item: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), item_id: (encode-path-segment $item_id)} | format pattern "/V1/guest-carts/{cart_id}/items/{item_id}"))
  let req_body = {"cartItem": $cart_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/order
#
# PUT /V1/guest-carts/{cartId}/order
# operationId: quoteGuestCartManagementV1PlaceOrderPut
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-order update-quote-management-place" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --payment-method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/order"))
  let req_body = {"paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/payment-information
#
# GET /V1/guest-carts/{cartId}/payment-information
# operationId: checkoutGuestPaymentInformationManagementV1GetPaymentInformationGet
export def "v1-guest-carts-payment-information get-checkout-management-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/payment-information"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/payment-information
#
# POST /V1/guest-carts/{cartId}/payment-information
# operationId: checkoutGuestPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-payment-information create-checkout-management-save-and-place-order" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  email: string
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/payment-information"))
  let req_body = {"billingAddress": $billing_address, "email": $email, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/payment-methods
#
# GET /V1/guest-carts/{cartId}/payment-methods
# operationId: quoteGuestPaymentMethodManagementV1GetListGet
export def "v1-guest-carts-payment-methods get-quote-management-list-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/payment-methods"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/selected-payment-method
#
# GET /V1/guest-carts/{cartId}/selected-payment-method
# operationId: quoteGuestPaymentMethodManagementV1GetGet
export def "v1-guest-carts-selected-payment-method get-quote-management-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/selected-payment-method"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/selected-payment-method
#
# PUT /V1/guest-carts/{cartId}/selected-payment-method
# operationId: quoteGuestPaymentMethodManagementV1SetPut
# --method shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-selected-payment-method update-quote-management-update" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/selected-payment-method"))
  let req_body = {"method": $method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/set-payment-information
#
# POST /V1/guest-carts/{cartId}/set-payment-information
# operationId: checkoutGuestPaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-set-payment-information create-checkout-management-save" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  email: string
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/set-payment-information"))
  let req_body = {"billingAddress": $billing_address, "email": $email, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/shipping-information
#
# POST /V1/guest-carts/{cartId}/shipping-information
# operationId: checkoutGuestShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-guest-carts-shipping-information create-checkout-management-save-address" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/shipping-information"))
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-carts/{cartId}/shipping-methods
#
# GET /V1/guest-carts/{cartId}/shipping-methods
# operationId: quoteGuestShippingMethodManagementV1GetListGet
export def "v1-guest-carts-shipping-methods get-quote-management-list-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/shipping-methods"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/totals
#
# GET /V1/guest-carts/{cartId}/totals
# operationId: quoteGuestCartTotalRepositoryV1GetGet
export def "v1-guest-carts-totals get-quote-repository-get" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/totals"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/totals-information
#
# POST /V1/guest-carts/{cartId}/totals-information
# operationId: checkoutGuestTotalsInformationManagementV1CalculatePost
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-guest-carts-totals-information create-checkout-management-calculate" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-carts/{cart_id}/totals-information"))
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# guest-giftregistry/{cartId}/estimate-shipping-methods
#
# POST /V1/guest-giftregistry/{cartId}/estimate-shipping-methods
# operationId: giftRegistryGuestCartShippingMethodManagementV1EstimateByRegistryIdPost
export def "v1-guest-giftregistry-estimate-shipping-methods create-gift-registry-cart-management-by-registry" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  registry_id: int # The estimate registry id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/guest-giftregistry/{cart_id}/estimate-shipping-methods"))
  let req_body = {"registryId": $registry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# hierarchy/move/{id}
#
# PUT /V1/hierarchy/move/{id}
# operationId: companyCompanyHierarchyV1MoveNodePut
export def "v1-hierarchy-move update-company-company-node" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  new_parent_id: int
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/hierarchy/move/{id}"))
  let req_body = {"newParentId": $new_parent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# hierarchy/{id}
#
# GET /V1/hierarchy/{id}
# operationId: companyCompanyHierarchyV1GetCompanyHierarchyGet
export def "v1-hierarchy get-company-company-company-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<entity_id: int, entity_type: string, extension_attributes: record, structure_id: int, structure_parent_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/hierarchy/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# integration/admin/token
#
# POST /V1/integration/admin/token
# operationId: integrationAdminTokenServiceV1CreateAdminAccessTokenPost
export def "v1-integration-admin-token create-service-access-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  password: string
  username: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/integration/admin/token")
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# integration/customer/token
#
# POST /V1/integration/customer/token
# operationId: integrationCustomerTokenServiceV1CreateCustomerAccessTokenPost
export def "v1-integration-customer-token create-service-access-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  password: string
  username: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/integration/customer/token")
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invoice/{invoiceId}/refund
#
# POST /V1/invoice/{invoiceId}/refund
# operationId: salesRefundInvoiceV1ExecutePost
# --arguments shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-invoice-refund create-sales-execute" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --append-comment: oneof<nothing, bool>
  --arguments: record # Interface CreditmemoCreationArgumentsInterface — shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
  --comment: record # Interface CreditmemoCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --is-online: oneof<nothing, bool>
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/V1/invoice/{invoice_id}/refund"))
  let req_body = {"appendComment": $append_comment, "arguments": $arguments, "comment": $comment, "isOnline": $is_online, "items": $items, "notify": $notify} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invoices
#
# GET /V1/invoices
# operationId: salesInvoiceRepositoryV1GetListGet
export def "v1-invoices get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: list, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: list, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/invoices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invoices/
#
# POST /V1/invoices/
# operationId: salesInvoiceRepositoryV1SavePost
# --entity shape: {base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_refunded?: float, billing_address_id?: int, can_void_flag?: int, ... (31 more fields)}
export def "v1-invoices create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Invoice interface. An invoice is a record of the receipt of payment for an order. — shape: {base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_refunded?: float, billing_address_id?: int, can_void_flag?: int, ... (31 more fields)}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string, vertex_tax_calculation_billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, vertex_tax_calculation_order: record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, vertex_tax_calculation_shipping_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>>, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/invoices/")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invoices/comments
#
# POST /V1/invoices/comments
# operationId: salesInvoiceCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-invoices-comments create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Invoice comment interface. An invoice is a record of the receipt of payment for an order. An invoice can include comments that detail the invoice history. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/invoices/comments")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invoices/{id}
#
# GET /V1/invoices/{id}
# operationId: salesInvoiceRepositoryV1GetGet
export def "v1-invoices get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string, vertex_tax_calculation_billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, vertex_tax_calculation_order: record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, vertex_tax_calculation_shipping_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>>, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/invoices/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invoices/{id}/capture
#
# POST /V1/invoices/{id}/capture
# operationId: salesInvoiceManagementV1SetCapturePost
export def "v1-invoices-capture update-sales-management-create" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/invoices/{id}/capture"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invoices/{id}/comments
#
# GET /V1/invoices/{id}/comments
# operationId: salesInvoiceManagementV1GetCommentsListGet
export def "v1-invoices-comments get-sales-management-list-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/invoices/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invoices/{id}/emails
#
# POST /V1/invoices/{id}/emails
# operationId: salesInvoiceManagementV1NotifyPost
export def "v1-invoices-emails notify-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/invoices/{id}/emails"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invoices/{id}/void
#
# POST /V1/invoices/{id}/void
# operationId: salesInvoiceManagementV1SetVoidPost
export def "v1-invoices-void update-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/invoices/{id}/void"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modules
#
# GET /V1/modules
# operationId: backendModuleServiceV1GetModulesGet
export def "v1-modules get-backend-service-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/modules")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/billing-address
#
# GET /V1/negotiable-carts/{cartId}/billing-address
# operationId: negotiableQuoteBillingAddressManagementV1GetGet
export def "v1-negotiable-carts-billing-address get-quote-management-get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/billing-address"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/billing-address
#
# POST /V1/negotiable-carts/{cartId}/billing-address
# operationId: negotiableQuoteBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-negotiable-carts-billing-address assign-quote-management-create" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  --use-for-shipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/billing-address"))
  let req_body = {"address": $address, "useForShipping": $use_for_shipping} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/coupons
#
# DELETE /V1/negotiable-carts/{cartId}/coupons
# operationId: negotiableQuoteCouponManagementV1RemoveDelete
export def "v1-negotiable-carts-coupons delete-quote-management-delete" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/coupons"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/negotiable-carts/{cartId}/coupons/{couponCode}
# operationId: negotiableQuoteCouponManagementV1SetPut
export def "v1-negotiable-carts-coupons update-quote-management-update" [
  cart_id: int
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), coupon_code: (encode-path-segment $coupon_code)} | format pattern "/V1/negotiable-carts/{cart_id}/coupons/{coupon_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/estimate-shipping-methods
#
# POST /V1/negotiable-carts/{cartId}/estimate-shipping-methods
# operationId: negotiableQuoteShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
export def "v1-negotiable-carts-estimate-shipping-methods create-quote-shipment-estimation-by-extended-address" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/estimate-shipping-methods"))
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/estimate-shipping-methods-by-address-id
#
# POST /V1/negotiable-carts/{cartId}/estimate-shipping-methods-by-address-id
# operationId: negotiableQuoteShippingMethodManagementV1EstimateByAddressIdPost
export def "v1-negotiable-carts-estimate-shipping-methods-by-address-id create-quote-management" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_id: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/estimate-shipping-methods-by-address-id"))
  let req_body = {"addressId": $address_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/giftCards
#
# POST /V1/negotiable-carts/{cartId}/giftCards
# operationId: negotiableQuoteGiftCardAccountManagementV1SaveByQuoteIdPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-negotiable-carts-gift-cards create-quote-account-management-save-by-quote" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  gift_card_account_data: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/giftCards"))
  let req_body = {"giftCardAccountData": $gift_card_account_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/negotiable-carts/{cartId}/giftCards/{giftCardCode}
# operationId: negotiableQuoteGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-negotiable-carts-gift-cards delete-quote-account-management-by-quote-delete" [
  cart_id: int
  gift_card_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id), gift_card_code: (encode-path-segment $gift_card_code)} | format pattern "/V1/negotiable-carts/{cart_id}/giftCards/{gift_card_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/payment-information
#
# GET /V1/negotiable-carts/{cartId}/payment-information
# operationId: negotiableQuotePaymentInformationManagementV1GetPaymentInformationGet
export def "v1-negotiable-carts-payment-information get-quote-management-get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/payment-information"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/payment-information
#
# POST /V1/negotiable-carts/{cartId}/payment-information
# operationId: negotiableQuotePaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-negotiable-carts-payment-information create-quote-management-save-and-place-order" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/payment-information"))
  let req_body = {"billingAddress": $billing_address, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/set-payment-information
#
# POST /V1/negotiable-carts/{cartId}/set-payment-information
# operationId: negotiableQuotePaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-negotiable-carts-set-payment-information create-quote-management-save" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/set-payment-information"))
  let req_body = {"billingAddress": $billing_address, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/shipping-information
#
# POST /V1/negotiable-carts/{cartId}/shipping-information
# operationId: negotiableQuoteShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-negotiable-carts-shipping-information create-quote-management-save-address" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address_information: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/shipping-information"))
  let req_body = {"addressInformation": $address_information} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiable-carts/{cartId}/totals
#
# GET /V1/negotiable-carts/{cartId}/totals
# operationId: negotiableQuoteCartTotalRepositoryV1GetGet
export def "v1-negotiable-carts-totals get-quote-repository-get" [
  cart_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/negotiable-carts/{cart_id}/totals"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiableQuote/attachmentContent
#
# GET /V1/negotiableQuote/attachmentContent
# operationId: negotiableQuoteAttachmentContentManagementV1GetGet
export def "v1-negotiable-quote-attachment-content get-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --attachment-ids: list<int>
]: nothing -> table<base64_encoded_data: string, extension_attributes: record, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachmentIds" $attachment_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/negotiableQuote/attachmentContent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiableQuote/decline
#
# POST /V1/negotiableQuote/decline
# operationId: negotiableQuoteNegotiableQuoteManagementV1DeclinePost
export def "v1-negotiable-quote-decline create-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  quote_id: int
  reason: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/decline")
  let req_body = {"quoteId": $quote_id, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiableQuote/pricesUpdated
#
# POST /V1/negotiableQuote/pricesUpdated
# operationId: negotiableQuoteNegotiableQuotePriceManagementV1PricesUpdatedPost
export def "v1-negotiable-quote-prices-updated create-management" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  quote_ids: list<int>
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/pricesUpdated")
  let req_body = {"quoteIds": $quote_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiableQuote/request
#
# POST /V1/negotiableQuote/request
# operationId: negotiableQuoteNegotiableQuoteManagementV1CreatePost
# --files item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
export def "v1-negotiable-quote-request create-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string
  --files: list # item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
  quote_id: int
  quote_name: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/request")
  let req_body = {"comment": $comment, "files": $files, "quoteId": $quote_id, "quoteName": $quote_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiableQuote/submitToCustomer
#
# POST /V1/negotiableQuote/submitToCustomer
# operationId: negotiableQuoteNegotiableQuoteManagementV1AdminSendPost
# --files item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
export def "v1-negotiable-quote-submit-to-customer send-management-admin-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string
  --files: list # item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
  quote_id: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/submitToCustomer")
  let req_body = {"comment": $comment, "files": $files, "quoteId": $quote_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiableQuote/{quoteId}
#
# PUT /V1/negotiableQuote/{quoteId}
# operationId: negotiableQuoteNegotiableCartRepositoryV1SavePut
# --quote shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
export def "v1-negotiable-quote update-cart-repository-save" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  quote: record # Interface CartInterface — shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/V1/negotiableQuote/{quote_id}"))
  let req_body = {"quote": $quote} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# negotiableQuote/{quoteId}/comments
#
# GET /V1/negotiableQuote/{quoteId}/comments
# operationId: negotiableQuoteCommentLocatorV1GetListForQuoteGet
export def "v1-negotiable-quote-comments get-locator-list-for-get" [
  quote_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attachments: list<record>, comment: string, created_at: string, creator_id: int, creator_type: int, entity_id: int, extension_attributes: record, is_decline: int, is_draft: int, parent_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/V1/negotiableQuote/{quote_id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# negotiableQuote/{quoteId}/shippingMethod
#
# PUT /V1/negotiableQuote/{quoteId}/shippingMethod
# operationId: negotiableQuoteNegotiableQuoteShippingManagementV1SetShippingMethodPut
export def "v1-negotiable-quote-shipping-method update-management-update" [
  quote_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  shipping_method: string # The shipping method code.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/V1/negotiableQuote/{quote_id}/shippingMethod"))
  let req_body = {"shippingMethod": $shipping_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# order/{orderId}/invoice
#
# POST /V1/order/{orderId}/invoice
# operationId: salesInvoiceOrderV1ExecutePost
# --arguments shape: {extension_attributes?: record}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-order-invoice create-sales-execute" [
  order_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --append-comment: oneof<nothing, bool>
  --arguments: record # Interface for creation arguments for Invoice. — shape: {extension_attributes?: record}
  --capture: oneof<nothing, bool>
  --comment: record # Interface InvoiceCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/V1/order/{order_id}/invoice"))
  let req_body = {"appendComment": $append_comment, "arguments": $arguments, "capture": $capture, "comment": $comment, "items": $items, "notify": $notify} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# order/{orderId}/refund
#
# POST /V1/order/{orderId}/refund
# operationId: salesRefundOrderV1ExecutePost
# --arguments shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-order-refund create-sales-execute" [
  order_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --append-comment: oneof<nothing, bool>
  --arguments: record # Interface CreditmemoCreationArgumentsInterface — shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
  --comment: record # Interface CreditmemoCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/V1/order/{order_id}/refund"))
  let req_body = {"appendComment": $append_comment, "arguments": $arguments, "comment": $comment, "items": $items, "notify": $notify} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# order/{orderId}/ship
#
# POST /V1/order/{orderId}/ship
# operationId: salesShipOrderV1ExecutePost
# --arguments shape: {extension_attributes?: record}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
# --packages item shape: {extension_attributes?: record}
# --tracks item shape: {carrier_code: string, extension_attributes?: record, title: string, track_number: string}
export def "v1-order-ship create-sales-execute" [
  order_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --append-comment: oneof<nothing, bool>
  --arguments: record # Interface for creation arguments for Shipment. — shape: {extension_attributes?: record}
  --comment: record # Interface ShipmentCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
  --packages: list # item shape: {extension_attributes?: record}
  --tracks: list # item shape: {carrier_code: string, extension_attributes?: record, title: string, track_number: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/V1/order/{order_id}/ship"))
  let req_body = {"appendComment": $append_comment, "arguments": $arguments, "comment": $comment, "items": $items, "notify": $notify, "packages": $packages, "tracks": $tracks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# orders
#
# GET /V1/orders
# operationId: salesOrderRepositoryV1GetListGet
export def "v1-orders get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/
#
# POST /V1/orders/
# operationId: salesOrderRepositoryV1SavePost
# --entity shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, ... (123 more fields)}
export def "v1-orders create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Order interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, ... (123 more fields)}
]: any -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/orders/")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# orders/create
#
# PUT /V1/orders/create
# operationId: salesOrderRepositoryV1SavePut
# --entity shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, ... (123 more fields)}
export def "v1-orders-create update-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Order interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, ... (123 more fields)}
]: any -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/orders/create")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# orders/items
#
# GET /V1/orders/items
# operationId: salesOrderItemRepositoryV1GetListGet
export def "v1-orders-items get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/orders/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/items/{id}
#
# GET /V1/orders/items/{id}
# operationId: salesOrderItemRepositoryV1GetGet
export def "v1-orders-items get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record<gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_base_price: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_id: string, gw_price: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, invoice_text_codes: list<string>, tax_codes: list<string>, vertex_tax_codes: list<string>>, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/items/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}
#
# GET /V1/orders/{id}
# operationId: salesOrderRepositoryV1GetGet
export def "v1-orders get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/cancel
#
# POST /V1/orders/{id}/cancel
# operationId: salesOrderManagementV1CancelPost
export def "v1-orders-cancel create-sales-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/cancel"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/comments
#
# GET /V1/orders/{id}/comments
# operationId: salesOrderManagementV1GetCommentsListGet
export def "v1-orders-comments get-sales-management-list-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/comments
#
# POST /V1/orders/{id}/comments
# operationId: salesOrderManagementV1AddCommentPost
# --statusHistory shape: {comment: string, created_at?: string, entity_id?: int, entity_name?: string, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status?: string}
export def "v1-orders-comments create-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  status_history: record # Order status history interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {comment: string, created_at?: string, entity_id?: int, entity_name?: string, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/comments"))
  let req_body = {"statusHistory": $status_history} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# orders/{id}/emails
#
# POST /V1/orders/{id}/emails
# operationId: salesOrderManagementV1NotifyPost
export def "v1-orders-emails notify-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/emails"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/hold
#
# POST /V1/orders/{id}/hold
# operationId: salesOrderManagementV1HoldPost
export def "v1-orders-hold create-sales-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/hold"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/statuses
#
# GET /V1/orders/{id}/statuses
# operationId: salesOrderManagementV1GetStatusGet
export def "v1-orders-statuses get-sales-management-status-get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/statuses"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{id}/unhold
#
# POST /V1/orders/{id}/unhold
# operationId: salesOrderManagementV1UnHoldPost
export def "v1-orders-unhold create-sales-management-un-hold" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/orders/{id}/unhold"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# orders/{parent_id}
#
# PUT /V1/orders/{parent_id}
# operationId: salesOrderAddressRepositoryV1SavePut
# --entity shape: {address_type: string, city: string, company?: string, country_id: string, customer_address_id?: int, customer_id?: int, email?: string, entity_id?: int, extension_attributes?: record, fax?: string, firstname: string, lastname: string, middlename?: string, parent_id?: int, postcode: string, prefix?: string, region?: string, region_code?: string, region_id?: int, street?: list<string>, suffix?: string, telephone: string, vat_id?: string, vat_is_valid?: int, vat_request_date?: string, ... (2 more fields)}
export def "v1-orders update-sales-address-repository-save" [
  parent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Order address interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {address_type: string, city: string, company?: string, country_id: string, customer_address_id?: int, customer_id?: int, email?: string, entity_id?: int, extension_attributes?: record, fax?: string, firstname: string, lastname: string, middlename?: string, parent_id?: int, postcode: string, prefix?: string, region?: string, region_code?: string, region_id?: int, street?: list<string>, suffix?: string, telephone: string, vat_id?: string, vat_is_valid?: int, vat_request_date?: string, ... (2 more fields)}
]: any -> record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list<record>>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({parent_id: (encode-path-segment $parent_id)} | format pattern "/V1/orders/{parent_id}"))
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products
#
# GET /V1/products
# operationId: catalogProductRepositoryV1GetListGet
export def "v1-products get-catalog-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, created_at: string, custom_attributes: list, extension_attributes: record, id: int, media_gallery_entries: list, name: string, options: list, price: float, product_links: list, sku: string, status: int, tier_prices: list, type_id: string, updated_at: string, visibility: int, weight: float>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products
#
# POST /V1/products
# operationId: catalogProductRepositoryV1SavePost
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-products create-catalog-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
  --save-options: oneof<nothing, bool>
]: any -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products")
  let req_body = {"product": $product, "saveOptions": $save_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products-render-info
#
# GET /V1/products-render-info
# operationId: catalogProductRenderListV1GetListGet
export def "v1-products-render-info list-catalog-get-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
  --store-id: int
  --currency-code: string
]: nothing -> record<items: table<add_to_cart_button: record, add_to_compare_button: record, currency_code: string, extension_attributes: record, id: int, images: list, is_salable: string, name: string, price_info: record, store_id: int, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar") (serialize-qp "storeId" $store_id "scalar") (serialize-qp "currencyCode" $currency_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products-render-info" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets
#
# POST /V1/products/attribute-sets
# operationId: catalogAttributeSetManagementV1CreatePost
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-products-attribute-sets create-catalog-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute_set: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
  skeleton_id: int
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets")
  let req_body = {"attributeSet": $attribute_set, "skeletonId": $skeleton_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attribute-sets/attributes
#
# POST /V1/products/attribute-sets/attributes
# operationId: catalogProductAttributeManagementV1AssignPost
export def "v1-products-attribute-sets-attributes assign-catalog-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute_code: string
  attribute_group_id: int
  attribute_set_id: int
  sort_order: int
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets/attributes")
  let req_body = {"attributeCode": $attribute_code, "attributeGroupId": $attribute_group_id, "attributeSetId": $attribute_set_id, "sortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attribute-sets/groups
#
# POST /V1/products/attribute-sets/groups
# operationId: catalogProductAttributeGroupRepositoryV1SavePost
# --group shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
export def "v1-products-attribute-sets-groups create-catalog-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  group: record # Interface AttributeGroupInterface — shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
]: any -> record<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record<attribute_group_code: string, sort_order: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets/groups")
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attribute-sets/groups/list
#
# GET /V1/products/attribute-sets/groups/list
# operationId: catalogProductAttributeGroupRepositoryV1GetListGet
export def "v1-products-attribute-sets-groups-list get-catalog-repository-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attribute-sets/groups/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/groups/{groupId}
#
# DELETE /V1/products/attribute-sets/groups/{groupId}
# operationId: catalogProductAttributeGroupRepositoryV1DeleteByIdDelete
export def "v1-products-attribute-sets-groups delete-catalog-repository-by-delete" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/V1/products/attribute-sets/groups/{group_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/sets/list
#
# GET /V1/products/attribute-sets/sets/list
# operationId: catalogAttributeSetRepositoryV1GetListGet
export def "v1-products-attribute-sets-sets-list get-catalog-repository-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attribute-sets/sets/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# DELETE /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1DeleteByIdDelete
export def "v1-products-attribute-sets delete-catalog-repository-by-delete" [
  attribute_set_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# GET /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1GetGet
export def "v1-products-attribute-sets get-catalog-repository-get" [
  attribute_set_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# PUT /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1SavePut
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-products-attribute-sets update-catalog-repository-save" [
  attribute_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute_set: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}"))
  let req_body = {"attributeSet": $attribute_set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attribute-sets/{attributeSetId}/attributes
#
# GET /V1/products/attribute-sets/{attributeSetId}/attributes
# operationId: catalogProductAttributeManagementV1GetAttributesGet
export def "v1-products-attribute-sets-attributes get-catalog-management-get" [
  attribute_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list<record>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list<record>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list<record>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}/attributes"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}/attributes/{attributeCode}
#
# DELETE /V1/products/attribute-sets/{attributeSetId}/attributes/{attributeCode}
# operationId: catalogProductAttributeManagementV1UnassignDelete
export def "v1-products-attribute-sets-attributes delete-catalog-management-unassign" [
  attribute_set_id: string
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id), attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}/attributes/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}/groups
#
# PUT /V1/products/attribute-sets/{attributeSetId}/groups
# operationId: catalogProductAttributeGroupRepositoryV1SavePut
# --group shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
export def "v1-products-attribute-sets-groups update-catalog-repository-save" [
  attribute_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  group: record # Interface AttributeGroupInterface — shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
]: any -> record<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record<attribute_group_code: string, sort_order: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_id: (encode-path-segment $attribute_set_id)} | format pattern "/V1/products/attribute-sets/{attribute_set_id}/groups"))
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attributes
#
# GET /V1/products/attributes
# operationId: catalogProductAttributeRepositoryV1GetListGet
export def "v1-products-attributes get-catalog-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<apply_to: list, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attributes
#
# POST /V1/products/attributes
# operationId: catalogProductAttributeRepositoryV1SavePost
# --attribute shape: {apply_to?: list<string>, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, ... (18 more fields)}
export def "v1-products-attributes create-catalog-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute: record # shape: {apply_to?: list<string>, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, ... (18 more fields)}
]: any -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attributes")
  let req_body = {"attribute": $attribute} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attributes/types
#
# GET /V1/products/attributes/types
# operationId: catalogProductAttributeTypesListV1GetItemsGet
export def "v1-products-attributes-types list-catalog-get-items-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, label: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attributes/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# DELETE /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1DeleteByIdDelete
export def "v1-products-attributes delete-catalog-repository-by-delete" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attributes/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# GET /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1GetGet
export def "v1-products-attributes get-catalog-repository-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attributes/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# PUT /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1SavePut
# --attribute shape: {apply_to?: list<string>, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, ... (18 more fields)}
export def "v1-products-attributes update-catalog-repository-save" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attribute: record # shape: {apply_to?: list<string>, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, ... (18 more fields)}
]: any -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attributes/{attribute_code}"))
  let req_body = {"attribute": $attribute} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attributes/{attributeCode}/options
#
# GET /V1/products/attributes/{attributeCode}/options
# operationId: catalogProductAttributeOptionManagementV1GetItemsGet
export def "v1-products-attributes-options get-catalog-management-items-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<is_default: bool, label: string, sort_order: int, store_labels: list<record>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attributes/{attribute_code}/options"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}/options
#
# POST /V1/products/attributes/{attributeCode}/options
# operationId: catalogProductAttributeOptionManagementV1AddPost
# --option shape: {is_default?: bool, label: string, sort_order?: int, store_labels?: list, value: string}
export def "v1-products-attributes-options create-catalog-management-create" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # Created from: — shape: {is_default?: bool, label: string, sort_order?: int, store_labels?: list, value: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/products/attributes/{attribute_code}/options"))
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/attributes/{attributeCode}/options/{optionId}
#
# DELETE /V1/products/attributes/{attributeCode}/options/{optionId}
# operationId: catalogProductAttributeOptionManagementV1DeleteDelete
export def "v1-products-attributes-options delete-catalog-management-delete" [
  attribute_code: string
  option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code), option_id: (encode-path-segment $option_id)} | format pattern "/V1/products/attributes/{attribute_code}/options/{option_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/base-prices
#
# POST /V1/products/base-prices
# operationId: catalogBasePriceStorageV1UpdatePost
# --prices item shape: {extension_attributes?: record, price: float, sku: string, store_id: int}
export def "v1-products-base-prices update-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/base-prices")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/base-prices-information
#
# POST /V1/products/base-prices-information
# operationId: catalogBasePriceStorageV1GetPost
export def "v1-products-base-prices-information get-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  skus: list<string>
]: any -> table<extension_attributes: record, price: float, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/base-prices-information")
  let req_body = {"skus": $skus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/cost
#
# POST /V1/products/cost
# operationId: catalogCostStorageV1UpdatePost
# --prices item shape: {cost: float, extension_attributes?: record, sku: string, store_id: int}
export def "v1-products-cost update-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {cost: float, extension_attributes?: record, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/cost-delete
#
# POST /V1/products/cost-delete
# operationId: catalogCostStorageV1DeletePost
export def "v1-products-cost-delete create-catalog-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  skus: list<string>
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost-delete")
  let req_body = {"skus": $skus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/cost-information
#
# POST /V1/products/cost-information
# operationId: catalogCostStorageV1GetPost
export def "v1-products-cost-information get-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  skus: list<string>
]: any -> table<cost: float, extension_attributes: record, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost-information")
  let req_body = {"skus": $skus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/downloadable-links/samples/{id}
#
# DELETE /V1/products/downloadable-links/samples/{id}
# operationId: downloadableSampleRepositoryV1DeleteDelete
export def "v1-products-downloadable-links-samples delete-repository-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/products/downloadable-links/samples/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/downloadable-links/{id}
#
# DELETE /V1/products/downloadable-links/{id}
# operationId: downloadableLinkRepositoryV1DeleteDelete
export def "v1-products-downloadable-links delete-repository-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/products/downloadable-links/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/links/types
#
# GET /V1/products/links/types
# operationId: catalogProductLinkTypeListV1GetItemsGet
export def "v1-products-links-types list-catalog-get-items-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: int, extension_attributes: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/links/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/links/{type}/attributes
#
# GET /V1/products/links/{type}/attributes
# operationId: catalogProductLinkTypeListV1GetItemAttributesGet
export def "v1-products-links-attributes list-catalog-get-item-get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/V1/products/links/{type}/attributes"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/media/types/{attributeSetName}
#
# GET /V1/products/media/types/{attributeSetName}
# operationId: catalogProductMediaAttributeManagementV1GetListGet
export def "v1-products-media-types get-catalog-attribute-management-list-get" [
  attribute_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list<record>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list<record>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list<record>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_set_name: (encode-path-segment $attribute_set_name)} | format pattern "/V1/products/media/types/{attribute_set_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/options
#
# POST /V1/products/options
# operationId: catalogProductCustomOptionRepositoryV1SavePost
# --option shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
export def "v1-products-options create-catalog-custom-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
]: any -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/options")
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/options/types
#
# GET /V1/products/options/types
# operationId: catalogProductCustomOptionTypeListV1GetItemsGet
export def "v1-products-options-types list-catalog-custom-get-items-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, group: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/options/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/options/{optionId}
#
# PUT /V1/products/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1SavePut
# --option shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
export def "v1-products-options update-catalog-custom-repository-save" [
  option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  option: record # shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
]: any -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({option_id: (encode-path-segment $option_id)} | format pattern "/V1/products/options/{option_id}"))
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/special-price
#
# POST /V1/products/special-price
# operationId: catalogSpecialPriceStorageV1UpdatePost
# --prices item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
export def "v1-products-special-price update-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/special-price-delete
#
# POST /V1/products/special-price-delete
# operationId: catalogSpecialPriceStorageV1DeletePost
# --prices item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
export def "v1-products-special-price-delete create-catalog-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price-delete")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/special-price-information
#
# POST /V1/products/special-price-information
# operationId: catalogSpecialPriceStorageV1GetPost
export def "v1-products-special-price-information get-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  skus: list<string>
]: any -> table<extension_attributes: record, price: float, price_from: string, price_to: string, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price-information")
  let req_body = {"skus": $skus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/tier-prices
#
# POST /V1/products/tier-prices
# operationId: catalogTierPriceStorageV1UpdatePost
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices update-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/tier-prices
#
# PUT /V1/products/tier-prices
# operationId: catalogTierPriceStorageV1ReplacePut
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices update-catalog-storage-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/tier-prices-delete
#
# POST /V1/products/tier-prices-delete
# operationId: catalogTierPriceStorageV1DeletePost
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices-delete create-catalog-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices-delete")
  let req_body = {"prices": $prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/tier-prices-information
#
# POST /V1/products/tier-prices-information
# operationId: catalogTierPriceStorageV1GetPost
export def "v1-products-tier-prices-information get-catalog-storage-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  skus: list<string>
]: any -> table<customer_group: string, extension_attributes: record, price: float, price_type: string, quantity: float, sku: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices-information")
  let req_body = {"skus": $skus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/types
#
# GET /V1/products/types
# operationId: catalogProductTypeListV1GetProductTypesGet
export def "v1-products-types list-catalog-get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, label: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{productSku}/stockItems/{itemId}
#
# PUT /V1/products/{productSku}/stockItems/{itemId}
# operationId: catalogInventoryStockRegistryV1UpdateStockItemBySkuPut
# --stockItem shape: {backorders: int, enable_qty_increments: bool, extension_attributes?: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id?: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id?: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id?: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, ... (6 more fields)}
export def "v1-products-stock-items update-catalog-inventory-registry-by-sku-update" [
  product_sku: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  stock_item: record # Interface StockItem — shape: {backorders: int, enable_qty_increments: bool, extension_attributes?: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id?: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id?: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id?: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, ... (6 more fields)}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_sku: (encode-path-segment $product_sku), item_id: (encode-path-segment $item_id)} | format pattern "/V1/products/{product_sku}/stockItems/{item_id}"))
  let req_body = {"stockItem": $stock_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}
#
# DELETE /V1/products/{sku}
# operationId: catalogProductRepositoryV1DeleteByIdDelete
export def "v1-products delete-catalog-repository-by-delete" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}
#
# GET /V1/products/{sku}
# operationId: catalogProductRepositoryV1GetGet
export def "v1-products get-catalog-repository-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --edit-mode: oneof<nothing, bool>
  --store-id: int
  --force-reload: oneof<nothing, bool>
]: nothing -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editMode" $edit_mode "scalar") (serialize-qp "storeId" $store_id "scalar") (serialize-qp "forceReload" $force_reload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}
#
# PUT /V1/products/{sku}
# operationId: catalogProductRepositoryV1SavePut
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-products update-catalog-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
  --save-options: oneof<nothing, bool>
]: any -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}"))
  let req_body = {"product": $product, "saveOptions": $save_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/downloadable-links
#
# GET /V1/products/{sku}/downloadable-links
# operationId: downloadableLinkRepositoryV1GetListGet
export def "v1-products-downloadable-links get-repository-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, id: int, is_shareable: int, link_file: string, link_file_content: record<extension_attributes: record, file_data: string, name: string>, link_type: string, link_url: string, number_of_downloads: int, price: float, sample_file: string, sample_file_content: record<extension_attributes: record, file_data: string, name: string>, sample_type: string, sample_url: string, sort_order: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/downloadable-links"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/downloadable-links
#
# POST /V1/products/{sku}/downloadable-links
# operationId: downloadableLinkRepositoryV1SavePost
# --link shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
export def "v1-products-downloadable-links create-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-global-scope-content: oneof<nothing, bool>
  link: record # shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/downloadable-links"))
  let req_body = {"isGlobalScopeContent": $is_global_scope_content, "link": $link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/downloadable-links/samples
#
# GET /V1/products/{sku}/downloadable-links/samples
# operationId: downloadableSampleRepositoryV1GetListGet
export def "v1-products-downloadable-links-samples get-repository-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, id: int, sample_file: string, sample_file_content: record<extension_attributes: record, file_data: string, name: string>, sample_type: string, sample_url: string, sort_order: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/downloadable-links/samples"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/downloadable-links/samples
#
# POST /V1/products/{sku}/downloadable-links/samples
# operationId: downloadableSampleRepositoryV1SavePost
# --sample shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
export def "v1-products-downloadable-links-samples create-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-global-scope-content: oneof<nothing, bool>
  sample: record # shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/downloadable-links/samples"))
  let req_body = {"isGlobalScopeContent": $is_global_scope_content, "sample": $sample} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/downloadable-links/samples/{id}
#
# PUT /V1/products/{sku}/downloadable-links/samples/{id}
# operationId: downloadableSampleRepositoryV1SavePut
# --sample shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
export def "v1-products-downloadable-links-samples update-repository-save" [
  sku: string
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
  --is-global-scope-content: oneof<nothing, bool>
  sample: record # shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/products/{sku}/downloadable-links/samples/{id}"))
  let req_body = {"isGlobalScopeContent": $is_global_scope_content, "sample": $sample} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/downloadable-links/{id}
#
# PUT /V1/products/{sku}/downloadable-links/{id}
# operationId: downloadableLinkRepositoryV1SavePut
# --link shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
export def "v1-products-downloadable-links update-repository-save" [
  sku: string
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
  --is-global-scope-content: oneof<nothing, bool>
  link: record # shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), id: (encode-path-segment $id)} | format pattern "/V1/products/{sku}/downloadable-links/{id}"))
  let req_body = {"isGlobalScopeContent": $is_global_scope_content, "link": $link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/group-prices/{customerGroupId}/tiers
#
# GET /V1/products/{sku}/group-prices/{customerGroupId}/tiers
# operationId: catalogProductTierPriceManagementV1GetListGet
export def "v1-products-group-prices-tiers get-catalog-management-list-get" [
  sku: string
  customer_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<customer_group_id: int, extension_attributes: record<percentage_value: float, website_id: int>, qty: float, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), customer_group_id: (encode-path-segment $customer_group_id)} | format pattern "/V1/products/{sku}/group-prices/{customer_group_id}/tiers"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/group-prices/{customerGroupId}/tiers/{qty}
#
# DELETE /V1/products/{sku}/group-prices/{customerGroupId}/tiers/{qty}
# operationId: catalogProductTierPriceManagementV1RemoveDelete
export def "v1-products-group-prices-tiers delete-catalog-management-delete" [
  sku: string
  customer_group_id: string
  qty: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), customer_group_id: (encode-path-segment $customer_group_id), qty: (encode-path-segment $qty)} | format pattern "/V1/products/{sku}/group-prices/{customer_group_id}/tiers/{qty}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/group-prices/{customerGroupId}/tiers/{qty}/price/{price}
#
# POST /V1/products/{sku}/group-prices/{customerGroupId}/tiers/{qty}/price/{price}
# operationId: catalogProductTierPriceManagementV1AddPost
export def "v1-products-group-prices-tiers-price create-catalog-management-create" [
  sku: string
  customer_group_id: string
  qty: float
  price: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), customer_group_id: (encode-path-segment $customer_group_id), qty: (encode-path-segment $qty), price: (encode-path-segment $price)} | format pattern "/V1/products/{sku}/group-prices/{customer_group_id}/tiers/{qty}/price/{price}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/links
#
# POST /V1/products/{sku}/links
# operationId: catalogProductLinkManagementV1SetProductLinksPost
# --items item shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
export def "v1-products-links update-catalog-management-create" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  items: list # item shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/links"))
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/links
#
# PUT /V1/products/{sku}/links
# operationId: catalogProductLinkRepositoryV1SavePut
# --entity shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
export def "v1-products-links update-catalog-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/links"))
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/links/{type}
#
# GET /V1/products/{sku}/links/{type}
# operationId: catalogProductLinkManagementV1GetLinkedItemsByTypeGet
export def "v1-products-links get-catalog-management-linked-items-by-get" [
  sku: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<qty: float>, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), type: (encode-path-segment $type)} | format pattern "/V1/products/{sku}/links/{type}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/links/{type}/{linkedProductSku}
#
# DELETE /V1/products/{sku}/links/{type}/{linkedProductSku}
# operationId: catalogProductLinkRepositoryV1DeleteByIdDelete
export def "v1-products-links delete-catalog-repository-by-delete" [
  sku: string
  type: string
  linked_product_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), type: (encode-path-segment $type), linked_product_sku: (encode-path-segment $linked_product_sku)} | format pattern "/V1/products/{sku}/links/{type}/{linked_product_sku}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/media
#
# GET /V1/products/{sku}/media
# operationId: catalogProductAttributeMediaGalleryManagementV1GetListGet
export def "v1-products-media get-catalog-attribute-gallery-management-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<content: record<base64_encoded_data: string, name: string, type: string>, disabled: bool, extension_attributes: record<video_content: record>, file: string, id: int, label: string, media_type: string, position: int, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/media"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/media
#
# POST /V1/products/{sku}/media
# operationId: catalogProductAttributeMediaGalleryManagementV1CreatePost
# --entry shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list<string>}
export def "v1-products-media create-catalog-attribute-gallery-management-create" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entry: record # shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list<string>}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/media"))
  let req_body = {"entry": $entry} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/media/{entryId}
#
# DELETE /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1RemoveDelete
export def "v1-products-media delete-catalog-attribute-gallery-management-delete" [
  sku: string
  entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), entry_id: (encode-path-segment $entry_id)} | format pattern "/V1/products/{sku}/media/{entry_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/media/{entryId}
#
# GET /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1GetGet
export def "v1-products-media get-catalog-attribute-gallery-management-get" [
  sku: string
  entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<content: record<base64_encoded_data: string, name: string, type: string>, disabled: bool, extension_attributes: record<video_content: record<media_type: string, video_description: string, video_metadata: string, video_provider: string, video_title: string, video_url: string>>, file: string, id: int, label: string, media_type: string, position: int, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), entry_id: (encode-path-segment $entry_id)} | format pattern "/V1/products/{sku}/media/{entry_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/media/{entryId}
#
# PUT /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1UpdatePut
# --entry shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list<string>}
export def "v1-products-media update-catalog-attribute-gallery-management-update" [
  sku: string
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entry: record # shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list<string>}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), entry_id: (encode-path-segment $entry_id)} | format pattern "/V1/products/{sku}/media/{entry_id}"))
  let req_body = {"entry": $entry} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/options
#
# GET /V1/products/{sku}/options
# operationId: catalogProductCustomOptionRepositoryV1GetListGet
export def "v1-products-options get-catalog-custom-repository-list-get" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/options"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/options/{optionId}
#
# DELETE /V1/products/{sku}/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1DeleteByIdentifierDelete
export def "v1-products-options delete-catalog-custom-repository-by-identifier-delete" [
  sku: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id)} | format pattern "/V1/products/{sku}/options/{option_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/options/{optionId}
#
# GET /V1/products/{sku}/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1GetGet
export def "v1-products-options get-catalog-custom-repository-get" [
  sku: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option_id: (encode-path-segment $option_id)} | format pattern "/V1/products/{sku}/options/{option_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# products/{sku}/websites
#
# POST /V1/products/{sku}/websites
# operationId: catalogProductWebsiteLinkRepositoryV1SavePost
# --productWebsiteLink shape: {sku: string, website_id: int}
export def "v1-products-websites create-catalog-link-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product_website_link: record # shape: {sku: string, website_id: int}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/websites"))
  let req_body = {"productWebsiteLink": $product_website_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/websites
#
# PUT /V1/products/{sku}/websites
# operationId: catalogProductWebsiteLinkRepositoryV1SavePut
# --productWebsiteLink shape: {sku: string, website_id: int}
export def "v1-products-websites update-catalog-link-repository-save" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  product_website_link: record # shape: {sku: string, website_id: int}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/V1/products/{sku}/websites"))
  let req_body = {"productWebsiteLink": $product_website_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# products/{sku}/websites/{websiteId}
#
# DELETE /V1/products/{sku}/websites/{websiteId}
# operationId: catalogProductWebsiteLinkRepositoryV1DeleteByIdDelete
export def "v1-products-websites delete-catalog-link-repository-by-delete" [
  sku: string
  website_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), website_id: (encode-path-segment $website_id)} | format pattern "/V1/products/{sku}/websites/{website_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# requisition_lists
#
# POST /V1/requisition_lists
# operationId: requisitionListRequisitionListRepositoryV1SavePost
# --requisitionList shape: {customer_id: int, description: string, extension_attributes?: record, id: int, items: list, name: string, updated_at: string}
export def "v1-requisition-lists create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  requisition_list: record # Interface RequisitionListInterface — shape: {customer_id: int, description: string, extension_attributes?: record, id: int, items: list, name: string, updated_at: string}
]: any -> record<customer_id: int, description: string, extension_attributes: record, id: int, items: table<added_at: string, extension_attributes: record, id: int, options: list, qty: float, requisition_list_id: int, sku: string, store_id: int>, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/requisition_lists")
  let req_body = {"requisitionList": $requisition_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns
#
# GET /V1/returns
# operationId: rmaRmaManagementV1SearchGet
export def "v1-returns list-rma-rma-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<comments: list, custom_attributes: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/returns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns
#
# POST /V1/returns
# operationId: rmaRmaManagementV1SaveRmaPost
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns create-rma-rma-management-save-rma" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  rma_data_object: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/returns")
  let req_body = {"rmaDataObject": $rma_data_object} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns/{id}
#
# DELETE /V1/returns/{id}
# operationId: rmaRmaRepositoryV1DeleteDelete
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns delete-rma-rma-repository-delete" [
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
  rma_data_object: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}"))
  let req_body = {"rmaDataObject": $rma_data_object} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns/{id}
#
# GET /V1/returns/{id}
# operationId: rmaRmaRepositoryV1GetGet
export def "v1-returns get-rma-rma-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns/{id}
#
# PUT /V1/returns/{id}
# operationId: rmaRmaManagementV1SaveRmaPut
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns update-rma-rma-management-save-rma" [
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
  rma_data_object: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}"))
  let req_body = {"rmaDataObject": $rma_data_object} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns/{id}/comments
#
# GET /V1/returns/{id}/comments
# operationId: rmaCommentManagementV1CommentsListGet
export def "v1-returns-comments list-rma-management-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns/{id}/comments
#
# POST /V1/returns/{id}/comments
# operationId: rmaCommentManagementV1AddCommentPost
# --data shape: {admin: bool, comment: string, created_at: string, custom_attributes?: list, customer_notified: bool, entity_id: int, extension_attributes?: record, rma_entity_id: int, status: string, visible_on_front: bool}
export def "v1-returns-comments create-rma-management-create" [
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
  data: record # Interface CommentInterface — shape: {admin: bool, comment: string, created_at: string, custom_attributes?: list, customer_notified: bool, entity_id: int, extension_attributes?: record, rma_entity_id: int, status: string, visible_on_front: bool}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}/comments"))
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns/{id}/labels
#
# GET /V1/returns/{id}/labels
# operationId: rmaTrackManagementV1GetShippingLabelPdfGet
export def "v1-returns-labels get-rma-track-management-shipping-pdf-get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}/labels"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns/{id}/tracking-numbers
#
# GET /V1/returns/{id}/tracking-numbers
# operationId: rmaTrackManagementV1GetTracksGet
export def "v1-returns-tracking-numbers get-rma-track-management-tracks-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}/tracking-numbers"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns/{id}/tracking-numbers
#
# POST /V1/returns/{id}/tracking-numbers
# operationId: rmaTrackManagementV1AddTrackPost
# --track shape: {carrier_code: string, carrier_title: string, entity_id: int, extension_attributes?: record, rma_entity_id: int, track_number: string}
export def "v1-returns-tracking-numbers create-rma-track-management-track-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  track: record # Interface TrackInterface — shape: {carrier_code: string, carrier_title: string, entity_id: int, extension_attributes?: record, rma_entity_id: int, track_number: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/returns/{id}/tracking-numbers"))
  let req_body = {"track": $track} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns/{id}/tracking-numbers/{trackId}
#
# DELETE /V1/returns/{id}/tracking-numbers/{trackId}
# operationId: rmaTrackManagementV1RemoveTrackByIdDelete
export def "v1-returns-tracking-numbers delete-rma-track-management-track-by-delete" [
  id: int
  track_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), track_id: (encode-path-segment $track_id)} | format pattern "/V1/returns/{id}/tracking-numbers/{track_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata
#
# GET /V1/returnsAttributeMetadata
# operationId: rmaRmaAttributesManagementV1GetAllAttributesMetadataGet
export def "v1-returns-attribute-metadata get-rma-rma-management-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/returnsAttributeMetadata")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/custom
#
# GET /V1/returnsAttributeMetadata/custom
# operationId: rmaRmaAttributesManagementV1GetCustomAttributesMetadataGet
export def "v1-returns-attribute-metadata-custom get-rma-rma-management-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-object-class-name: string # Data object class name
]: nothing -> table<attribute_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataObjectClassName" $data_object_class_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/returnsAttributeMetadata/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/form/{formCode}
#
# GET /V1/returnsAttributeMetadata/form/{formCode}
# operationId: rmaRmaAttributesManagementV1GetAttributesGet
export def "v1-returns-attribute-metadata-form get-rma-rma-management-get" [
  form_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({form_code: (encode-path-segment $form_code)} | format pattern "/V1/returnsAttributeMetadata/form/{form_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/{attributeCode}
#
# GET /V1/returnsAttributeMetadata/{attributeCode}
# operationId: rmaRmaAttributesManagementV1GetAttributeMetadataGet
export def "v1-returns-attribute-metadata get-rma-rma-management-get" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: (encode-path-segment $attribute_code)} | format pattern "/V1/returnsAttributeMetadata/{attribute_code}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# reward/mine/use-reward
#
# POST /V1/reward/mine/use-reward
# operationId: rewardRewardManagementV1SetPost
export def "v1-reward-mine-use-reward update-management-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/reward/mine/use-reward")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# salesRules
#
# POST /V1/salesRules
# operationId: salesRuleRuleRepositoryV1SavePost
# --rule shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list<int>, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list<int>, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, ... (6 more fields)}
export def "v1-sales-rules create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  rule: record # Interface RuleInterface — shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list<int>, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list<int>, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, ... (6 more fields)}
]: any -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/salesRules")
  let req_body = {"rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# salesRules/search
#
# GET /V1/salesRules/search
# operationId: salesRuleRuleRepositoryV1GetListGet
export def "v1-sales-rules-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<action_condition: record, apply_to_shipping: bool, condition: record, coupon_type: string, customer_group_ids: list, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: list, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/salesRules/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# DELETE /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1DeleteByIdDelete
export def "v1-sales-rules delete-repository-by-delete" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/V1/salesRules/{rule_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# GET /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1GetByIdGet
export def "v1-sales-rules get-repository-by-get" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/V1/salesRules/{rule_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# PUT /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1SavePut
# --rule shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list<int>, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list<int>, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, ... (6 more fields)}
export def "v1-sales-rules update-repository-save" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  rule: record # Interface RuleInterface — shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list<int>, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list<int>, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, ... (6 more fields)}
]: any -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/V1/salesRules/{rule_id}"))
  let req_body = {"rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# search
#
# GET /V1/search
# operationId: searchV1SearchGet
export def "v1-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-request-name: string
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<aggregations: record<bucket_names: list<string>, buckets: list<record>>, items: table<custom_attributes: list, id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, request_name: string, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[requestName]" $search_criteria_request_name "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog
#
# POST /V1/sharedCatalog
# operationId: sharedCatalogSharedCatalogRepositoryV1SavePost
# --sharedCatalog shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
export def "v1-shared-catalog create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  shared_catalog: record # SharedCatalogInterface interface. — shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/sharedCatalog")
  let req_body = {"sharedCatalog": $shared_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/
#
# GET /V1/sharedCatalog/
# operationId: sharedCatalogSharedCatalogRepositoryV1GetListGet
export def "v1-shared-catalog get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<created_at: string, created_by: int, customer_group_id: int, description: string, id: int, name: string, store_id: int, tax_class_id: int, type: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/sharedCatalog/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}
#
# PUT /V1/sharedCatalog/{id}
# operationId: sharedCatalogSharedCatalogRepositoryV1SavePut
# --sharedCatalog shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
export def "v1-shared-catalog update-repository-save" [
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
  shared_catalog: record # SharedCatalogInterface interface. — shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}"))
  let req_body = {"sharedCatalog": $shared_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{id}/assignCategories
#
# POST /V1/sharedCatalog/{id}/assignCategories
# operationId: sharedCatalogCategoryManagementV1AssignCategoriesPost
# --categories item shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-shared-catalog-assign-categories create-category-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  categories: list # item shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/assignCategories"))
  let req_body = {"categories": $categories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{id}/assignProducts
#
# POST /V1/sharedCatalog/{id}/assignProducts
# operationId: sharedCatalogProductManagementV1AssignProductsPost
# --products item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-shared-catalog-assign-products create-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  products: list # item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/assignProducts"))
  let req_body = {"products": $products} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{id}/categories
#
# GET /V1/sharedCatalog/{id}/categories
# operationId: sharedCatalogCategoryManagementV1GetCategoriesGet
export def "v1-shared-catalog-categories get-category-management-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/categories"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}/products
#
# GET /V1/sharedCatalog/{id}/products
# operationId: sharedCatalogProductManagementV1GetProductsGet
export def "v1-shared-catalog-products get-management-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/products"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}/unassignCategories
#
# POST /V1/sharedCatalog/{id}/unassignCategories
# operationId: sharedCatalogCategoryManagementV1UnassignCategoriesPost
# --categories item shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-shared-catalog-unassign-categories create-category-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  categories: list # item shape: {available_sort_by?: list<string>, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/unassignCategories"))
  let req_body = {"categories": $categories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{id}/unassignProducts
#
# POST /V1/sharedCatalog/{id}/unassignProducts
# operationId: sharedCatalogProductManagementV1UnassignProductsPost
# --products item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-shared-catalog-unassign-products create-management" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  products: list # item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/sharedCatalog/{id}/unassignProducts"))
  let req_body = {"products": $products} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{sharedCatalogId}
#
# DELETE /V1/sharedCatalog/{sharedCatalogId}
# operationId: sharedCatalogSharedCatalogRepositoryV1DeleteByIdDelete
export def "v1-shared-catalog delete-repository-by-delete" [
  shared_catalog_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shared_catalog_id: (encode-path-segment $shared_catalog_id)} | format pattern "/V1/sharedCatalog/{shared_catalog_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}
#
# GET /V1/sharedCatalog/{sharedCatalogId}
# operationId: sharedCatalogSharedCatalogRepositoryV1GetGet
export def "v1-shared-catalog get-repository-get" [
  shared_catalog_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, created_by: int, customer_group_id: int, description: string, id: int, name: string, store_id: int, tax_class_id: int, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shared_catalog_id: (encode-path-segment $shared_catalog_id)} | format pattern "/V1/sharedCatalog/{shared_catalog_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}/assignCompanies
#
# POST /V1/sharedCatalog/{sharedCatalogId}/assignCompanies
# operationId: sharedCatalogCompanyManagementV1AssignCompaniesPost
# --companies item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-shared-catalog-assign-companies create-company-management" [
  shared_catalog_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  companies: list # item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shared_catalog_id: (encode-path-segment $shared_catalog_id)} | format pattern "/V1/sharedCatalog/{shared_catalog_id}/assignCompanies"))
  let req_body = {"companies": $companies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# sharedCatalog/{sharedCatalogId}/companies
#
# GET /V1/sharedCatalog/{sharedCatalogId}/companies
# operationId: sharedCatalogCompanyManagementV1GetCompaniesGet
export def "v1-shared-catalog-companies get-company-management-get" [
  shared_catalog_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shared_catalog_id: (encode-path-segment $shared_catalog_id)} | format pattern "/V1/sharedCatalog/{shared_catalog_id}/companies"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}/unassignCompanies
#
# POST /V1/sharedCatalog/{sharedCatalogId}/unassignCompanies
# operationId: sharedCatalogCompanyManagementV1UnassignCompaniesPost
# --companies item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-shared-catalog-unassign-companies create-company-management" [
  shared_catalog_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  companies: list # item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list<string>, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shared_catalog_id: (encode-path-segment $shared_catalog_id)} | format pattern "/V1/sharedCatalog/{shared_catalog_id}/unassignCompanies"))
  let req_body = {"companies": $companies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# shipment/
#
# POST /V1/shipment/
# operationId: salesShipmentRepositoryV1SavePost
# --entity shape: {billing_address_id?: int, comments: list, created_at?: string, customer_id?: int, email_sent?: int, entity_id?: int, extension_attributes?: record, increment_id?: string, items: list, order_id: int, packages?: list, shipment_status?: int, shipping_address_id?: int, shipping_label?: string, store_id?: int, total_qty?: float, total_weight?: float, tracks: list, updated_at?: string}
export def "v1-shipment create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Shipment interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. — shape: {billing_address_id?: int, comments: list, created_at?: string, customer_id?: int, email_sent?: int, entity_id?: int, extension_attributes?: record, increment_id?: string, items: list, order_id: int, packages?: list, shipment_status?: int, shipping_address_id?: int, shipping_label?: string, store_id?: int, total_qty?: float, total_weight?: float, tracks: list, updated_at?: string}
]: any -> record<billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record<ext_location_id: string, ext_return_shipment_id: string, ext_shipment_id: string, ext_tracking_reference: string, ext_tracking_url: string>, increment_id: string, items: table<additional_data: string, description: string, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, product_id: int, qty: float, row_total: float, sku: string, weight: float>, order_id: int, packages: table<extension_attributes: record>, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: table<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/shipment/")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# shipment/track
#
# POST /V1/shipment/track
# operationId: salesShipmentTrackRepositoryV1SavePost
# --entity shape: {carrier_code: string, created_at?: string, description: string, entity_id?: int, extension_attributes?: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at?: string, weight: float}
export def "v1-shipment-track create-sales-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  entity: record # Shipment track interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. Merchants and customers can track shipments. — shape: {carrier_code: string, created_at?: string, description: string, entity_id?: int, extension_attributes?: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at?: string, weight: float}
]: any -> record<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/shipment/track")
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# shipment/track/{id}
#
# DELETE /V1/shipment/track/{id}
# operationId: salesShipmentTrackRepositoryV1DeleteByIdDelete
export def "v1-shipment-track delete-sales-repository-by-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/track/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# shipment/{id}
#
# GET /V1/shipment/{id}
# operationId: salesShipmentRepositoryV1GetGet
export def "v1-shipment get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record<ext_location_id: string, ext_return_shipment_id: string, ext_shipment_id: string, ext_tracking_reference: string, ext_tracking_url: string>, increment_id: string, items: table<additional_data: string, description: string, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, product_id: int, qty: float, row_total: float, sku: string, weight: float>, order_id: int, packages: table<extension_attributes: record>, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: table<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# shipment/{id}/comments
#
# GET /V1/shipment/{id}/comments
# operationId: salesShipmentManagementV1GetCommentsListGet
export def "v1-shipment-comments get-sales-management-list-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# shipment/{id}/comments
#
# POST /V1/shipment/{id}/comments
# operationId: salesShipmentCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-shipment-comments create-sales-repository-save" [
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
  entity: record # Shipment comment interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. A shipment document can contain comments. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/{id}/comments"))
  let req_body = {"entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# shipment/{id}/emails
#
# POST /V1/shipment/{id}/emails
# operationId: salesShipmentManagementV1NotifyPost
export def "v1-shipment-emails notify-sales-management-create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/{id}/emails"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# shipment/{id}/label
#
# GET /V1/shipment/{id}/label
# operationId: salesShipmentManagementV1GetLabelGet
export def "v1-shipment-label get-sales-management-get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/shipment/{id}/label"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# shipments
#
# GET /V1/shipments
# operationId: salesShipmentRepositoryV1GetListGet
export def "v1-shipments get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<billing_address_id: int, comments: list, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record, increment_id: string, items: list, order_id: int, packages: list, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: list, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/shipments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# stockItems/lowStock/
#
# GET /V1/stockItems/lowStock/
# operationId: catalogInventoryStockRegistryV1GetLowStockItemsGet
export def "v1-stock-items-low-stock get-catalog-inventory-registry-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scope-id: int
  --qty: float
  --current-page: int
  --page-size: int
]: nothing -> record<items: table<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, search_criteria: record<criteria_list: list<record>, filters: list<string>, limit: list<string>, mapper_interface_name: string, orders: list<string>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scope_id "scalar") (serialize-qp "qty" $qty "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/stockItems/lowStock/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# stockItems/{productSku}
#
# GET /V1/stockItems/{productSku}
# operationId: catalogInventoryStockRegistryV1GetStockItemBySkuGet
export def "v1-stock-items get-catalog-inventory-registry-by-sku-get" [
  product_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scope-id: int
]: nothing -> record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scope_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_sku: (encode-path-segment $product_sku)} | format pattern "/V1/stockItems/{product_sku}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# stockStatuses/{productSku}
#
# GET /V1/stockStatuses/{productSku}
# operationId: catalogInventoryStockRegistryV1GetStockStatusBySkuGet
export def "v1-stock-statuses get-catalog-inventory-registry-status-by-sku-get" [
  product_sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scope-id: int
]: nothing -> record<extension_attributes: record, product_id: int, qty: int, stock_id: int, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, stock_status: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scope_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_sku: (encode-path-segment $product_sku)} | format pattern "/V1/stockStatuses/{product_sku}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# store/storeConfigs
#
# GET /V1/store/storeConfigs
# operationId: storeStoreConfigManagerV1GetStoreConfigsGet
export def "v1-store-store-configs get-manager-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --store-codes: list<string>
]: nothing -> table<base_currency_code: string, base_link_url: string, base_media_url: string, base_static_url: string, base_url: string, code: string, default_display_currency_code: string, extension_attributes: record, id: int, locale: string, secure_base_link_url: string, secure_base_media_url: string, secure_base_static_url: string, secure_base_url: string, timezone: string, website_id: int, weight_unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeCodes" $store_codes "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/store/storeConfigs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# store/storeGroups
#
# GET /V1/store/storeGroups
# operationId: storeGroupRepositoryV1GetListGet
export def "v1-store-store-groups get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, default_store_id: int, extension_attributes: record, id: int, name: string, root_category_id: int, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/storeGroups")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# store/storeViews
#
# GET /V1/store/storeViews
# operationId: storeStoreRepositoryV1GetListGet
export def "v1-store-store-views get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, id: int, name: string, store_group_id: int, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/storeViews")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# store/websites
#
# GET /V1/store/websites
# operationId: storeWebsiteRepositoryV1GetListGet
export def "v1-store-websites get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, default_group_id: int, extension_attributes: record, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/websites")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxClasses
#
# POST /V1/taxClasses
# operationId: taxTaxClassRepositoryV1SavePost
# --taxClass shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
export def "v1-tax-classes create-class-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  tax_class: record # Tax class interface. — shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxClasses")
  let req_body = {"taxClass": $tax_class} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxClasses/search
#
# GET /V1/taxClasses/search
# operationId: taxTaxClassRepositoryV1GetListGet
export def "v1-tax-classes-search get-class-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<class_id: int, class_name: string, class_type: string, extension_attributes: record>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxClasses/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxClasses/{classId}
#
# PUT /V1/taxClasses/{classId}
# operationId: taxTaxClassRepositoryV1SavePut
# --taxClass shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
export def "v1-tax-classes update-class-repository-save" [
  class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  tax_class: record # Tax class interface. — shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({class_id: (encode-path-segment $class_id)} | format pattern "/V1/taxClasses/{class_id}"))
  let req_body = {"taxClass": $tax_class} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxClasses/{taxClassId}
#
# DELETE /V1/taxClasses/{taxClassId}
# operationId: taxTaxClassRepositoryV1DeleteByIdDelete
export def "v1-tax-classes delete-class-repository-by-delete" [
  tax_class_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tax_class_id: (encode-path-segment $tax_class_id)} | format pattern "/V1/taxClasses/{tax_class_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxClasses/{taxClassId}
#
# GET /V1/taxClasses/{taxClassId}
# operationId: taxTaxClassRepositoryV1GetGet
export def "v1-tax-classes get-class-repository-get" [
  tax_class_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<class_id: int, class_name: string, class_type: string, extension_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tax_class_id: (encode-path-segment $tax_class_id)} | format pattern "/V1/taxClasses/{tax_class_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRates
#
# POST /V1/taxRates
# operationId: taxTaxRateRepositoryV1SavePost
# --taxRate shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
export def "v1-tax-rates create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  tax_rate: record # Tax rate interface. — shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
]: any -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRates")
  let req_body = {"taxRate": $tax_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxRates
#
# PUT /V1/taxRates
# operationId: taxTaxRateRepositoryV1SavePut
# --taxRate shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
export def "v1-tax-rates update-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  tax_rate: record # Tax rate interface. — shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
]: any -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRates")
  let req_body = {"taxRate": $tax_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxRates/search
#
# GET /V1/taxRates/search
# operationId: taxTaxRateRepositoryV1GetListGet
export def "v1-tax-rates-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: list, zip_from: int, zip_is_range: int, zip_to: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxRates/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRates/{rateId}
#
# DELETE /V1/taxRates/{rateId}
# operationId: taxTaxRateRepositoryV1DeleteByIdDelete
export def "v1-tax-rates delete-repository-by-delete" [
  rate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/V1/taxRates/{rate_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRates/{rateId}
#
# GET /V1/taxRates/{rateId}
# operationId: taxTaxRateRepositoryV1GetGet
export def "v1-tax-rates get-repository-get" [
  rate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/V1/taxRates/{rate_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRules
#
# POST /V1/taxRules
# operationId: taxTaxRuleRepositoryV1SavePost
# --rule shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>}
export def "v1-tax-rules create-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  rule: record # Tax rule interface. — shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>}
]: any -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRules")
  let req_body = {"rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxRules
#
# PUT /V1/taxRules
# operationId: taxTaxRuleRepositoryV1SavePut
# --rule shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>}
export def "v1-tax-rules update-repository-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  rule: record # Tax rule interface. — shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>}
]: any -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRules")
  let req_body = {"rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# taxRules/search
#
# GET /V1/taxRules/search
# operationId: taxTaxRuleRepositoryV1GetListGet
export def "v1-tax-rules-search get-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<calculate_subtotal: bool, code: string, customer_tax_class_ids: list, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxRules/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRules/{ruleId}
#
# DELETE /V1/taxRules/{ruleId}
# operationId: taxTaxRuleRepositoryV1DeleteByIdDelete
export def "v1-tax-rules delete-repository-by-delete" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/V1/taxRules/{rule_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# taxRules/{ruleId}
#
# GET /V1/taxRules/{ruleId}
# operationId: taxTaxRuleRepositoryV1GetGet
export def "v1-tax-rules get-repository-get" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/V1/taxRules/{rule_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# team/
#
# GET /V1/team/
# operationId: companyTeamRepositoryV1GetListGet
export def "v1-team get-company-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<custom_attributes: list, description: string, extension_attributes: record, id: int, name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/team/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# team/{companyId}
#
# POST /V1/team/{companyId}
# operationId: companyTeamRepositoryV1CreatePost
# --team shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
export def "v1-team create-company-repository-create" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  team: record # Team interface — shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/V1/team/{company_id}"))
  let req_body = {"team": $team} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# team/{teamId}
#
# DELETE /V1/team/{teamId}
# operationId: companyTeamRepositoryV1DeleteByIdDelete
export def "v1-team delete-company-repository-by-delete" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/V1/team/{team_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# team/{teamId}
#
# GET /V1/team/{teamId}
# operationId: companyTeamRepositoryV1GetGet
export def "v1-team get-company-repository-get" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_attributes: table<attribute_code: string, value: string>, description: string, extension_attributes: record, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/V1/team/{team_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# team/{teamId}
#
# PUT /V1/team/{teamId}
# operationId: companyTeamRepositoryV1SavePut
# --team shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
export def "v1-team update-company-repository-save" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  team: record # Team interface — shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/V1/team/{team_id}"))
  let req_body = {"team": $team} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# temando/rma/{rmaId}/shipments
#
# PUT /V1/temando/rma/{rmaId}/shipments
# operationId: temandoShippingRmaRmaShipmentManagementV1AssignShipmentIdsPut
export def "v1-temando-rma-shipments assign-shipping-management-update" [
  rma_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  return_shipment_ids: list<string>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rma_id: (encode-path-segment $rma_id)} | format pattern "/V1/temando/rma/{rma_id}/shipments"))
  let req_body = {"returnShipmentIds": $return_shipment_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# transactions
#
# GET /V1/transactions
# operationId: salesTransactionRepositoryV1GetListGet
export def "v1-transactions get-sales-repository-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-criteria-filter-groups-0-filters-0-field: string # Field
  --search-criteria-filter-groups-0-filters-0-value: string # Value
  --search-criteria-filter-groups-0-filters-0-condition-type: string # Condition type
  --search-criteria-sort-orders-0-field: string # Sorting field.
  --search-criteria-sort-orders-0-direction: string # Sorting direction.
  --search-criteria-page-size: int # Page size.
  --search-criteria-current-page: int # Current page.
]: nothing -> record<items: table<additional_information: list, child_transactions: list, created_at: string, extension_attributes: record, is_closed: int, order_id: int, parent_id: int, parent_txn_id: string, payment_id: int, transaction_id: int, txn_id: string, txn_type: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $search_criteria_filter_groups_0_filters_0_field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $search_criteria_filter_groups_0_filters_0_value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $search_criteria_filter_groups_0_filters_0_condition_type "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $search_criteria_sort_orders_0_field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $search_criteria_sort_orders_0_direction "scalar") (serialize-qp "searchCriteria[pageSize]" $search_criteria_page_size "scalar") (serialize-qp "searchCriteria[currentPage]" $search_criteria_current_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/transactions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# transactions/{id}
#
# GET /V1/transactions/{id}
# operationId: salesTransactionRepositoryV1GetGet
export def "v1-transactions get-sales-repository-get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_information: list<string>, child_transactions: list<any>, created_at: string, extension_attributes: record, is_closed: int, order_id: int, parent_id: int, parent_txn_id: string, payment_id: int, transaction_id: int, txn_id: string, txn_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/V1/transactions/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# worldpay-guest-carts/{cartId}/payment-information
#
# POST /V1/worldpay-guest-carts/{cartId}/payment-information
# operationId: worldpayGuestPaymentInformationManagementProxyV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
export def "v1-worldpay-guest-carts-payment-information create-management-proxy-save-and-place-order" [
  cart_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --billing-address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list<string>, suffix?: string, telephone: string, vat_id?: string}
  email: string
  payment_method: record # Interface PaymentInterface — shape: {additional_data?: list<string>, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cart_id: (encode-path-segment $cart_id)} | format pattern "/V1/worldpay-guest-carts/{cart_id}/payment-information"))
  let req_body = {"billingAddress": $billing_address, "email": $email, "paymentMethod": $payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
