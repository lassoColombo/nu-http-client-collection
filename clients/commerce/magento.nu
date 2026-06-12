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

def base-url-completer [] { ["https://example.com/rest/default"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1-addresses customerAddressRepositoryV1DeleteByIdDelete" } } | get name | first)
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
export def "v1-addresses customerAddressRepositoryV1DeleteByIdDelete" [
  addressId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/addresses/($addressId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# amazon-billing-address/{amazonOrderReferenceId}
#
# PUT /V1/amazon-billing-address/{amazonOrderReferenceId}
# operationId: amazonPaymentAddressManagementV1GetBillingAddressPut
export def "v1-amazon-billing-address amazonPaymentAddressManagementV1GetBillingAddressPut" [
  amazonOrderReferenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressConsentToken: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/amazon-billing-address/($amazonOrderReferenceId)")
  let body = {addressConsentToken: $addressConsentToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# amazon-shipping-address/{amazonOrderReferenceId}
#
# PUT /V1/amazon-shipping-address/{amazonOrderReferenceId}
# operationId: amazonPaymentAddressManagementV1GetShippingAddressPut
export def "v1-amazon-shipping-address amazonPaymentAddressManagementV1GetShippingAddressPut" [
  amazonOrderReferenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressConsentToken: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/amazon-shipping-address/($amazonOrderReferenceId)")
  let body = {addressConsentToken: $addressConsentToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# amazon/order-ref
#
# DELETE /V1/amazon/order-ref
# operationId: amazonPaymentOrderInformationManagementV1RemoveOrderReferenceDelete
export def "v1-amazon-order-ref amazonPaymentOrderInformationManagementV1RemoveOrderReferenceDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/amazon/order-ref")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# analytics/link
#
# GET /V1/analytics/link
# operationId: analyticsLinkProviderV1GetGet
export def "v1-analytics-link analyticsLinkProviderV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<initialization_vector: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/analytics/link")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customer
#
# GET /V1/attributeMetadata/customer
# operationId: customerCustomerMetadataV1GetAllAttributesMetadataGet
export def "v1-attribute-metadata-customer customerCustomerMetadataV1GetAllAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/attributeMetadata/customer")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/attribute/{attributeCode}
#
# GET /V1/attributeMetadata/customer/attribute/{attributeCode}
# operationId: customerCustomerMetadataV1GetAttributeMetadataGet
export def "v1-attribute-metadata-customer-attribute customerCustomerMetadataV1GetAttributeMetadataGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/attributeMetadata/customer/attribute/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/custom
#
# GET /V1/attributeMetadata/customer/custom
# operationId: customerCustomerMetadataV1GetCustomAttributesMetadataGet
export def "v1-attribute-metadata-customer-custom customerCustomerMetadataV1GetCustomAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --dataInterfaceName: string
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataInterfaceName" $dataInterfaceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/attributeMetadata/customer/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customer/form/{formCode}
#
# GET /V1/attributeMetadata/customer/form/{formCode}
# operationId: customerCustomerMetadataV1GetAttributesGet
export def "v1-attribute-metadata-customer-form customerCustomerMetadataV1GetAttributesGet" [
  formCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/attributeMetadata/customer/form/($formCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress
#
# GET /V1/attributeMetadata/customerAddress
# operationId: customerAddressMetadataV1GetAllAttributesMetadataGet
export def "v1-attribute-metadata-customer-address customerAddressMetadataV1GetAllAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/attributeMetadata/customerAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/attribute/{attributeCode}
#
# GET /V1/attributeMetadata/customerAddress/attribute/{attributeCode}
# operationId: customerAddressMetadataV1GetAttributeMetadataGet
export def "v1-attribute-metadata-customer-address-attribute customerAddressMetadataV1GetAttributeMetadataGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/attributeMetadata/customerAddress/attribute/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/custom
#
# GET /V1/attributeMetadata/customerAddress/custom
# operationId: customerAddressMetadataV1GetCustomAttributesMetadataGet
export def "v1-attribute-metadata-customer-address-custom customerAddressMetadataV1GetCustomAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --dataInterfaceName: string
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataInterfaceName" $dataInterfaceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/attributeMetadata/customerAddress/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# attributeMetadata/customerAddress/form/{formCode}
#
# GET /V1/attributeMetadata/customerAddress/form/{formCode}
# operationId: customerAddressMetadataV1GetAttributesGet
export def "v1-attribute-metadata-customer-address-form customerAddressMetadataV1GetAttributesGet" [
  formCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/attributeMetadata/customerAddress/form/($formCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/detailed-status
#
# GET /V1/bulk/{bulkUuid}/detailed-status
# operationId: asynchronousOperationsBulkStatusV1GetBulkDetailedStatusGet
export def "v1-bulk-detailed-status asynchronousOperationsBulkStatusV1GetBulkDetailedStatusGet" [
  bulkUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<bulk_id: string, description: string, extension_attributes: record, operation_count: int, operations_list: table<bulk_uuid: string, error_code: int, extension_attributes: record, id: int, result_message: string, result_serialized_data: string, serialized_data: string, status: int, topic_name: string>, start_time: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bulk/($bulkUuid)/detailed-status")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/operation-status/{status}
#
# GET /V1/bulk/{bulkUuid}/operation-status/{status}
# operationId: asynchronousOperationsBulkStatusV1GetOperationsCountByBulkIdAndStatusGet
export def "v1-bulk-operation-status asynchronousOperationsBulkStatusV1GetOperationsCountByBulkIdAndStatusGet" [
  bulkUuid: string
  status: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bulk/($bulkUuid)/operation-status/($status)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bulk/{bulkUuid}/status
#
# GET /V1/bulk/{bulkUuid}/status
# operationId: asynchronousOperationsBulkStatusV1GetBulkShortStatusGet
export def "v1-bulk-status asynchronousOperationsBulkStatusV1GetBulkShortStatusGet" [
  bulkUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<bulk_id: string, description: string, extension_attributes: record, operation_count: int, operations_list: table<error_code: int, id: int, result_message: string, status: int>, start_time: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bulk/($bulkUuid)/status")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/options/add
#
# POST /V1/bundle-products/options/add
# operationId: bundleProductOptionManagementV1SavePost
# --option shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
export def "v1-bundle-products-options-add bundleProductOptionManagementV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/bundle-products/options/add")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# bundle-products/options/types
#
# GET /V1/bundle-products/options/types
# operationId: bundleProductOptionTypeListV1GetItemsGet
export def "v1-bundle-products-options-types bundleProductOptionTypeListV1GetItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/bundle-products/options/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/options/{optionId}
#
# PUT /V1/bundle-products/options/{optionId}
# operationId: bundleProductOptionManagementV1SavePut
# --option shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
export def "v1-bundle-products-options bundleProductOptionManagementV1SavePut" [
  optionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {extension_attributes?: record, option_id?: int, position?: int, product_links?: list, required?: bool, sku?: string, title?: string, type?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/options/($optionId)")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# bundle-products/{productSku}/children
#
# GET /V1/bundle-products/{productSku}/children
# operationId: bundleProductLinkManagementV1GetChildrenGet
export def "v1-bundle-products-children bundleProductLinkManagementV1GetChildrenGet" [
  productSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --optionId: int
]: nothing -> table<can_change_quantity: int, extension_attributes: record, id: string, is_default: bool, option_id: int, position: int, price: float, price_type: int, qty: float, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "optionId" $optionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/bundle-products/($productSku)/children" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/links/{id}
#
# PUT /V1/bundle-products/{sku}/links/{id}
# operationId: bundleProductLinkManagementV1SaveChildPut
# --linkedProduct shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
export def "v1-bundle-products-links bundleProductLinkManagementV1SaveChildPut" [
  sku: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  linkedProduct: record # Interface LinkInterface — shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/links/($id)")
  let body = {linkedProduct: $linkedProduct} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# bundle-products/{sku}/links/{optionId}
#
# POST /V1/bundle-products/{sku}/links/{optionId}
# operationId: bundleProductLinkManagementV1AddChildByProductSkuPost
# --linkedProduct shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
export def "v1-bundle-products-links bundleProductLinkManagementV1AddChildByProductSkuPost" [
  sku: string
  optionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  linkedProduct: record # Interface LinkInterface — shape: {can_change_quantity?: int, extension_attributes?: record, id?: string, is_default: bool, option_id?: int, position?: int, price: float, price_type: int, qty?: float, sku?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/links/($optionId)")
  let body = {linkedProduct: $linkedProduct} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# bundle-products/{sku}/options/all
#
# GET /V1/bundle-products/{sku}/options/all
# operationId: bundleProductOptionRepositoryV1GetListGet
export def "v1-bundle-products-options-all bundleProductOptionRepositoryV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, option_id: int, position: int, product_links: list<record>, required: bool, sku: string, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/options/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}
#
# DELETE /V1/bundle-products/{sku}/options/{optionId}
# operationId: bundleProductOptionRepositoryV1DeleteByIdDelete
export def "v1-bundle-products-options bundleProductOptionRepositoryV1DeleteByIdDelete" [
  sku: string
  optionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/options/($optionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}
#
# GET /V1/bundle-products/{sku}/options/{optionId}
# operationId: bundleProductOptionRepositoryV1GetGet
export def "v1-bundle-products-options bundleProductOptionRepositoryV1GetGet" [
  sku: string
  optionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, option_id: int, position: int, product_links: table<can_change_quantity: int, extension_attributes: record, id: string, is_default: bool, option_id: int, position: int, price: float, price_type: int, qty: float, sku: string>, required: bool, sku: string, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/options/($optionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# bundle-products/{sku}/options/{optionId}/children/{childSku}
#
# DELETE /V1/bundle-products/{sku}/options/{optionId}/children/{childSku}
# operationId: bundleProductLinkManagementV1RemoveChildDelete
export def "v1-bundle-products-options-children bundleProductLinkManagementV1RemoveChildDelete" [
  sku: string
  optionId: int
  childSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/bundle-products/($sku)/options/($optionId)/children/($childSku)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/
#
# POST /V1/carts/
# operationId: quoteCartManagementV1CreateEmptyCartPost
export def "v1-carts quoteCartManagementV1CreateEmptyCartPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/guest-carts/{cartId}/checkGiftCard/{giftCardCode}
#
# GET /V1/carts/guest-carts/{cartId}/checkGiftCard/{giftCardCode}
# operationId: giftCardAccountGuestGiftCardAccountManagementV1CheckGiftCardGet
export def "v1-carts-guest-carts-check-gift-card giftCardAccountGuestGiftCardAccountManagementV1CheckGiftCardGet" [
  cartId: string
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/guest-carts/($cartId)/checkGiftCard/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/guest-carts/{cartId}/giftCards
#
# POST /V1/carts/guest-carts/{cartId}/giftCards
# operationId: giftCardAccountGuestGiftCardAccountManagementV1AddGiftCardPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-guest-carts-gift-cards giftCardAccountGuestGiftCardAccountManagementV1AddGiftCardPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftCardAccountData: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/guest-carts/($cartId)/giftCards")
  let body = {giftCardAccountData: $giftCardAccountData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/guest-carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/carts/guest-carts/{cartId}/giftCards/{giftCardCode}
# operationId: giftCardAccountGuestGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-carts-guest-carts-gift-cards giftCardAccountGuestGiftCardAccountManagementV1DeleteByQuoteIdDelete" [
  cartId: string
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/guest-carts/($cartId)/giftCards/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/licence
#
# GET /V1/carts/licence
# operationId: checkoutAgreementsCheckoutAgreementsRepositoryV1GetListGet
export def "v1-carts-licence checkoutAgreementsCheckoutAgreementsRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<agreement_id: int, checkbox_text: string, content: string, content_height: string, extension_attributes: record, is_active: bool, is_html: bool, mode: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/licence")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine
#
# GET /V1/carts/mine
# operationId: quoteCartManagementV1GetCartForCustomerGet
export def "v1-carts-mine quoteCartManagementV1GetCartForCustomerGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine
#
# POST /V1/carts/mine
# operationId: quoteCartManagementV1CreateEmptyCartForCustomerPost
export def "v1-carts-mine quoteCartManagementV1CreateEmptyCartForCustomerPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine
#
# PUT /V1/carts/mine
# operationId: quoteCartRepositoryV1SavePut
# --quote shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
export def "v1-carts-mine quoteCartRepositoryV1SavePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  quote: record # Interface CartInterface — shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine")
  let body = {quote: $quote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/balance/apply
#
# POST /V1/carts/mine/balance/apply
# operationId: customerBalanceBalanceManagementFromQuoteV1ApplyPost
export def "v1-carts-mine-balance-apply customerBalanceBalanceManagementFromQuoteV1ApplyPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/balance/apply")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/balance/unapply
#
# POST /V1/carts/mine/balance/unapply
# operationId: customerBalanceBalanceManagementFromQuoteV1UnapplyPost
export def "v1-carts-mine-balance-unapply customerBalanceBalanceManagementFromQuoteV1UnapplyPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/balance/unapply")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/billing-address
#
# GET /V1/carts/mine/billing-address
# operationId: quoteBillingAddressManagementV1GetGet
export def "v1-carts-mine-billing-address quoteBillingAddressManagementV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/billing-address")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/billing-address
#
# POST /V1/carts/mine/billing-address
# operationId: quoteBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-mine-billing-address quoteBillingAddressManagementV1AssignPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  --useForShipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/billing-address")
  let body = {address: $address, useForShipping: $useForShipping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/checkGiftCard/{giftCardCode}
#
# GET /V1/carts/mine/checkGiftCard/{giftCardCode}
# operationId: giftCardAccountGiftCardAccountManagementV1CheckGiftCardGet
export def "v1-carts-mine-check-gift-card giftCardAccountGiftCardAccountManagementV1CheckGiftCardGet" [
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/checkGiftCard/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/checkout-fields
#
# POST /V1/carts/mine/checkout-fields
# operationId: temandoShippingQuoteCartCheckoutFieldManagementV1SaveCheckoutFieldsPost
# --serviceSelection item shape: {attribute_code: string, value: string}
export def "v1-carts-mine-checkout-fields temandoShippingQuoteCartCheckoutFieldManagementV1SaveCheckoutFieldsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  serviceSelection: list # item shape: {attribute_code: string, value: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/checkout-fields")
  let body = {serviceSelection: $serviceSelection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/collect-totals
#
# PUT /V1/carts/mine/collect-totals
# operationId: quoteCartTotalManagementV1CollectTotalsPut
# --additionalData shape: {custom_attributes?: list, extension_attributes?: record}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-collect-totals quoteCartTotalManagementV1CollectTotalsPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --additionalData: record # Additional data for totals collection. — shape: {custom_attributes?: list, extension_attributes?: record}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
  --shippingCarrierCode: string # The carrier code.
  --shippingMethodCode: string # The shipping method code.
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collect-totals")
  let body = {additionalData: $additionalData, paymentMethod: $paymentMethod, shippingCarrierCode: $shippingCarrierCode, shippingMethodCode: $shippingMethodCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/collection-point/search-request
#
# DELETE /V1/carts/mine/collection-point/search-request
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1DeleteSearchRequestDelete
export def "v1-carts-mine-collection-point-search-request temandoShippingCollectionPointCartCollectionPointManagementV1DeleteSearchRequestDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-request")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/collection-point/search-request
#
# PUT /V1/carts/mine/collection-point/search-request
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1SaveSearchRequestPut
export def "v1-carts-mine-collection-point-search-request temandoShippingCollectionPointCartCollectionPointManagementV1SaveSearchRequestPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  countryId: string
  postcode: string
]: any -> record<country_id: string, pending: bool, postcode: string, shipping_address_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-request")
  let body = {countryId: $countryId, postcode: $postcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/collection-point/search-result
#
# GET /V1/carts/mine/collection-point/search-result
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1GetCollectionPointsGet
export def "v1-carts-mine-collection-point-search-result temandoShippingCollectionPointCartCollectionPointManagementV1GetCollectionPointsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<city: string, collection_point_id: string, country: string, entity_id: int, name: string, opening_hours: list<string>, postcode: string, recipient_address_id: int, region: string, selected: bool, shipping_experiences: list<string>, street: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/search-result")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/collection-point/select
#
# POST /V1/carts/mine/collection-point/select
# operationId: temandoShippingCollectionPointCartCollectionPointManagementV1SelectCollectionPointPost
export def "v1-carts-mine-collection-point-select temandoShippingCollectionPointCartCollectionPointManagementV1SelectCollectionPointPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entityId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/collection-point/select")
  let body = {entityId: $entityId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/coupons
#
# DELETE /V1/carts/mine/coupons
# operationId: quoteCouponManagementV1RemoveDelete
export def "v1-carts-mine-coupons quoteCouponManagementV1RemoveDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/coupons
#
# GET /V1/carts/mine/coupons
# operationId: quoteCouponManagementV1GetGet
export def "v1-carts-mine-coupons quoteCouponManagementV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/coupons/{couponCode}
#
# PUT /V1/carts/mine/coupons/{couponCode}
# operationId: quoteCouponManagementV1SetPut
export def "v1-carts-mine-coupons quoteCouponManagementV1SetPut" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/coupons/($couponCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/delivery-option
#
# POST /V1/carts/mine/delivery-option
# operationId: temandoShippingQuoteCartDeliveryOptionManagementV1SavePost
export def "v1-carts-mine-delivery-option temandoShippingQuoteCartDeliveryOptionManagementV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  selectedOption: string
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/delivery-option")
  let body = {selectedOption: $selectedOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/estimate-shipping-methods
#
# POST /V1/carts/mine/estimate-shipping-methods
# operationId: quoteShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-mine-estimate-shipping-methods quoteShipmentEstimationV1EstimateByExtendedAddressPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/estimate-shipping-methods")
  let body = {address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/estimate-shipping-methods-by-address-id
#
# POST /V1/carts/mine/estimate-shipping-methods-by-address-id
# operationId: quoteShippingMethodManagementV1EstimateByAddressIdPost
export def "v1-carts-mine-estimate-shipping-methods-by-address-id quoteShippingMethodManagementV1EstimateByAddressIdPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressId: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/estimate-shipping-methods-by-address-id")
  let body = {addressId: $addressId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/gift-message
#
# GET /V1/carts/mine/gift-message
# operationId: giftMessageCartRepositoryV1GetGet
export def "v1-carts-mine-gift-message giftMessageCartRepositoryV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/gift-message")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/gift-message
#
# POST /V1/carts/mine/gift-message
# operationId: giftMessageCartRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-mine-gift-message giftMessageCartRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/gift-message")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/gift-message/{itemId}
#
# GET /V1/carts/mine/gift-message/{itemId}
# operationId: giftMessageItemRepositoryV1GetGet
export def "v1-carts-mine-gift-message giftMessageItemRepositoryV1GetGet" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/gift-message/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/gift-message/{itemId}
#
# POST /V1/carts/mine/gift-message/{itemId}
# operationId: giftMessageItemRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-mine-gift-message giftMessageItemRepositoryV1SavePost" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/gift-message/($itemId)")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/giftCards
#
# POST /V1/carts/mine/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-mine-gift-cards giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftCardAccountData: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/giftCards")
  let body = {giftCardAccountData: $giftCardAccountData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/giftCards/{giftCardCode}
#
# DELETE /V1/carts/mine/giftCards/{giftCardCode}
# operationId: giftCardAccountGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-carts-mine-gift-cards giftCardAccountGiftCardAccountManagementV1DeleteByQuoteIdDelete" [
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/giftCards/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/items
#
# GET /V1/carts/mine/items
# operationId: quoteCartItemRepositoryV1GetListGet
export def "v1-carts-mine-items quoteCartItemRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/items")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/items
#
# POST /V1/carts/mine/items
# operationId: quoteCartItemRepositoryV1SavePost
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-mine-items quoteCartItemRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/items")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/items/{itemId}
#
# DELETE /V1/carts/mine/items/{itemId}
# operationId: quoteCartItemRepositoryV1DeleteByIdDelete
export def "v1-carts-mine-items quoteCartItemRepositoryV1DeleteByIdDelete" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/items/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/items/{itemId}
#
# PUT /V1/carts/mine/items/{itemId}
# operationId: quoteCartItemRepositoryV1SavePut
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-mine-items quoteCartItemRepositoryV1SavePut" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/mine/items/($itemId)")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/order
#
# PUT /V1/carts/mine/order
# operationId: quoteCartManagementV1PlaceOrderPut
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-order quoteCartManagementV1PlaceOrderPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/order")
  let body = {paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/payment-information
#
# GET /V1/carts/mine/payment-information
# operationId: checkoutPaymentInformationManagementV1GetPaymentInformationGet
export def "v1-carts-mine-payment-information checkoutPaymentInformationManagementV1GetPaymentInformationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-information")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/payment-information
#
# POST /V1/carts/mine/payment-information
# operationId: checkoutPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-payment-information checkoutPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-information")
  let body = {billingAddress: $billingAddress, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/payment-methods
#
# GET /V1/carts/mine/payment-methods
# operationId: quotePaymentMethodManagementV1GetListGet
export def "v1-carts-mine-payment-methods quotePaymentMethodManagementV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/payment-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/selected-payment-method
#
# GET /V1/carts/mine/selected-payment-method
# operationId: quotePaymentMethodManagementV1GetGet
export def "v1-carts-mine-selected-payment-method quotePaymentMethodManagementV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/selected-payment-method")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/selected-payment-method
#
# PUT /V1/carts/mine/selected-payment-method
# operationId: quotePaymentMethodManagementV1SetPut
# --method shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-selected-payment-method quotePaymentMethodManagementV1SetPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/selected-payment-method")
  let body = {method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/set-payment-information
#
# POST /V1/carts/mine/set-payment-information
# operationId: checkoutPaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-mine-set-payment-information checkoutPaymentInformationManagementV1SavePaymentInformationPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/set-payment-information")
  let body = {billingAddress: $billingAddress, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/shipping-information
#
# POST /V1/carts/mine/shipping-information
# operationId: checkoutShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-carts-mine-shipping-information checkoutShippingInformationManagementV1SaveAddressInformationPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/shipping-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/mine/shipping-methods
#
# GET /V1/carts/mine/shipping-methods
# operationId: quoteShippingMethodManagementV1GetListGet
export def "v1-carts-mine-shipping-methods quoteShippingMethodManagementV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/shipping-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/totals
#
# GET /V1/carts/mine/totals
# operationId: quoteCartTotalRepositoryV1GetGet
export def "v1-carts-mine-totals quoteCartTotalRepositoryV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/totals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/mine/totals-information
#
# POST /V1/carts/mine/totals-information
# operationId: checkoutTotalsInformationManagementV1CalculatePost
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-carts-mine-totals-information checkoutTotalsInformationManagementV1CalculatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/carts/mine/totals-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/search
#
# GET /V1/carts/search
# operationId: quoteCartRepositoryV1GetListGet
export def "v1-carts-search quoteCartRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<billing_address: record, converted_at: string, created_at: string, currency: record, customer: record, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record, id: int, is_active: bool, is_virtual: bool, items: list, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/carts/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}
#
# GET /V1/carts/{cartId}
# operationId: quoteCartRepositoryV1GetGet
export def "v1-carts quoteCartRepositoryV1GetGet" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}
#
# PUT /V1/carts/{cartId}
# operationId: quoteCartManagementV1AssignCustomerPut
export def "v1-carts quoteCartManagementV1AssignCustomerPut" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customerId: int # The customer ID.
  storeId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)")
  let body = {customerId: $customerId, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/billing-address
#
# GET /V1/carts/{cartId}/billing-address
export def "v1-carts-billing-address get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/billing-address")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/billing-address
#
# POST /V1/carts/{cartId}/billing-address
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-billing-address post" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  --useForShipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/billing-address")
  let body = {address: $address, useForShipping: $useForShipping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/coupons
#
# DELETE /V1/carts/{cartId}/coupons
export def "v1-carts-coupons delete" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/coupons
#
# GET /V1/carts/{cartId}/coupons
export def "v1-carts-coupons get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/carts/{cartId}/coupons/{couponCode}
export def "v1-carts-coupons put" [
  cartId: int
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/coupons/($couponCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/estimate-shipping-methods
#
# POST /V1/carts/{cartId}/estimate-shipping-methods
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-carts-estimate-shipping-methods post" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/estimate-shipping-methods")
  let body = {address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/estimate-shipping-methods-by-address-id
#
# POST /V1/carts/{cartId}/estimate-shipping-methods-by-address-id
export def "v1-carts-estimate-shipping-methods-by-address-id post" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressId: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/estimate-shipping-methods-by-address-id")
  let body = {addressId: $addressId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/gift-message
#
# GET /V1/carts/{cartId}/gift-message
export def "v1-carts-gift-message list" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/gift-message")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/gift-message
#
# POST /V1/carts/{cartId}/gift-message
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-gift-message post-by-cartId" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/gift-message")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/gift-message/{itemId}
#
# GET /V1/carts/{cartId}/gift-message/{itemId}
export def "v1-carts-gift-message get" [
  cartId: int
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/gift-message/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/gift-message/{itemId}
#
# POST /V1/carts/{cartId}/gift-message/{itemId}
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-carts-gift-message post-by-cartId-itemId" [
  cartId: int
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/gift-message/($itemId)")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/giftCards
#
# PUT /V1/carts/{cartId}/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPut
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-carts-gift-cards giftCardAccountGiftCardAccountManagementV1SaveByQuoteIdPut" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftCardAccountData: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/giftCards")
  let body = {giftCardAccountData: $giftCardAccountData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/carts/{cartId}/giftCards/{giftCardCode}
export def "v1-carts-gift-cards delete" [
  cartId: int
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/giftCards/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/items
#
# GET /V1/carts/{cartId}/items
export def "v1-carts-items get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/items")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/items/{itemId}
#
# DELETE /V1/carts/{cartId}/items/{itemId}
export def "v1-carts-items delete" [
  cartId: int
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/items/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/items/{itemId}
#
# PUT /V1/carts/{cartId}/items/{itemId}
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-items put" [
  cartId: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/items/($itemId)")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/order
#
# PUT /V1/carts/{cartId}/order
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-order put" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/order")
  let body = {paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/payment-methods
#
# GET /V1/carts/{cartId}/payment-methods
export def "v1-carts-payment-methods get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/payment-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/selected-payment-method
#
# GET /V1/carts/{cartId}/selected-payment-method
export def "v1-carts-selected-payment-method get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/selected-payment-method")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/selected-payment-method
#
# PUT /V1/carts/{cartId}/selected-payment-method
# --method shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-carts-selected-payment-method put" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/selected-payment-method")
  let body = {method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/shipping-information
#
# POST /V1/carts/{cartId}/shipping-information
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-carts-shipping-information post" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/shipping-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{cartId}/shipping-methods
#
# GET /V1/carts/{cartId}/shipping-methods
export def "v1-carts-shipping-methods get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/shipping-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/totals
#
# GET /V1/carts/{cartId}/totals
export def "v1-carts-totals get" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/totals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{cartId}/totals-information
#
# POST /V1/carts/{cartId}/totals-information
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-carts-totals-information post" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($cartId)/totals-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# carts/{quoteId}/giftCards
#
# GET /V1/carts/{quoteId}/giftCards
# operationId: giftCardAccountGiftCardAccountManagementV1GetListByQuoteIdGet
export def "v1-carts-gift-cards giftCardAccountGiftCardAccountManagementV1GetListByQuoteIdGet" [
  quoteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes: record, gift_cards: list<string>, gift_cards_amount: float, gift_cards_amount_used: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($quoteId)/giftCards")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# carts/{quoteId}/items
#
# POST /V1/carts/{quoteId}/items
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-carts-items post" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/carts/($quoteId)/items")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# categories
#
# GET /V1/categories
# operationId: catalogCategoryManagementV1GetTreeGet
export def "v1-categories catalogCategoryManagementV1GetTreeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --rootCategoryId: int
  --depth: int
]: nothing -> record<children_data: list<any>, id: int, is_active: bool, level: int, name: string, parent_id: int, position: int, product_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rootCategoryId" $rootCategoryId "scalar") (serialize-qp "depth" $depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories
#
# POST /V1/categories
# operationId: catalogCategoryRepositoryV1SavePost
# --category shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-categories catalogCategoryRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  category: record # shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/categories")
  let body = {category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# categories/attributes
#
# GET /V1/categories/attributes
# operationId: catalogCategoryAttributeRepositoryV1GetListGet
export def "v1-categories-attributes catalogCategoryAttributeRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<apply_to: list, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/attributes/{attributeCode}
#
# GET /V1/categories/attributes/{attributeCode}
# operationId: catalogCategoryAttributeRepositoryV1GetGet
export def "v1-categories-attributes catalogCategoryAttributeRepositoryV1GetGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/attributes/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/attributes/{attributeCode}/options
#
# GET /V1/categories/attributes/{attributeCode}/options
# operationId: catalogCategoryAttributeOptionManagementV1GetItemsGet
export def "v1-categories-attributes-options catalogCategoryAttributeOptionManagementV1GetItemsGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<is_default: bool, label: string, sort_order: int, store_labels: list<record>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/attributes/($attributeCode)/options")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/list
#
# GET /V1/categories/list
# operationId: catalogCategoryListV1GetListGet
export def "v1-categories-list catalogCategoryListV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<available_sort_by: list, children: string, created_at: string, custom_attributes: list, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/categories/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/{categoryId}
#
# DELETE /V1/categories/{categoryId}
# operationId: catalogCategoryRepositoryV1DeleteByIdentifierDelete
export def "v1-categories catalogCategoryRepositoryV1DeleteByIdentifierDelete" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/{categoryId}
#
# GET /V1/categories/{categoryId}
# operationId: catalogCategoryRepositoryV1GetGet
export def "v1-categories catalogCategoryRepositoryV1GetGet" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --storeId: int
]: nothing -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/categories/($categoryId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/{categoryId}/move
#
# PUT /V1/categories/{categoryId}/move
# operationId: catalogCategoryManagementV1MovePut
export def "v1-categories-move catalogCategoryManagementV1MovePut" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --afterId: int
  parentId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)/move")
  let body = {afterId: $afterId, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# categories/{categoryId}/products
#
# GET /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkManagementV1GetAssignedProductsGet
export def "v1-categories-products catalogCategoryLinkManagementV1GetAssignedProductsGet" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<category_id: string, extension_attributes: record, position: int, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)/products")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/{categoryId}/products
#
# POST /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkRepositoryV1SavePost
# --productLink shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
export def "v1-categories-products catalogCategoryLinkRepositoryV1SavePost" [
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  productLink: record # shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)/products")
  let body = {productLink: $productLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# categories/{categoryId}/products
#
# PUT /V1/categories/{categoryId}/products
# operationId: catalogCategoryLinkRepositoryV1SavePut
# --productLink shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
export def "v1-categories-products catalogCategoryLinkRepositoryV1SavePut" [
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  productLink: record # shape: {category_id: string, extension_attributes?: record, position?: int, sku?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)/products")
  let body = {productLink: $productLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# categories/{categoryId}/products/{sku}
#
# DELETE /V1/categories/{categoryId}/products/{sku}
# operationId: catalogCategoryLinkRepositoryV1DeleteByIdsDelete
export def "v1-categories-products catalogCategoryLinkRepositoryV1DeleteByIdsDelete" [
  categoryId: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($categoryId)/products/($sku)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# categories/{id}
#
# PUT /V1/categories/{id}
# operationId: catalogCategoryRepositoryV1SavePut
# --category shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-categories catalogCategoryRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  category: record # shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> record<available_sort_by: list<string>, children: string, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record, id: int, include_in_menu: bool, is_active: bool, level: int, name: string, parent_id: int, path: string, position: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/categories/($id)")
  let body = {category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cmsBlock
#
# POST /V1/cmsBlock
# operationId: cmsBlockRepositoryV1SavePost
# --block shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
export def "v1-cms-block cmsBlockRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  block: record # CMS block interface. — shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/cmsBlock")
  let body = {block: $block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cmsBlock/search
#
# GET /V1/cmsBlock/search
# operationId: cmsBlockRepositoryV1GetListGet
export def "v1-cms-block-search cmsBlockRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/cmsBlock/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# cmsBlock/{blockId}
#
# DELETE /V1/cmsBlock/{blockId}
# operationId: cmsBlockRepositoryV1DeleteByIdDelete
export def "v1-cms-block cmsBlockRepositoryV1DeleteByIdDelete" [
  blockId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsBlock/($blockId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# cmsBlock/{blockId}
#
# GET /V1/cmsBlock/{blockId}
# operationId: cmsBlockRepositoryV1GetByIdGet
export def "v1-cms-block cmsBlockRepositoryV1GetByIdGet" [
  blockId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsBlock/($blockId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# cmsBlock/{id}
#
# PUT /V1/cmsBlock/{id}
# operationId: cmsBlockRepositoryV1SavePut
# --block shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
export def "v1-cms-block cmsBlockRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  block: record # CMS block interface. — shape: {active?: bool, content?: string, creation_time?: string, id?: int, identifier: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, creation_time: string, id: int, identifier: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsBlock/($id)")
  let body = {block: $block} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cmsPage
#
# POST /V1/cmsPage
# operationId: cmsPageRepositoryV1SavePost
# --page shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
export def "v1-cms-page cmsPageRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  page: record # CMS page interface. — shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/cmsPage")
  let body = {page: $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cmsPage/search
#
# GET /V1/cmsPage/search
# operationId: cmsPageRepositoryV1GetListGet
export def "v1-cms-page-search cmsPageRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/cmsPage/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# cmsPage/{id}
#
# PUT /V1/cmsPage/{id}
# operationId: cmsPageRepositoryV1SavePut
# --page shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
export def "v1-cms-page cmsPageRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  page: record # CMS page interface. — shape: {active?: bool, content?: string, content_heading?: string, creation_time?: string, custom_layout_update_xml?: string, custom_root_template?: string, custom_theme?: string, custom_theme_from?: string, custom_theme_to?: string, id?: int, identifier: string, layout_update_xml?: string, meta_description?: string, meta_keywords?: string, meta_title?: string, page_layout?: string, sort_order?: string, title?: string, update_time?: string}
]: any -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsPage/($id)")
  let body = {page: $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cmsPage/{pageId}
#
# DELETE /V1/cmsPage/{pageId}
# operationId: cmsPageRepositoryV1DeleteByIdDelete
export def "v1-cms-page cmsPageRepositoryV1DeleteByIdDelete" [
  pageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsPage/($pageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# cmsPage/{pageId}
#
# GET /V1/cmsPage/{pageId}
# operationId: cmsPageRepositoryV1GetByIdGet
export def "v1-cms-page cmsPageRepositoryV1GetByIdGet" [
  pageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, content: string, content_heading: string, creation_time: string, custom_layout_update_xml: string, custom_root_template: string, custom_theme: string, custom_theme_from: string, custom_theme_to: string, id: int, identifier: string, layout_update_xml: string, meta_description: string, meta_keywords: string, meta_title: string, page_layout: string, sort_order: string, title: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/cmsPage/($pageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/
#
# GET /V1/company/
# operationId: companyCompanyRepositoryV1GetListGet
export def "v1-company companyCompanyRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list, super_user_id: int, telephone: string, vat_tax_id: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/company/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/
#
# POST /V1/company/
# operationId: companyCompanyRepositoryV1SavePost
# --company shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-company companyCompanyRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  company: record # Interface for Company entity. — shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/")
  let body = {company: $company} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# company/assignRoles
#
# PUT /V1/company/assignRoles
# operationId: companyAclV1AssignRolesPut
# --roles item shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-assign-roles companyAclV1AssignRolesPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  roles: list # item shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
  userId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/assignRoles")
  let body = {roles: $roles, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# company/role/
#
# GET /V1/company/role/
# operationId: companyRoleRepositoryV1GetListGet
export def "v1-company-role companyRoleRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<company_id: int, extension_attributes: record, id: int, permissions: list, role_name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/company/role/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/role/
#
# POST /V1/company/role/
# operationId: companyRoleRepositoryV1SavePost
# --role shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-role companyRoleRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  role: record # Role data transfer object interface. — shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
]: any -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/company/role/")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# company/role/{id}
#
# PUT /V1/company/role/{id}
# operationId: companyRoleRepositoryV1SavePut
# --role shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
export def "v1-company-role companyRoleRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  role: record # Role data transfer object interface. — shape: {company_id?: int, extension_attributes?: record, id?: int, permissions: list, role_name?: string}
]: any -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/role/($id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# company/role/{roleId}
#
# DELETE /V1/company/role/{roleId}
# operationId: companyRoleRepositoryV1DeleteDelete
export def "v1-company-role companyRoleRepositoryV1DeleteDelete" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/role/($roleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/role/{roleId}
#
# GET /V1/company/role/{roleId}
# operationId: companyRoleRepositoryV1GetGet
export def "v1-company-role companyRoleRepositoryV1GetGet" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<company_id: int, extension_attributes: record, id: int, permissions: table<id: int, permission: string, resource_id: string, role_id: int>, role_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/role/($roleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/role/{roleId}/users
#
# GET /V1/company/role/{roleId}/users
# operationId: companyAclV1GetUsersByRoleIdGet
export def "v1-company-role-users companyAclV1GetUsersByRoleIdGet" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/role/($roleId)/users")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# DELETE /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1DeleteByIdDelete
export def "v1-company companyCompanyRepositoryV1DeleteByIdDelete" [
  companyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/($companyId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# GET /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1GetGet
export def "v1-company companyCompanyRepositoryV1GetGet" [
  companyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/($companyId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# company/{companyId}
#
# PUT /V1/company/{companyId}
# operationId: companyCompanyRepositoryV1SavePut
# --company shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-company companyCompanyRepositoryV1SavePut" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  company: record # Interface for Company entity. — shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> record<city: string, comment: string, company_email: string, company_name: string, country_id: string, customer_group_id: int, extension_attributes: record<applicable_payment_method: int, available_payment_methods: string, quote_config: record<company_id: string, extension_attributes: record, is_quote_enabled: bool>, use_config_settings: int>, id: int, legal_name: string, postcode: string, region: string, region_id: string, reject_reason: string, rejected_at: string, reseller_id: string, sales_representative_id: int, status: int, street: list<string>, super_user_id: int, telephone: string, vat_tax_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/company/($companyId)")
  let body = {company: $company} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# companyCredits/
#
# GET /V1/companyCredits/
# operationId: companyCreditCreditLimitRepositoryV1GetListGet
export def "v1-company-credits companyCreditCreditLimitRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<available_limit: float, balance: float, company_id: int, credit_limit: float, currency_code: string, exceed_limit: bool, id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/companyCredits/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# companyCredits/company/{companyId}
#
# GET /V1/companyCredits/company/{companyId}
# operationId: companyCreditCreditLimitManagementV1GetCreditByCompanyIdGet
export def "v1-company-credits-company companyCreditCreditLimitManagementV1GetCreditByCompanyIdGet" [
  companyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/companyCredits/company/($companyId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# companyCredits/history
#
# GET /V1/companyCredits/history
# operationId: companyCreditCreditHistoryManagementV1GetListGet
export def "v1-company-credits-history companyCreditCreditHistoryManagementV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<amount: float, available_limit: float, balance: float, comment: string, company_credit_id: int, credit_limit: float, currency_credit: string, currency_operation: string, datetime: string, id: int, purchase_order: string, rate: float, rate_credit: float, type: int, user_id: int, user_type: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/companyCredits/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# companyCredits/history/{historyId}
#
# PUT /V1/companyCredits/history/{historyId}
# operationId: companyCreditCreditHistoryManagementV1UpdatePut
export def "v1-company-credits-history companyCreditCreditHistoryManagementV1UpdatePut" [
  historyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  --purchaseOrder: string # [optional]
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/companyCredits/history/($historyId)")
  let body = {comment: $comment, purchaseOrder: $purchaseOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# companyCredits/{creditId}
#
# GET /V1/companyCredits/{creditId}
# operationId: companyCreditCreditLimitRepositoryV1GetGet
export def "v1-company-credits companyCreditCreditLimitRepositoryV1GetGet" [
  creditId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --reload: oneof<nothing, bool> # [optional]
]: nothing -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reload" $reload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/companyCredits/($creditId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# companyCredits/{creditId}/decreaseBalance
#
# POST /V1/companyCredits/{creditId}/decreaseBalance
# operationId: companyCreditCreditBalanceManagementV1DecreasePost
# --options shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
export def "v1-company-credits-decrease-balance companyCreditCreditBalanceManagementV1DecreasePost" [
  creditId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  currency: string
  operationType: int
  --options: record # Credit balance data transfer object interface. — shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
  value: float
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/companyCredits/($creditId)/decreaseBalance")
  let body = {comment: $comment, currency: $currency, operationType: $operationType, options: $options, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# companyCredits/{creditId}/increaseBalance
#
# POST /V1/companyCredits/{creditId}/increaseBalance
# operationId: companyCreditCreditBalanceManagementV1IncreasePost
# --options shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
export def "v1-company-credits-increase-balance companyCreditCreditBalanceManagementV1IncreasePost" [
  creditId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --comment: string # [optional]
  currency: string
  operationType: int
  --options: record # Credit balance data transfer object interface. — shape: {currency_base: string, currency_display: string, order_increment: string, purchase_order: string}
  value: float
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/companyCredits/($creditId)/increaseBalance")
  let body = {comment: $comment, currency: $currency, operationType: $operationType, options: $options, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# companyCredits/{id}
#
# PUT /V1/companyCredits/{id}
# operationId: companyCreditCreditLimitRepositoryV1SavePut
# --creditLimit shape: {available_limit?: float, balance?: float, company_id?: int, credit_comment?: string, credit_limit?: float, currency_code?: string, exceed_limit: bool, extension_attributes?: record, id?: int}
export def "v1-company-credits companyCreditCreditLimitRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  creditLimit: record # Credit Limit data transfer object interface. — shape: {available_limit?: float, balance?: float, company_id?: int, credit_comment?: string, credit_limit?: float, currency_code?: string, exceed_limit: bool, extension_attributes?: record, id?: int}
]: any -> record<available_limit: float, balance: float, company_id: int, credit_comment: string, credit_limit: float, currency_code: string, exceed_limit: bool, extension_attributes: record, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/companyCredits/($id)")
  let body = {creditLimit: $creditLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# configurable-products/variation
#
# PUT /V1/configurable-products/variation
# operationId: configurableProductConfigurableProductManagementV1GenerateVariationPut
# --options item shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-configurable-products-variation configurableProductConfigurableProductManagementV1GenerateVariationPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  options: list # item shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> table<attribute_set_id: int, created_at: string, custom_attributes: list<record>, extension_attributes: record<bundle_product_options: list, category_links: list, configurable_product_links: list, configurable_product_options: list, downloadable_product_links: list, downloadable_product_samples: list, giftcard_amounts: list, stock_item: record, website_ids: list>, id: int, media_gallery_entries: list<record>, name: string, options: list<record>, price: float, product_links: list<record>, sku: string, status: int, tier_prices: list<record>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/configurable-products/variation")
  let body = {options: $options, product: $product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# configurable-products/{sku}/child
#
# POST /V1/configurable-products/{sku}/child
# operationId: configurableProductLinkManagementV1AddChildPost
export def "v1-configurable-products-child configurableProductLinkManagementV1AddChildPost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  childSku: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/child")
  let body = {childSku: $childSku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# configurable-products/{sku}/children
#
# GET /V1/configurable-products/{sku}/children
# operationId: configurableProductLinkManagementV1GetChildrenGet
export def "v1-configurable-products-children configurableProductLinkManagementV1GetChildrenGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_set_id: int, created_at: string, custom_attributes: list<record>, extension_attributes: record<bundle_product_options: list, category_links: list, configurable_product_links: list, configurable_product_options: list, downloadable_product_links: list, downloadable_product_samples: list, giftcard_amounts: list, stock_item: record, website_ids: list>, id: int, media_gallery_entries: list<record>, name: string, options: list<record>, price: float, product_links: list<record>, sku: string, status: int, tier_prices: list<record>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/children")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/children/{childSku}
#
# DELETE /V1/configurable-products/{sku}/children/{childSku}
# operationId: configurableProductLinkManagementV1RemoveChildDelete
export def "v1-configurable-products-children configurableProductLinkManagementV1RemoveChildDelete" [
  sku: string
  childSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/children/($childSku)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options
#
# POST /V1/configurable-products/{sku}/options
# operationId: configurableProductOptionRepositoryV1SavePost
# --option shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
export def "v1-configurable-products-options configurableProductOptionRepositoryV1SavePost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/options")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# configurable-products/{sku}/options/all
#
# GET /V1/configurable-products/{sku}/options/all
# operationId: configurableProductOptionRepositoryV1GetListGet
export def "v1-configurable-products-options-all configurableProductOptionRepositoryV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_id: string, extension_attributes: record, id: int, is_use_default: bool, label: string, position: int, product_id: int, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/options/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# DELETE /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1DeleteByIdDelete
export def "v1-configurable-products-options configurableProductOptionRepositoryV1DeleteByIdDelete" [
  sku: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/options/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# GET /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1GetGet
export def "v1-configurable-products-options configurableProductOptionRepositoryV1GetGet" [
  sku: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_id: string, extension_attributes: record, id: int, is_use_default: bool, label: string, position: int, product_id: int, values: table<extension_attributes: record, value_index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/options/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# configurable-products/{sku}/options/{id}
#
# PUT /V1/configurable-products/{sku}/options/{id}
# operationId: configurableProductOptionRepositoryV1SavePut
# --option shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
export def "v1-configurable-products-options configurableProductOptionRepositoryV1SavePut" [
  sku: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # Interface OptionInterface — shape: {attribute_id?: string, extension_attributes?: record, id?: int, is_use_default?: bool, label?: string, position?: int, product_id?: int, values?: list}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/configurable-products/($sku)/options/($id)")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# coupons
#
# POST /V1/coupons
# operationId: salesRuleCouponRepositoryV1SavePost
# --coupon shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
export def "v1-coupons salesRuleCouponRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  coupon: record # Interface CouponInterface — shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
]: any -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons")
  let body = {coupon: $coupon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# coupons/deleteByCodes
#
# POST /V1/coupons/deleteByCodes
# operationId: salesRuleCouponManagementV1DeleteByCodesPost
export def "v1-coupons-delete-by-codes salesRuleCouponManagementV1DeleteByCodesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  codes: list
  --ignoreInvalidCoupons: oneof<nothing, bool>
]: any -> record<failed_items: list<string>, missing_items: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/deleteByCodes")
  let body = {codes: $codes, ignoreInvalidCoupons: $ignoreInvalidCoupons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# coupons/deleteByIds
#
# POST /V1/coupons/deleteByIds
# operationId: salesRuleCouponManagementV1DeleteByIdsPost
export def "v1-coupons-delete-by-ids salesRuleCouponManagementV1DeleteByIdsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list
  --ignoreInvalidCoupons: oneof<nothing, bool>
]: any -> record<failed_items: list<string>, missing_items: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/deleteByIds")
  let body = {ids: $ids, ignoreInvalidCoupons: $ignoreInvalidCoupons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# coupons/generate
#
# POST /V1/coupons/generate
# operationId: salesRuleCouponManagementV1GeneratePost
# --couponSpec shape: {delimiter?: string, delimiter_at_every?: int, extension_attributes?: record, format: string, length: int, prefix?: string, quantity: int, rule_id: int, suffix?: string}
export def "v1-coupons-generate salesRuleCouponManagementV1GeneratePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  couponSpec: record # CouponGenerationSpecInterface — shape: {delimiter?: string, delimiter_at_every?: int, extension_attributes?: record, format: string, length: int, prefix?: string, quantity: int, rule_id: int, suffix?: string}
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/coupons/generate")
  let body = {couponSpec: $couponSpec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# coupons/search
#
# GET /V1/coupons/search
# operationId: salesRuleCouponRepositoryV1GetListGet
export def "v1-coupons-search salesRuleCouponRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/coupons/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# DELETE /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1DeleteByIdDelete
export def "v1-coupons salesRuleCouponRepositoryV1DeleteByIdDelete" [
  couponId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/coupons/($couponId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# GET /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1GetByIdGet
export def "v1-coupons salesRuleCouponRepositoryV1GetByIdGet" [
  couponId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/coupons/($couponId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# coupons/{couponId}
#
# PUT /V1/coupons/{couponId}
# operationId: salesRuleCouponRepositoryV1SavePut
# --coupon shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
export def "v1-coupons salesRuleCouponRepositoryV1SavePut" [
  couponId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  coupon: record # Interface CouponInterface — shape: {code?: string, coupon_id?: int, created_at?: string, expiration_date?: string, extension_attributes?: record, is_primary: bool, rule_id: int, times_used: int, type?: int, usage_limit?: int, usage_per_customer?: int}
]: any -> record<code: string, coupon_id: int, created_at: string, expiration_date: string, extension_attributes: record, is_primary: bool, rule_id: int, times_used: int, type: int, usage_limit: int, usage_per_customer: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/coupons/($couponId)")
  let body = {coupon: $coupon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# creditmemo
#
# POST /V1/creditmemo
# operationId: salesCreditmemoRepositoryV1SavePost
# --entity shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, billing_address_id?: int, comments?: list, created_at?: string, creditmemo_status?: int, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, invoice_id?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, transaction_id?: string, updated_at?: string}
export def "v1-creditmemo salesCreditmemoRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Credit memo interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. — shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, billing_address_id?: int, comments?: list, created_at?: string, creditmemo_status?: int, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, invoice_id?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, transaction_id?: string, updated_at?: string}
]: any -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/creditmemo")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# creditmemo/refund
#
# POST /V1/creditmemo/refund
# operationId: salesCreditmemoManagementV1RefundPost
# --creditmemo shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, billing_address_id?: int, comments?: list, created_at?: string, creditmemo_status?: int, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, invoice_id?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, transaction_id?: string, updated_at?: string}
export def "v1-creditmemo-refund salesCreditmemoManagementV1RefundPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  creditmemo: record # Credit memo interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. — shape: {adjustment?: float, adjustment_negative?: float, adjustment_positive?: float, base_adjustment?: float, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, billing_address_id?: int, comments?: list, created_at?: string, creditmemo_status?: int, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, invoice_id?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, transaction_id?: string, updated_at?: string}
  --offlineRequested: oneof<nothing, bool>
]: any -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/creditmemo/refund")
  let body = {creditmemo: $creditmemo, offlineRequested: $offlineRequested} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# creditmemo/{id}
#
# GET /V1/creditmemo/{id}
# operationId: salesCreditmemoRepositoryV1GetGet
export def "v1-creditmemo salesCreditmemoRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string>, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/creditmemo/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creditmemo/{id}
#
# PUT /V1/creditmemo/{id}
# operationId: salesCreditmemoManagementV1CancelPut
export def "v1-creditmemo salesCreditmemoManagementV1CancelPut" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/creditmemo/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creditmemo/{id}/comments
#
# GET /V1/creditmemo/{id}/comments
# operationId: salesCreditmemoManagementV1GetCommentsListGet
export def "v1-creditmemo-comments salesCreditmemoManagementV1GetCommentsListGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/creditmemo/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creditmemo/{id}/comments
#
# POST /V1/creditmemo/{id}/comments
# operationId: salesCreditmemoCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-creditmemo-comments salesCreditmemoCommentRepositoryV1SavePost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Credit memo comment interface. After a customer places and pays for an order and an invoice has been issued, the merchant can create a credit memo to refund all or part of the amount paid for any returned or undelivered items. The memo restores funds to the customer account so that the customer can make future purchases. A credit memo usually includes comments that detail why the credit memo amount was credited to the customer. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/creditmemo/($id)/comments")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# creditmemo/{id}/emails
#
# POST /V1/creditmemo/{id}/emails
# operationId: salesCreditmemoManagementV1NotifyPost
export def "v1-creditmemo-emails salesCreditmemoManagementV1NotifyPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/creditmemo/($id)/emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creditmemos
#
# GET /V1/creditmemos
# operationId: salesCreditmemoRepositoryV1GetListGet
export def "v1-creditmemos salesCreditmemoRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<adjustment: float, adjustment_negative: float, adjustment_positive: float, base_adjustment: float, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, billing_address_id: int, comments: list, created_at: string, creditmemo_status: int, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record, global_currency_code: string, grand_total: float, increment_id: string, invoice_id: int, items: list, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, transaction_id: string, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/creditmemos" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups
#
# POST /V1/customerGroups
# operationId: customerGroupRepositoryV1SavePost
# --group shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
export def "v1-customer-groups customerGroupRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  group: record # Customer group interface. — shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
]: any -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customerGroups")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customerGroups/default
#
# GET /V1/customerGroups/default
# operationId: customerGroupManagementV1GetDefaultGroupGet
export def "v1-customer-groups-default customerGroupManagementV1GetDefaultGroupGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --storeId: int
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customerGroups/default" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/default/{id}
#
# PUT /V1/customerGroups/default/{id}
# operationId: customerCustomerGroupConfigV1SetDefaultCustomerGroupPut
export def "v1-customer-groups-default customerCustomerGroupConfigV1SetDefaultCustomerGroupPut" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/default/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/default/{storeId}
#
# GET /V1/customerGroups/default/{storeId}
export def "v1-customer-groups-default get" [
  storeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/default/($storeId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/search
#
# GET /V1/customerGroups/search
# operationId: customerGroupRepositoryV1GetListGet
export def "v1-customer-groups-search customerGroupRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customerGroups/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# DELETE /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1DeleteByIdDelete
export def "v1-customer-groups customerGroupRepositoryV1DeleteByIdDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# GET /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1GetByIdGet
export def "v1-customer-groups customerGroupRepositoryV1GetByIdGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customerGroups/{id}
#
# PUT /V1/customerGroups/{id}
# operationId: customerGroupRepositoryV1SavePut
# --group shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
export def "v1-customer-groups customerGroupRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  group: record # Customer group interface. — shape: {code: string, extension_attributes?: record, id?: int, tax_class_id: int, tax_class_name?: string}
]: any -> record<code: string, extension_attributes: record, id: int, tax_class_id: int, tax_class_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/($id)")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customerGroups/{id}/permissions
#
# GET /V1/customerGroups/{id}/permissions
# operationId: customerGroupManagementV1IsReadonlyGet
export def "v1-customer-groups-permissions customerGroupManagementV1IsReadonlyGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customerGroups/($id)/permissions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers
#
# POST /V1/customers
# operationId: customerAccountManagementV1CreateAccountPost
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers customerAccountManagementV1CreateAccountPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --password: string
  --redirectUrl: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers")
  let body = {customer: $customer, password: $password, redirectUrl: $redirectUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/addresses/{addressId}
#
# GET /V1/customers/addresses/{addressId}
# operationId: customerAddressRepositoryV1GetByIdGet
export def "v1-customers-addresses customerAddressRepositoryV1GetByIdGet" [
  addressId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/addresses/($addressId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/confirm
#
# POST /V1/customers/confirm
# operationId: customerAccountManagementV1ResendConfirmationPost
export def "v1-customers-confirm customerAccountManagementV1ResendConfirmationPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string
  --redirectUrl: string
  websiteId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/confirm")
  let body = {email: $email, redirectUrl: $redirectUrl, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/isEmailAvailable
#
# POST /V1/customers/isEmailAvailable
# operationId: customerAccountManagementV1IsEmailAvailablePost
export def "v1-customers-is-email-available customerAccountManagementV1IsEmailAvailablePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customerEmail: string
  --websiteId: int # If not set, will use the current websiteId
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/isEmailAvailable")
  let body = {customerEmail: $customerEmail, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/me
#
# GET /V1/customers/me
# operationId: customerCustomerRepositoryV1GetByIdGet
export def "v1-customers-me customerCustomerRepositoryV1GetByIdGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/me
#
# PUT /V1/customers/me
# operationId: customerCustomerRepositoryV1SavePut
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers-me customerCustomerRepositoryV1SavePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --passwordHash: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me")
  let body = {customer: $customer, passwordHash: $passwordHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/me/activate
#
# PUT /V1/customers/me/activate
# operationId: customerAccountManagementV1ActivateByIdPut
export def "v1-customers-me-activate customerAccountManagementV1ActivateByIdPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  confirmationKey: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/activate")
  let body = {confirmationKey: $confirmationKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/me/billingAddress
#
# GET /V1/customers/me/billingAddress
# operationId: customerAccountManagementV1GetDefaultBillingAddressGet
export def "v1-customers-me-billing-address customerAccountManagementV1GetDefaultBillingAddressGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/billingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/me/password
#
# PUT /V1/customers/me/password
# operationId: customerAccountManagementV1ChangePasswordByIdPut
export def "v1-customers-me-password customerAccountManagementV1ChangePasswordByIdPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  currentPassword: string
  newPassword: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/password")
  let body = {currentPassword: $currentPassword, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/me/shippingAddress
#
# GET /V1/customers/me/shippingAddress
# operationId: customerAccountManagementV1GetDefaultShippingAddressGet
export def "v1-customers-me-shipping-address customerAccountManagementV1GetDefaultShippingAddressGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/me/shippingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/password
#
# PUT /V1/customers/password
# operationId: customerAccountManagementV1InitiatePasswordResetPut
export def "v1-customers-password customerAccountManagementV1InitiatePasswordResetPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string
  template: string
  --websiteId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/password")
  let body = {email: $email, template: $template, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/resetPassword
#
# POST /V1/customers/resetPassword
# operationId: customerAccountManagementV1ResetPasswordPost
export def "v1-customers-reset-password customerAccountManagementV1ResetPasswordPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string # If empty value given then the customer will be matched by the RP token.
  newPassword: string
  resetToken: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/resetPassword")
  let body = {email: $email, newPassword: $newPassword, resetToken: $resetToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/search
#
# GET /V1/customers/search
# operationId: customerCustomerRepositoryV1GetListGet
export def "v1-customers-search customerCustomerRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<addresses: list, confirmation: string, created_at: string, created_in: string, custom_attributes: list, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/customers/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/validate
#
# PUT /V1/customers/validate
# operationId: customerAccountManagementV1ValidatePut
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers-validate customerAccountManagementV1ValidatePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
]: any -> record<messages: list<string>, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/customers/validate")
  let body = {customer: $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/{customerId}
#
# DELETE /V1/customers/{customerId}
# operationId: customerCustomerRepositoryV1DeleteByIdDelete
export def "v1-customers customerCustomerRepositoryV1DeleteByIdDelete" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}
#
# GET /V1/customers/{customerId}
export def "v1-customers get" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}
#
# PUT /V1/customers/{customerId}
# --customer shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
export def "v1-customers put" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customer: record # Customer interface. — shape: {addresses?: list, confirmation?: string, created_at?: string, created_in?: string, custom_attributes?: list, default_billing?: string, default_shipping?: string, disable_auto_group_change?: int, dob?: string, email: string, extension_attributes?: record, firstname: string, gender?: int, group_id?: int, id?: int, lastname: string, middlename?: string, prefix?: string, store_id?: int, suffix?: string, taxvat?: string, updated_at?: string, website_id?: int}
  --passwordHash: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)")
  let body = {customer: $customer, passwordHash: $passwordHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# customers/{customerId}/billingAddress
#
# GET /V1/customers/{customerId}/billingAddress
export def "v1-customers-billing-address get" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/billingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}/carts
#
# POST /V1/customers/{customerId}/carts
export def "v1-customers-carts post" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/carts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}/confirm
#
# GET /V1/customers/{customerId}/confirm
# operationId: customerAccountManagementV1GetConfirmationStatusGet
export def "v1-customers-confirm customerAccountManagementV1GetConfirmationStatusGet" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/confirm")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}/password/resetLinkToken/{resetPasswordLinkToken}
#
# GET /V1/customers/{customerId}/password/resetLinkToken/{resetPasswordLinkToken}
# operationId: customerAccountManagementV1ValidateResetPasswordLinkTokenGet
export def "v1-customers-password-reset-link-token customerAccountManagementV1ValidateResetPasswordLinkTokenGet" [
  customerId: int
  resetPasswordLinkToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/password/resetLinkToken/($resetPasswordLinkToken)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}/permissions/readonly
#
# GET /V1/customers/{customerId}/permissions/readonly
# operationId: customerAccountManagementV1IsReadonlyGet
export def "v1-customers-permissions-readonly customerAccountManagementV1IsReadonlyGet" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/permissions/readonly")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{customerId}/shippingAddress
#
# GET /V1/customers/{customerId}/shippingAddress
export def "v1-customers-shipping-address get" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record<extension_attributes: record, region: string, region_code: string, region_id: int>, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($customerId)/shippingAddress")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# customers/{email}/activate
#
# PUT /V1/customers/{email}/activate
# operationId: customerAccountManagementV1ActivatePut
export def "v1-customers-activate customerAccountManagementV1ActivatePut" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  confirmationKey: string
]: any -> record<addresses: table<city: string, company: string, country_id: string, custom_attributes: list, customer_id: int, default_billing: bool, default_shipping: bool, extension_attributes: record, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: record, region_id: int, street: list, suffix: string, telephone: string, vat_id: string>, confirmation: string, created_at: string, created_in: string, custom_attributes: table<attribute_code: string, value: string>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record<company_id: int, customer_id: int, extension_attributes: record, job_title: string, status: int, telephone: string>, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/customers/($email)/activate")
  let body = {confirmationKey: $confirmationKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# directory/countries
#
# GET /V1/directory/countries
# operationId: directoryCountryInformationAcquirerV1GetCountriesInfoGet
export def "v1-directory-countries directoryCountryInformationAcquirerV1GetCountriesInfoGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<available_regions: list<record>, extension_attributes: record, full_name_english: string, full_name_locale: string, id: string, three_letter_abbreviation: string, two_letter_abbreviation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/directory/countries")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# directory/countries/{countryId}
#
# GET /V1/directory/countries/{countryId}
# operationId: directoryCountryInformationAcquirerV1GetCountryInfoGet
export def "v1-directory-countries directoryCountryInformationAcquirerV1GetCountryInfoGet" [
  countryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_regions: table<code: string, extension_attributes: record, id: string, name: string>, extension_attributes: record, full_name_english: string, full_name_locale: string, id: string, three_letter_abbreviation: string, two_letter_abbreviation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/directory/countries/($countryId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# directory/currency
#
# GET /V1/directory/currency
# operationId: directoryCurrencyInformationAcquirerV1GetCurrencyInfoGet
export def "v1-directory-currency directoryCurrencyInformationAcquirerV1GetCurrencyInfoGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<available_currency_codes: list<string>, base_currency_code: string, base_currency_symbol: string, default_display_currency_code: string, default_display_currency_symbol: string, exchange_rates: table<currency_to: string, extension_attributes: record, rate: float>, extension_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/directory/currency")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# eav/attribute-sets
#
# POST /V1/eav/attribute-sets
# operationId: eavAttributeSetManagementV1CreatePost
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-eav-attribute-sets eavAttributeSetManagementV1CreatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attributeSet: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
  entityTypeCode: string
  skeletonId: int
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/eav/attribute-sets")
  let body = {attributeSet: $attributeSet, entityTypeCode: $entityTypeCode, skeletonId: $skeletonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# eav/attribute-sets/list
#
# GET /V1/eav/attribute-sets/list
# operationId: eavAttributeSetRepositoryV1GetListGet
export def "v1-eav-attribute-sets-list eavAttributeSetRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/eav/attribute-sets/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# DELETE /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1DeleteByIdDelete
export def "v1-eav-attribute-sets eavAttributeSetRepositoryV1DeleteByIdDelete" [
  attributeSetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/eav/attribute-sets/($attributeSetId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# GET /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1GetGet
export def "v1-eav-attribute-sets eavAttributeSetRepositoryV1GetGet" [
  attributeSetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/eav/attribute-sets/($attributeSetId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# eav/attribute-sets/{attributeSetId}
#
# PUT /V1/eav/attribute-sets/{attributeSetId}
# operationId: eavAttributeSetRepositoryV1SavePut
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-eav-attribute-sets eavAttributeSetRepositoryV1SavePut" [
  attributeSetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attributeSet: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/eav/attribute-sets/($attributeSetId)")
  let body = {attributeSet: $attributeSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# gift-wrappings
#
# GET /V1/gift-wrappings
# operationId: giftWrappingWrappingRepositoryV1GetListGet
export def "v1-gift-wrappings giftWrappingWrappingRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list, wrapping_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/gift-wrappings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# gift-wrappings
#
# POST /V1/gift-wrappings
# operationId: giftWrappingWrappingRepositoryV1SavePost
# --data shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list, wrapping_id?: int}
export def "v1-gift-wrappings giftWrappingWrappingRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  data: record # Interface WrappingInterface — shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list, wrapping_id?: int}
  --storeId: int
]: any -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/gift-wrappings")
  let body = {data: $data, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# gift-wrappings/{id}
#
# DELETE /V1/gift-wrappings/{id}
# operationId: giftWrappingWrappingRepositoryV1DeleteByIdDelete
export def "v1-gift-wrappings giftWrappingWrappingRepositoryV1DeleteByIdDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/gift-wrappings/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# gift-wrappings/{id}
#
# GET /V1/gift-wrappings/{id}
# operationId: giftWrappingWrappingRepositoryV1GetGet
export def "v1-gift-wrappings giftWrappingWrappingRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --storeId: int
]: nothing -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/gift-wrappings/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# gift-wrappings/{wrappingId}
#
# PUT /V1/gift-wrappings/{wrappingId}
# operationId: giftWrappingWrappingRepositoryV1SavePut
# --data shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list, wrapping_id?: int}
export def "v1-gift-wrappings giftWrappingWrappingRepositoryV1SavePut" [
  wrappingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  data: record # Interface WrappingInterface — shape: {base_currency_code?: string, base_price: float, design: string, extension_attributes?: record, image_base64_content?: string, image_name?: string, image_url?: string, status: int, website_ids?: list, wrapping_id?: int}
  --storeId: int
]: any -> record<base_currency_code: string, base_price: float, design: string, extension_attributes: record, image_base64_content: string, image_name: string, image_url: string, status: int, website_ids: list<int>, wrapping_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/gift-wrappings/($wrappingId)")
  let body = {data: $data, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# giftregistry/mine/estimate-shipping-methods
#
# POST /V1/giftregistry/mine/estimate-shipping-methods
# operationId: giftRegistryShippingMethodManagementV1EstimateByRegistryIdPost
export def "v1-giftregistry-mine-estimate-shipping-methods giftRegistryShippingMethodManagementV1EstimateByRegistryIdPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  registryId: int # The estimate registry id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/giftregistry/mine/estimate-shipping-methods")
  let body = {registryId: $registryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts
#
# POST /V1/guest-carts
# operationId: quoteGuestCartManagementV1CreateEmptyCartPost
export def "v1-guest-carts quoteGuestCartManagementV1CreateEmptyCartPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/guest-carts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}
#
# GET /V1/guest-carts/{cartId}
# operationId: quoteGuestCartRepositoryV1GetGet
export def "v1-guest-carts quoteGuestCartRepositoryV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address: record<city: string, company: string, country_id: string, custom_attributes: list<record>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string>, converted_at: string, created_at: string, currency: record<base_currency_code: string, base_to_global_rate: float, base_to_quote_rate: float, extension_attributes: record, global_currency_code: string, quote_currency_code: string, store_currency_code: string, store_to_base_rate: float, store_to_quote_rate: float>, customer: record<addresses: list<record>, confirmation: string, created_at: string, created_in: string, custom_attributes: list<record>, default_billing: string, default_shipping: string, disable_auto_group_change: int, dob: string, email: string, extension_attributes: record<amazon_id: string, company_attributes: record, is_subscribed: bool, vertex_customer_code: string>, firstname: string, gender: int, group_id: int, id: int, lastname: string, middlename: string, prefix: string, store_id: int, suffix: string, taxvat: string, updated_at: string, website_id: int>, customer_is_guest: bool, customer_note: string, customer_note_notify: bool, customer_tax_class_id: int, extension_attributes: record<amazon_order_reference_id: string, negotiable_quote: record<applied_rule_ids: string, base_negotiated_total_price: float, base_original_total_price: float, creator_id: int, creator_type: int, deleted_sku: string, email_notification_status: int, expiration_period: string, extension_attributes: record, has_unconfirmed_changes: bool, is_address_draft: bool, is_customer_price_changed: bool, is_regular_quote: bool, is_shipping_tax_changed: bool, negotiated_price_type: int, negotiated_price_value: float, negotiated_total_price: float, notifications: int, original_total_price: float, quote_id: int, quote_name: string, shipping_price: float, status: string>, shipping_assignments: list<record>>, id: int, is_active: bool, is_virtual: bool, items: table<extension_attributes: record, item_id: int, name: string, price: float, product_option: record, product_type: string, qty: float, quote_id: string, sku: string>, items_count: int, items_qty: float, orig_order_id: int, reserved_order_id: string, store_id: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}
#
# PUT /V1/guest-carts/{cartId}
# operationId: quoteGuestCartManagementV1AssignCustomerPut
export def "v1-guest-carts quoteGuestCartManagementV1AssignCustomerPut" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  customerId: int # The customer ID.
  storeId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)")
  let body = {customerId: $customerId, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/billing-address
#
# GET /V1/guest-carts/{cartId}/billing-address
# operationId: quoteGuestBillingAddressManagementV1GetGet
export def "v1-guest-carts-billing-address quoteGuestBillingAddressManagementV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/billing-address")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/billing-address
#
# POST /V1/guest-carts/{cartId}/billing-address
# operationId: quoteGuestBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-guest-carts-billing-address quoteGuestBillingAddressManagementV1AssignPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  --useForShipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/billing-address")
  let body = {address: $address, useForShipping: $useForShipping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/checkout-fields
#
# POST /V1/guest-carts/{cartId}/checkout-fields
# operationId: temandoShippingQuoteGuestCartCheckoutFieldManagementV1SaveCheckoutFieldsPost
# --serviceSelection item shape: {attribute_code: string, value: string}
export def "v1-guest-carts-checkout-fields temandoShippingQuoteGuestCartCheckoutFieldManagementV1SaveCheckoutFieldsPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  serviceSelection: list # item shape: {attribute_code: string, value: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/checkout-fields")
  let body = {serviceSelection: $serviceSelection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/collect-totals
#
# PUT /V1/guest-carts/{cartId}/collect-totals
# operationId: quoteGuestCartTotalManagementV1CollectTotalsPut
# --additionalData shape: {custom_attributes?: list, extension_attributes?: record}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-collect-totals quoteGuestCartTotalManagementV1CollectTotalsPut" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --additionalData: record # Additional data for totals collection. — shape: {custom_attributes?: list, extension_attributes?: record}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
  --shippingCarrierCode: string # The carrier code.
  --shippingMethodCode: string # The shipping method code.
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/collect-totals")
  let body = {additionalData: $additionalData, paymentMethod: $paymentMethod, shippingCarrierCode: $shippingCarrierCode, shippingMethodCode: $shippingMethodCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/collection-point/search-request
#
# DELETE /V1/guest-carts/{cartId}/collection-point/search-request
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1DeleteSearchRequestDelete
export def "v1-guest-carts-collection-point-search-request temandoShippingCollectionPointGuestCartCollectionPointManagementV1DeleteSearchRequestDelete" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/collection-point/search-request")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/collection-point/search-request
#
# PUT /V1/guest-carts/{cartId}/collection-point/search-request
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1SaveSearchRequestPut
export def "v1-guest-carts-collection-point-search-request temandoShippingCollectionPointGuestCartCollectionPointManagementV1SaveSearchRequestPut" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  countryId: string
  postcode: string
]: any -> record<country_id: string, pending: bool, postcode: string, shipping_address_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/collection-point/search-request")
  let body = {countryId: $countryId, postcode: $postcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/collection-point/search-result
#
# GET /V1/guest-carts/{cartId}/collection-point/search-result
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1GetCollectionPointsGet
export def "v1-guest-carts-collection-point-search-result temandoShippingCollectionPointGuestCartCollectionPointManagementV1GetCollectionPointsGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<city: string, collection_point_id: string, country: string, entity_id: int, name: string, opening_hours: list<string>, postcode: string, recipient_address_id: int, region: string, selected: bool, shipping_experiences: list<string>, street: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/collection-point/search-result")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/collection-point/select
#
# POST /V1/guest-carts/{cartId}/collection-point/select
# operationId: temandoShippingCollectionPointGuestCartCollectionPointManagementV1SelectCollectionPointPost
export def "v1-guest-carts-collection-point-select temandoShippingCollectionPointGuestCartCollectionPointManagementV1SelectCollectionPointPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entityId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/collection-point/select")
  let body = {entityId: $entityId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/coupons
#
# DELETE /V1/guest-carts/{cartId}/coupons
# operationId: quoteGuestCouponManagementV1RemoveDelete
export def "v1-guest-carts-coupons quoteGuestCouponManagementV1RemoveDelete" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/coupons
#
# GET /V1/guest-carts/{cartId}/coupons
# operationId: quoteGuestCouponManagementV1GetGet
export def "v1-guest-carts-coupons quoteGuestCouponManagementV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/guest-carts/{cartId}/coupons/{couponCode}
# operationId: quoteGuestCouponManagementV1SetPut
export def "v1-guest-carts-coupons quoteGuestCouponManagementV1SetPut" [
  cartId: string
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/coupons/($couponCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/delivery-option
#
# POST /V1/guest-carts/{cartId}/delivery-option
# operationId: temandoShippingQuoteGuestCartDeliveryOptionManagementV1SavePost
export def "v1-guest-carts-delivery-option temandoShippingQuoteGuestCartDeliveryOptionManagementV1SavePost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  selectedOption: string
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/delivery-option")
  let body = {selectedOption: $selectedOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/estimate-shipping-methods
#
# POST /V1/guest-carts/{cartId}/estimate-shipping-methods
# operationId: quoteGuestShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-guest-carts-estimate-shipping-methods quoteGuestShipmentEstimationV1EstimateByExtendedAddressPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/estimate-shipping-methods")
  let body = {address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/gift-message
#
# GET /V1/guest-carts/{cartId}/gift-message
# operationId: giftMessageGuestCartRepositoryV1GetGet
export def "v1-guest-carts-gift-message giftMessageGuestCartRepositoryV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/gift-message")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/gift-message
#
# POST /V1/guest-carts/{cartId}/gift-message
# operationId: giftMessageGuestCartRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-guest-carts-gift-message giftMessageGuestCartRepositoryV1SavePost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/gift-message")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/gift-message/{itemId}
#
# GET /V1/guest-carts/{cartId}/gift-message/{itemId}
# operationId: giftMessageGuestItemRepositoryV1GetGet
export def "v1-guest-carts-gift-message giftMessageGuestItemRepositoryV1GetGet" [
  cartId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<customer_id: int, extension_attributes: record<entity_id: string, entity_type: string, wrapping_add_printed_card: bool, wrapping_allow_gift_receipt: bool, wrapping_id: int>, gift_message_id: int, message: string, recipient: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/gift-message/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/gift-message/{itemId}
#
# POST /V1/guest-carts/{cartId}/gift-message/{itemId}
# operationId: giftMessageGuestItemRepositoryV1SavePost
# --giftMessage shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
export def "v1-guest-carts-gift-message giftMessageGuestItemRepositoryV1SavePost" [
  cartId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftMessage: record # Interface MessageInterface — shape: {customer_id?: int, extension_attributes?: record, gift_message_id?: int, message: string, recipient: string, sender: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/gift-message/($itemId)")
  let body = {giftMessage: $giftMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/items
#
# GET /V1/guest-carts/{cartId}/items
# operationId: quoteGuestCartItemRepositoryV1GetListGet
export def "v1-guest-carts-items quoteGuestCartItemRepositoryV1GetListGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<negotiable_quote_item: record>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record>, product_type: string, qty: float, quote_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/items")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/items
#
# POST /V1/guest-carts/{cartId}/items
# operationId: quoteGuestCartItemRepositoryV1SavePost
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-guest-carts-items quoteGuestCartItemRepositoryV1SavePost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/items")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/items/{itemId}
#
# DELETE /V1/guest-carts/{cartId}/items/{itemId}
# operationId: quoteGuestCartItemRepositoryV1DeleteByIdDelete
export def "v1-guest-carts-items quoteGuestCartItemRepositoryV1DeleteByIdDelete" [
  cartId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/items/($itemId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/items/{itemId}
#
# PUT /V1/guest-carts/{cartId}/items/{itemId}
# operationId: quoteGuestCartItemRepositoryV1SavePut
# --cartItem shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
export def "v1-guest-carts-items quoteGuestCartItemRepositoryV1SavePut" [
  cartId: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  cartItem: record # Interface CartItemInterface — shape: {extension_attributes?: record, item_id?: int, name?: string, price?: float, product_option?: record, product_type?: string, qty: float, quote_id: string, sku?: string}
]: any -> record<extension_attributes: record<negotiable_quote_item: record<extension_attributes: record, item_id: int, original_discount_amount: float, original_price: float, original_tax_amount: float>>, item_id: int, name: string, price: float, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty: float, quote_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/items/($itemId)")
  let body = {cartItem: $cartItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/order
#
# PUT /V1/guest-carts/{cartId}/order
# operationId: quoteGuestCartManagementV1PlaceOrderPut
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-order quoteGuestCartManagementV1PlaceOrderPut" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/order")
  let body = {paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/payment-information
#
# GET /V1/guest-carts/{cartId}/payment-information
# operationId: checkoutGuestPaymentInformationManagementV1GetPaymentInformationGet
export def "v1-guest-carts-payment-information checkoutGuestPaymentInformationManagementV1GetPaymentInformationGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/payment-information")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/payment-information
#
# POST /V1/guest-carts/{cartId}/payment-information
# operationId: checkoutGuestPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-payment-information checkoutGuestPaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  email: string
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/payment-information")
  let body = {billingAddress: $billingAddress, email: $email, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/payment-methods
#
# GET /V1/guest-carts/{cartId}/payment-methods
# operationId: quoteGuestPaymentMethodManagementV1GetListGet
export def "v1-guest-carts-payment-methods quoteGuestPaymentMethodManagementV1GetListGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/payment-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/selected-payment-method
#
# GET /V1/guest-carts/{cartId}/selected-payment-method
# operationId: quoteGuestPaymentMethodManagementV1GetGet
export def "v1-guest-carts-selected-payment-method quoteGuestPaymentMethodManagementV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: list<string>, extension_attributes: record<agreement_ids: list<string>>, method: string, po_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/selected-payment-method")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/selected-payment-method
#
# PUT /V1/guest-carts/{cartId}/selected-payment-method
# operationId: quoteGuestPaymentMethodManagementV1SetPut
# --method shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-selected-payment-method quoteGuestPaymentMethodManagementV1SetPut" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  method: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/selected-payment-method")
  let body = {method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/set-payment-information
#
# POST /V1/guest-carts/{cartId}/set-payment-information
# operationId: checkoutGuestPaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-guest-carts-set-payment-information checkoutGuestPaymentInformationManagementV1SavePaymentInformationPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  email: string
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/set-payment-information")
  let body = {billingAddress: $billingAddress, email: $email, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/shipping-information
#
# POST /V1/guest-carts/{cartId}/shipping-information
# operationId: checkoutGuestShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-guest-carts-shipping-information checkoutGuestShippingInformationManagementV1SaveAddressInformationPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/shipping-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-carts/{cartId}/shipping-methods
#
# GET /V1/guest-carts/{cartId}/shipping-methods
# operationId: quoteGuestShippingMethodManagementV1GetListGet
export def "v1-guest-carts-shipping-methods quoteGuestShippingMethodManagementV1GetListGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/shipping-methods")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/totals
#
# GET /V1/guest-carts/{cartId}/totals
# operationId: quoteGuestCartTotalRepositoryV1GetGet
export def "v1-guest-carts-totals quoteGuestCartTotalRepositoryV1GetGet" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/totals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# guest-carts/{cartId}/totals-information
#
# POST /V1/guest-carts/{cartId}/totals-information
# operationId: checkoutGuestTotalsInformationManagementV1CalculatePost
# --addressInformation shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
export def "v1-guest-carts-totals-information checkoutGuestTotalsInformationManagementV1CalculatePost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface TotalsInformationInterface — shape: {address: record, custom_attributes?: list, extension_attributes?: record, shipping_carrier_code?: string, shipping_method_code?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-carts/($cartId)/totals-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# guest-giftregistry/{cartId}/estimate-shipping-methods
#
# POST /V1/guest-giftregistry/{cartId}/estimate-shipping-methods
# operationId: giftRegistryGuestCartShippingMethodManagementV1EstimateByRegistryIdPost
export def "v1-guest-giftregistry-estimate-shipping-methods giftRegistryGuestCartShippingMethodManagementV1EstimateByRegistryIdPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  registryId: int # The estimate registry id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/guest-giftregistry/($cartId)/estimate-shipping-methods")
  let body = {registryId: $registryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# hierarchy/move/{id}
#
# PUT /V1/hierarchy/move/{id}
# operationId: companyCompanyHierarchyV1MoveNodePut
export def "v1-hierarchy-move companyCompanyHierarchyV1MoveNodePut" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  newParentId: int
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/hierarchy/move/($id)")
  let body = {newParentId: $newParentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# hierarchy/{id}
#
# GET /V1/hierarchy/{id}
# operationId: companyCompanyHierarchyV1GetCompanyHierarchyGet
export def "v1-hierarchy companyCompanyHierarchyV1GetCompanyHierarchyGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<entity_id: int, entity_type: string, extension_attributes: record, structure_id: int, structure_parent_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/hierarchy/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# integration/admin/token
#
# POST /V1/integration/admin/token
# operationId: integrationAdminTokenServiceV1CreateAdminAccessTokenPost
export def "v1-integration-admin-token integrationAdminTokenServiceV1CreateAdminAccessTokenPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  password: string
  username: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/integration/admin/token")
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# integration/customer/token
#
# POST /V1/integration/customer/token
# operationId: integrationCustomerTokenServiceV1CreateCustomerAccessTokenPost
export def "v1-integration-customer-token integrationCustomerTokenServiceV1CreateCustomerAccessTokenPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  password: string
  username: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/integration/customer/token")
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# invoice/{invoiceId}/refund
#
# POST /V1/invoice/{invoiceId}/refund
# operationId: salesRefundInvoiceV1ExecutePost
# --arguments shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-invoice-refund salesRefundInvoiceV1ExecutePost" [
  invoiceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --appendComment: oneof<nothing, bool>
  --arguments: record # Interface CreditmemoCreationArgumentsInterface — shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
  --comment: record # Interface CreditmemoCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --isOnline: oneof<nothing, bool>
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoice/($invoiceId)/refund")
  let body = {appendComment: $appendComment, arguments: $arguments, comment: $comment, isOnline: $isOnline, items: $items, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# invoices
#
# GET /V1/invoices
# operationId: salesInvoiceRepositoryV1GetListGet
export def "v1-invoices salesInvoiceRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: list, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: list, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/invoices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# invoices/
#
# POST /V1/invoices/
# operationId: salesInvoiceRepositoryV1SavePost
# --entity shape: {base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_refunded?: float, billing_address_id?: int, can_void_flag?: int, comments?: list, created_at?: string, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, is_used_for_refund?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, total_qty: float, transaction_id?: string, updated_at?: string}
export def "v1-invoices salesInvoiceRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Invoice interface. An invoice is a record of the receipt of payment for an order. — shape: {base_currency_code?: string, base_discount_amount?: float, base_discount_tax_compensation_amount?: float, base_grand_total?: float, base_shipping_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_tax_amount?: float, base_subtotal?: float, base_subtotal_incl_tax?: float, base_tax_amount?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_refunded?: float, billing_address_id?: int, can_void_flag?: int, comments?: list, created_at?: string, discount_amount?: float, discount_description?: string, discount_tax_compensation_amount?: float, email_sent?: int, entity_id?: int, extension_attributes?: record, global_currency_code?: string, grand_total?: float, increment_id?: string, is_used_for_refund?: int, items: list, order_currency_code?: string, order_id: int, shipping_address_id?: int, shipping_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_tax_amount?: float, state?: int, store_currency_code?: string, store_id?: int, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_incl_tax?: float, tax_amount?: float, total_qty: float, transaction_id?: string, updated_at?: string}
]: any -> record<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string, vertex_tax_calculation_billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, vertex_tax_calculation_order: record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, vertex_tax_calculation_shipping_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>>, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/invoices/")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# invoices/comments
#
# POST /V1/invoices/comments
# operationId: salesInvoiceCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-invoices-comments salesInvoiceCommentRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Invoice comment interface. An invoice is a record of the receipt of payment for an order. An invoice can include comments that detail the invoice history. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/invoices/comments")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# invoices/{id}
#
# GET /V1/invoices/{id}
# operationId: salesInvoiceRepositoryV1GetGet
export def "v1-invoices salesInvoiceRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_tax_amount: float, base_to_global_rate: float, base_to_order_rate: float, base_total_refunded: float, billing_address_id: int, can_void_flag: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, discount_amount: float, discount_description: string, discount_tax_compensation_amount: float, email_sent: int, entity_id: int, extension_attributes: record<base_customer_balance_amount: float, base_gift_cards_amount: float, customer_balance_amount: float, gift_cards_amount: float, gw_base_price: string, gw_base_tax_amount: string, gw_card_base_price: string, gw_card_base_tax_amount: string, gw_card_price: string, gw_card_tax_amount: string, gw_items_base_price: string, gw_items_base_tax_amount: string, gw_items_price: string, gw_items_tax_amount: string, gw_price: string, gw_tax_amount: string, vertex_tax_calculation_billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, vertex_tax_calculation_order: record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, vertex_tax_calculation_shipping_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>>, global_currency_code: string, grand_total: float, increment_id: string, is_used_for_refund: int, items: table<additional_data: string, base_cost: float, base_discount_amount: float, base_discount_tax_compensation_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, description: string, discount_amount: float, discount_tax_compensation_amount: float, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, price_incl_tax: float, product_id: int, qty: float, row_total: float, row_total_incl_tax: float, sku: string, tax_amount: float>, order_currency_code: string, order_id: int, shipping_address_id: int, shipping_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, state: int, store_currency_code: string, store_id: int, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_incl_tax: float, tax_amount: float, total_qty: float, transaction_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoices/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# invoices/{id}/capture
#
# POST /V1/invoices/{id}/capture
# operationId: salesInvoiceManagementV1SetCapturePost
export def "v1-invoices-capture salesInvoiceManagementV1SetCapturePost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoices/($id)/capture")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# invoices/{id}/comments
#
# GET /V1/invoices/{id}/comments
# operationId: salesInvoiceManagementV1GetCommentsListGet
export def "v1-invoices-comments salesInvoiceManagementV1GetCommentsListGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoices/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# invoices/{id}/emails
#
# POST /V1/invoices/{id}/emails
# operationId: salesInvoiceManagementV1NotifyPost
export def "v1-invoices-emails salesInvoiceManagementV1NotifyPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoices/($id)/emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# invoices/{id}/void
#
# POST /V1/invoices/{id}/void
# operationId: salesInvoiceManagementV1SetVoidPost
export def "v1-invoices-void salesInvoiceManagementV1SetVoidPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/invoices/($id)/void")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# modules
#
# GET /V1/modules
# operationId: backendModuleServiceV1GetModulesGet
export def "v1-modules backendModuleServiceV1GetModulesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/modules")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/billing-address
#
# GET /V1/negotiable-carts/{cartId}/billing-address
# operationId: negotiableQuoteBillingAddressManagementV1GetGet
export def "v1-negotiable-carts-billing-address negotiableQuoteBillingAddressManagementV1GetGet" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: string, company: string, country_id: string, custom_attributes: table<attribute_code: string, value: string>, customer_address_id: int, customer_id: int, email: string, extension_attributes: record<checkout_fields: list<record>, gift_registry_id: int>, fax: string, firstname: string, id: int, lastname: string, middlename: string, postcode: string, prefix: string, region: string, region_code: string, region_id: int, same_as_billing: int, save_in_address_book: int, street: list<string>, suffix: string, telephone: string, vat_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/billing-address")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/billing-address
#
# POST /V1/negotiable-carts/{cartId}/billing-address
# operationId: negotiableQuoteBillingAddressManagementV1AssignPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-negotiable-carts-billing-address negotiableQuoteBillingAddressManagementV1AssignPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  --useForShipping: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/billing-address")
  let body = {address: $address, useForShipping: $useForShipping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/coupons
#
# DELETE /V1/negotiable-carts/{cartId}/coupons
# operationId: negotiableQuoteCouponManagementV1RemoveDelete
export def "v1-negotiable-carts-coupons negotiableQuoteCouponManagementV1RemoveDelete" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/coupons")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/coupons/{couponCode}
#
# PUT /V1/negotiable-carts/{cartId}/coupons/{couponCode}
# operationId: negotiableQuoteCouponManagementV1SetPut
export def "v1-negotiable-carts-coupons negotiableQuoteCouponManagementV1SetPut" [
  cartId: int
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/coupons/($couponCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/estimate-shipping-methods
#
# POST /V1/negotiable-carts/{cartId}/estimate-shipping-methods
# operationId: negotiableQuoteShipmentEstimationV1EstimateByExtendedAddressPost
# --address shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
export def "v1-negotiable-carts-estimate-shipping-methods negotiableQuoteShipmentEstimationV1EstimateByExtendedAddressPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  address: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/estimate-shipping-methods")
  let body = {address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/estimate-shipping-methods-by-address-id
#
# POST /V1/negotiable-carts/{cartId}/estimate-shipping-methods-by-address-id
# operationId: negotiableQuoteShippingMethodManagementV1EstimateByAddressIdPost
export def "v1-negotiable-carts-estimate-shipping-methods-by-address-id negotiableQuoteShippingMethodManagementV1EstimateByAddressIdPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressId: int # The estimate address id
]: any -> table<amount: float, available: bool, base_amount: float, carrier_code: string, carrier_title: string, error_message: string, extension_attributes: record, method_code: string, method_title: string, price_excl_tax: float, price_incl_tax: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/estimate-shipping-methods-by-address-id")
  let body = {addressId: $addressId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/giftCards
#
# POST /V1/negotiable-carts/{cartId}/giftCards
# operationId: negotiableQuoteGiftCardAccountManagementV1SaveByQuoteIdPost
# --giftCardAccountData shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
export def "v1-negotiable-carts-gift-cards negotiableQuoteGiftCardAccountManagementV1SaveByQuoteIdPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  giftCardAccountData: record # Gift Card Account data — shape: {base_gift_cards_amount: float, base_gift_cards_amount_used: float, extension_attributes?: record, gift_cards: list, gift_cards_amount: float, gift_cards_amount_used: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/giftCards")
  let body = {giftCardAccountData: $giftCardAccountData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/giftCards/{giftCardCode}
#
# DELETE /V1/negotiable-carts/{cartId}/giftCards/{giftCardCode}
# operationId: negotiableQuoteGiftCardAccountManagementV1DeleteByQuoteIdDelete
export def "v1-negotiable-carts-gift-cards negotiableQuoteGiftCardAccountManagementV1DeleteByQuoteIdDelete" [
  cartId: int
  giftCardCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/giftCards/($giftCardCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/payment-information
#
# GET /V1/negotiable-carts/{cartId}/payment-information
# operationId: negotiableQuotePaymentInformationManagementV1GetPaymentInformationGet
export def "v1-negotiable-carts-payment-information negotiableQuotePaymentInformationManagementV1GetPaymentInformationGet" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/payment-information")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiable-carts/{cartId}/payment-information
#
# POST /V1/negotiable-carts/{cartId}/payment-information
# operationId: negotiableQuotePaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-negotiable-carts-payment-information negotiableQuotePaymentInformationManagementV1SavePaymentInformationAndPlaceOrderPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/payment-information")
  let body = {billingAddress: $billingAddress, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/set-payment-information
#
# POST /V1/negotiable-carts/{cartId}/set-payment-information
# operationId: negotiableQuotePaymentInformationManagementV1SavePaymentInformationPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-negotiable-carts-set-payment-information negotiableQuotePaymentInformationManagementV1SavePaymentInformationPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/set-payment-information")
  let body = {billingAddress: $billingAddress, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/shipping-information
#
# POST /V1/negotiable-carts/{cartId}/shipping-information
# operationId: negotiableQuoteShippingInformationManagementV1SaveAddressInformationPost
# --addressInformation shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
export def "v1-negotiable-carts-shipping-information negotiableQuoteShippingInformationManagementV1SaveAddressInformationPost" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  addressInformation: record # Interface ShippingInformationInterface — shape: {billing_address?: record, custom_attributes?: list, extension_attributes?: record, shipping_address: record, shipping_carrier_code: string, shipping_method_code: string}
]: any -> record<extension_attributes: record, payment_methods: table<code: string, title: string>, totals: record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: list<record>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: list<record>, weee_tax_applied_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/shipping-information")
  let body = {addressInformation: $addressInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiable-carts/{cartId}/totals
#
# GET /V1/negotiable-carts/{cartId}/totals
# operationId: negotiableQuoteCartTotalRepositoryV1GetGet
export def "v1-negotiable-carts-totals negotiableQuoteCartTotalRepositoryV1GetGet" [
  cartId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<base_currency_code: string, base_discount_amount: float, base_grand_total: float, base_shipping_amount: float, base_shipping_discount_amount: float, base_shipping_incl_tax: float, base_shipping_tax_amount: float, base_subtotal: float, base_subtotal_incl_tax: float, base_subtotal_with_discount: float, base_tax_amount: float, coupon_code: string, discount_amount: float, extension_attributes: record<base_customer_balance_amount: float, base_reward_currency_amount: float, coupon_label: string, customer_balance_amount: float, negotiable_quote_totals: record<base_cost_total: float, base_original_price_incl_tax: float, base_original_tax: float, base_original_total: float, base_to_quote_rate: float, cost_total: float, created_at: string, customer_group: int, items_count: int, negotiated_price_type: int, negotiated_price_value: float, original_price_incl_tax: float, original_tax: float, original_total: float, quote_status: string, updated_at: string>, reward_currency_amount: float, reward_points_balance: float>, grand_total: float, items: table<base_discount_amount: float, base_price: float, base_price_incl_tax: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, discount_amount: float, discount_percent: float, extension_attributes: record, item_id: int, name: string, options: string, price: float, price_incl_tax: float, qty: float, row_total: float, row_total_incl_tax: float, row_total_with_discount: float, tax_amount: float, tax_percent: float, weee_tax_applied: string, weee_tax_applied_amount: float>, items_qty: int, quote_currency_code: string, shipping_amount: float, shipping_discount_amount: float, shipping_incl_tax: float, shipping_tax_amount: float, subtotal: float, subtotal_incl_tax: float, subtotal_with_discount: float, tax_amount: float, total_segments: table<area: string, code: string, extension_attributes: record, title: string, value: float>, weee_tax_applied_amount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiable-carts/($cartId)/totals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiableQuote/attachmentContent
#
# GET /V1/negotiableQuote/attachmentContent
# operationId: negotiableQuoteAttachmentContentManagementV1GetGet
export def "v1-negotiable-quote-attachment-content negotiableQuoteAttachmentContentManagementV1GetGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attachmentIds: list
]: nothing -> table<base64_encoded_data: string, extension_attributes: record, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachmentIds" $attachmentIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/negotiableQuote/attachmentContent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiableQuote/decline
#
# POST /V1/negotiableQuote/decline
# operationId: negotiableQuoteNegotiableQuoteManagementV1DeclinePost
export def "v1-negotiable-quote-decline negotiableQuoteNegotiableQuoteManagementV1DeclinePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  quoteId: int
  reason: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/decline")
  let body = {quoteId: $quoteId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiableQuote/pricesUpdated
#
# POST /V1/negotiableQuote/pricesUpdated
# operationId: negotiableQuoteNegotiableQuotePriceManagementV1PricesUpdatedPost
export def "v1-negotiable-quote-prices-updated negotiableQuoteNegotiableQuotePriceManagementV1PricesUpdatedPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  quoteIds: list
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/pricesUpdated")
  let body = {quoteIds: $quoteIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiableQuote/request
#
# POST /V1/negotiableQuote/request
# operationId: negotiableQuoteNegotiableQuoteManagementV1CreatePost
# --files item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
export def "v1-negotiable-quote-request negotiableQuoteNegotiableQuoteManagementV1CreatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --comment: string
  --files: list # item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
  quoteId: int
  quoteName: string
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/request")
  let body = {comment: $comment, files: $files, quoteId: $quoteId, quoteName: $quoteName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiableQuote/submitToCustomer
#
# POST /V1/negotiableQuote/submitToCustomer
# operationId: negotiableQuoteNegotiableQuoteManagementV1AdminSendPost
# --files item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
export def "v1-negotiable-quote-submit-to-customer negotiableQuoteNegotiableQuoteManagementV1AdminSendPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --comment: string
  --files: list # item shape: {base64_encoded_data: string, extension_attributes?: record, name: string, type: string}
  quoteId: int
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/negotiableQuote/submitToCustomer")
  let body = {comment: $comment, files: $files, quoteId: $quoteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiableQuote/{quoteId}
#
# PUT /V1/negotiableQuote/{quoteId}
# operationId: negotiableQuoteNegotiableCartRepositoryV1SavePut
# --quote shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
export def "v1-negotiable-quote negotiableQuoteNegotiableCartRepositoryV1SavePut" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  quote: record # Interface CartInterface — shape: {billing_address?: record, converted_at?: string, created_at?: string, currency?: record, customer: record, customer_is_guest?: bool, customer_note?: string, customer_note_notify?: bool, customer_tax_class_id?: int, extension_attributes?: record, id: int, is_active?: bool, is_virtual?: bool, items?: list, items_count?: int, items_qty?: float, orig_order_id?: int, reserved_order_id?: string, store_id: int, updated_at?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiableQuote/($quoteId)")
  let body = {quote: $quote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# negotiableQuote/{quoteId}/comments
#
# GET /V1/negotiableQuote/{quoteId}/comments
# operationId: negotiableQuoteCommentLocatorV1GetListForQuoteGet
export def "v1-negotiable-quote-comments negotiableQuoteCommentLocatorV1GetListForQuoteGet" [
  quoteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attachments: list<record>, comment: string, created_at: string, creator_id: int, creator_type: int, entity_id: int, extension_attributes: record, is_decline: int, is_draft: int, parent_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiableQuote/($quoteId)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# negotiableQuote/{quoteId}/shippingMethod
#
# PUT /V1/negotiableQuote/{quoteId}/shippingMethod
# operationId: negotiableQuoteNegotiableQuoteShippingManagementV1SetShippingMethodPut
export def "v1-negotiable-quote-shipping-method negotiableQuoteNegotiableQuoteShippingManagementV1SetShippingMethodPut" [
  quoteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  shippingMethod: string # The shipping method code.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/negotiableQuote/($quoteId)/shippingMethod")
  let body = {shippingMethod: $shippingMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# order/{orderId}/invoice
#
# POST /V1/order/{orderId}/invoice
# operationId: salesInvoiceOrderV1ExecutePost
# --arguments shape: {extension_attributes?: record}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-order-invoice salesInvoiceOrderV1ExecutePost" [
  orderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --appendComment: oneof<nothing, bool>
  --arguments: record # Interface for creation arguments for Invoice. — shape: {extension_attributes?: record}
  --capture: oneof<nothing, bool>
  --comment: record # Interface InvoiceCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/order/($orderId)/invoice")
  let body = {appendComment: $appendComment, arguments: $arguments, capture: $capture, comment: $comment, items: $items, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# order/{orderId}/refund
#
# POST /V1/order/{orderId}/refund
# operationId: salesRefundOrderV1ExecutePost
# --arguments shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
# --comment shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
# --items item shape: {extension_attributes?: record, order_item_id: int, qty: float}
export def "v1-order-refund salesRefundOrderV1ExecutePost" [
  orderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --appendComment: oneof<nothing, bool>
  --arguments: record # Interface CreditmemoCreationArgumentsInterface — shape: {adjustment_negative?: float, adjustment_positive?: float, extension_attributes?: record, shipping_amount?: float}
  --comment: record # Interface CreditmemoCommentCreationInterface — shape: {comment: string, extension_attributes?: record, is_visible_on_front: int}
  --items: list # item shape: {extension_attributes?: record, order_item_id: int, qty: float}
  --notify: oneof<nothing, bool>
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/order/($orderId)/refund")
  let body = {appendComment: $appendComment, arguments: $arguments, comment: $comment, items: $items, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
export def "v1-order-ship salesShipOrderV1ExecutePost" [
  orderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --appendComment: oneof<nothing, bool>
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
  let full_url = (build-url $base $"/V1/order/($orderId)/ship")
  let body = {appendComment: $appendComment, arguments: $arguments, comment: $comment, items: $items, notify: $notify, packages: $packages, tracks: $tracks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# orders
#
# GET /V1/orders
# operationId: salesOrderRepositoryV1GetListGet
export def "v1-orders salesOrderRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: list, order_currency_code: string, original_increment_id: string, payment: record, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: list, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/orders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/
#
# POST /V1/orders/
# operationId: salesOrderRepositoryV1SavePost
# --entity shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, base_shipping_amount?: float, base_shipping_canceled?: float, base_shipping_discount_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_invoiced?: float, base_shipping_refunded?: float, base_shipping_tax_amount?: float, base_shipping_tax_refunded?: float, base_subtotal?: float, base_subtotal_canceled?: float, base_subtotal_incl_tax?: float, base_subtotal_invoiced?: float, base_subtotal_refunded?: float, base_tax_amount?: float, base_tax_canceled?: float, base_tax_invoiced?: float, base_tax_refunded?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_canceled?: float, base_total_due?: float, base_total_invoiced?: float, base_total_invoiced_cost?: float, base_total_offline_refunded?: float, base_total_online_refunded?: float, base_total_paid?: float, base_total_qty_ordered?: float, base_total_refunded?: float, billing_address?: record, billing_address_id?: int, can_ship_partially?: int, can_ship_partially_item?: int, coupon_code?: string, created_at?: string, customer_dob?: string, customer_email: string, customer_firstname?: string, customer_gender?: int, customer_group_id?: int, customer_id?: int, customer_is_guest?: int, customer_lastname?: string, customer_middlename?: string, customer_note?: string, customer_note_notify?: int, customer_prefix?: string, customer_suffix?: string, customer_taxvat?: string, discount_amount?: float, discount_canceled?: float, discount_description?: string, discount_invoiced?: float, discount_refunded?: float, discount_tax_compensation_amount?: float, discount_tax_compensation_invoiced?: float, discount_tax_compensation_refunded?: float, edit_increment?: int, email_sent?: int, entity_id?: int, ext_customer_id?: string, ext_order_id?: string, extension_attributes?: record, forced_shipment_with_invoice?: int, global_currency_code?: string, grand_total: float, hold_before_state?: string, hold_before_status?: string, increment_id?: string, is_virtual?: int, items: list, order_currency_code?: string, original_increment_id?: string, payment?: record, payment_auth_expiration?: int, payment_authorization_amount?: float, protect_code?: string, quote_address_id?: int, quote_id?: int, relation_child_id?: string, relation_child_real_id?: string, relation_parent_id?: string, relation_parent_real_id?: string, remote_ip?: string, shipping_amount?: float, shipping_canceled?: float, shipping_description?: string, shipping_discount_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_invoiced?: float, shipping_refunded?: float, shipping_tax_amount?: float, shipping_tax_refunded?: float, state?: string, status?: string, status_histories?: list, store_currency_code?: string, store_id?: int, store_name?: string, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_canceled?: float, subtotal_incl_tax?: float, subtotal_invoiced?: float, subtotal_refunded?: float, tax_amount?: float, tax_canceled?: float, tax_invoiced?: float, tax_refunded?: float, total_canceled?: float, total_due?: float, total_invoiced?: float, total_item_count?: int, total_offline_refunded?: float, total_online_refunded?: float, total_paid?: float, total_qty_ordered?: float, total_refunded?: float, updated_at?: string, weight?: float, x_forwarded_for?: string}
export def "v1-orders salesOrderRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Order interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, base_shipping_amount?: float, base_shipping_canceled?: float, base_shipping_discount_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_invoiced?: float, base_shipping_refunded?: float, base_shipping_tax_amount?: float, base_shipping_tax_refunded?: float, base_subtotal?: float, base_subtotal_canceled?: float, base_subtotal_incl_tax?: float, base_subtotal_invoiced?: float, base_subtotal_refunded?: float, base_tax_amount?: float, base_tax_canceled?: float, base_tax_invoiced?: float, base_tax_refunded?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_canceled?: float, base_total_due?: float, base_total_invoiced?: float, base_total_invoiced_cost?: float, base_total_offline_refunded?: float, base_total_online_refunded?: float, base_total_paid?: float, base_total_qty_ordered?: float, base_total_refunded?: float, billing_address?: record, billing_address_id?: int, can_ship_partially?: int, can_ship_partially_item?: int, coupon_code?: string, created_at?: string, customer_dob?: string, customer_email: string, customer_firstname?: string, customer_gender?: int, customer_group_id?: int, customer_id?: int, customer_is_guest?: int, customer_lastname?: string, customer_middlename?: string, customer_note?: string, customer_note_notify?: int, customer_prefix?: string, customer_suffix?: string, customer_taxvat?: string, discount_amount?: float, discount_canceled?: float, discount_description?: string, discount_invoiced?: float, discount_refunded?: float, discount_tax_compensation_amount?: float, discount_tax_compensation_invoiced?: float, discount_tax_compensation_refunded?: float, edit_increment?: int, email_sent?: int, entity_id?: int, ext_customer_id?: string, ext_order_id?: string, extension_attributes?: record, forced_shipment_with_invoice?: int, global_currency_code?: string, grand_total: float, hold_before_state?: string, hold_before_status?: string, increment_id?: string, is_virtual?: int, items: list, order_currency_code?: string, original_increment_id?: string, payment?: record, payment_auth_expiration?: int, payment_authorization_amount?: float, protect_code?: string, quote_address_id?: int, quote_id?: int, relation_child_id?: string, relation_child_real_id?: string, relation_parent_id?: string, relation_parent_real_id?: string, remote_ip?: string, shipping_amount?: float, shipping_canceled?: float, shipping_description?: string, shipping_discount_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_invoiced?: float, shipping_refunded?: float, shipping_tax_amount?: float, shipping_tax_refunded?: float, state?: string, status?: string, status_histories?: list, store_currency_code?: string, store_id?: int, store_name?: string, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_canceled?: float, subtotal_incl_tax?: float, subtotal_invoiced?: float, subtotal_refunded?: float, tax_amount?: float, tax_canceled?: float, tax_invoiced?: float, tax_refunded?: float, total_canceled?: float, total_due?: float, total_invoiced?: float, total_item_count?: int, total_offline_refunded?: float, total_online_refunded?: float, total_paid?: float, total_qty_ordered?: float, total_refunded?: float, updated_at?: string, weight?: float, x_forwarded_for?: string}
]: any -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/orders/")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# orders/create
#
# PUT /V1/orders/create
# operationId: salesOrderRepositoryV1SavePut
# --entity shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, base_shipping_amount?: float, base_shipping_canceled?: float, base_shipping_discount_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_invoiced?: float, base_shipping_refunded?: float, base_shipping_tax_amount?: float, base_shipping_tax_refunded?: float, base_subtotal?: float, base_subtotal_canceled?: float, base_subtotal_incl_tax?: float, base_subtotal_invoiced?: float, base_subtotal_refunded?: float, base_tax_amount?: float, base_tax_canceled?: float, base_tax_invoiced?: float, base_tax_refunded?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_canceled?: float, base_total_due?: float, base_total_invoiced?: float, base_total_invoiced_cost?: float, base_total_offline_refunded?: float, base_total_online_refunded?: float, base_total_paid?: float, base_total_qty_ordered?: float, base_total_refunded?: float, billing_address?: record, billing_address_id?: int, can_ship_partially?: int, can_ship_partially_item?: int, coupon_code?: string, created_at?: string, customer_dob?: string, customer_email: string, customer_firstname?: string, customer_gender?: int, customer_group_id?: int, customer_id?: int, customer_is_guest?: int, customer_lastname?: string, customer_middlename?: string, customer_note?: string, customer_note_notify?: int, customer_prefix?: string, customer_suffix?: string, customer_taxvat?: string, discount_amount?: float, discount_canceled?: float, discount_description?: string, discount_invoiced?: float, discount_refunded?: float, discount_tax_compensation_amount?: float, discount_tax_compensation_invoiced?: float, discount_tax_compensation_refunded?: float, edit_increment?: int, email_sent?: int, entity_id?: int, ext_customer_id?: string, ext_order_id?: string, extension_attributes?: record, forced_shipment_with_invoice?: int, global_currency_code?: string, grand_total: float, hold_before_state?: string, hold_before_status?: string, increment_id?: string, is_virtual?: int, items: list, order_currency_code?: string, original_increment_id?: string, payment?: record, payment_auth_expiration?: int, payment_authorization_amount?: float, protect_code?: string, quote_address_id?: int, quote_id?: int, relation_child_id?: string, relation_child_real_id?: string, relation_parent_id?: string, relation_parent_real_id?: string, remote_ip?: string, shipping_amount?: float, shipping_canceled?: float, shipping_description?: string, shipping_discount_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_invoiced?: float, shipping_refunded?: float, shipping_tax_amount?: float, shipping_tax_refunded?: float, state?: string, status?: string, status_histories?: list, store_currency_code?: string, store_id?: int, store_name?: string, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_canceled?: float, subtotal_incl_tax?: float, subtotal_invoiced?: float, subtotal_refunded?: float, tax_amount?: float, tax_canceled?: float, tax_invoiced?: float, tax_refunded?: float, total_canceled?: float, total_due?: float, total_invoiced?: float, total_item_count?: int, total_offline_refunded?: float, total_online_refunded?: float, total_paid?: float, total_qty_ordered?: float, total_refunded?: float, updated_at?: string, weight?: float, x_forwarded_for?: string}
export def "v1-orders-create salesOrderRepositoryV1SavePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Order interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {adjustment_negative?: float, adjustment_positive?: float, applied_rule_ids?: string, base_adjustment_negative?: float, base_adjustment_positive?: float, base_currency_code?: string, base_discount_amount?: float, base_discount_canceled?: float, base_discount_invoiced?: float, base_discount_refunded?: float, base_discount_tax_compensation_amount?: float, base_discount_tax_compensation_invoiced?: float, base_discount_tax_compensation_refunded?: float, base_grand_total: float, base_shipping_amount?: float, base_shipping_canceled?: float, base_shipping_discount_amount?: float, base_shipping_discount_tax_compensation_amnt?: float, base_shipping_incl_tax?: float, base_shipping_invoiced?: float, base_shipping_refunded?: float, base_shipping_tax_amount?: float, base_shipping_tax_refunded?: float, base_subtotal?: float, base_subtotal_canceled?: float, base_subtotal_incl_tax?: float, base_subtotal_invoiced?: float, base_subtotal_refunded?: float, base_tax_amount?: float, base_tax_canceled?: float, base_tax_invoiced?: float, base_tax_refunded?: float, base_to_global_rate?: float, base_to_order_rate?: float, base_total_canceled?: float, base_total_due?: float, base_total_invoiced?: float, base_total_invoiced_cost?: float, base_total_offline_refunded?: float, base_total_online_refunded?: float, base_total_paid?: float, base_total_qty_ordered?: float, base_total_refunded?: float, billing_address?: record, billing_address_id?: int, can_ship_partially?: int, can_ship_partially_item?: int, coupon_code?: string, created_at?: string, customer_dob?: string, customer_email: string, customer_firstname?: string, customer_gender?: int, customer_group_id?: int, customer_id?: int, customer_is_guest?: int, customer_lastname?: string, customer_middlename?: string, customer_note?: string, customer_note_notify?: int, customer_prefix?: string, customer_suffix?: string, customer_taxvat?: string, discount_amount?: float, discount_canceled?: float, discount_description?: string, discount_invoiced?: float, discount_refunded?: float, discount_tax_compensation_amount?: float, discount_tax_compensation_invoiced?: float, discount_tax_compensation_refunded?: float, edit_increment?: int, email_sent?: int, entity_id?: int, ext_customer_id?: string, ext_order_id?: string, extension_attributes?: record, forced_shipment_with_invoice?: int, global_currency_code?: string, grand_total: float, hold_before_state?: string, hold_before_status?: string, increment_id?: string, is_virtual?: int, items: list, order_currency_code?: string, original_increment_id?: string, payment?: record, payment_auth_expiration?: int, payment_authorization_amount?: float, protect_code?: string, quote_address_id?: int, quote_id?: int, relation_child_id?: string, relation_child_real_id?: string, relation_parent_id?: string, relation_parent_real_id?: string, remote_ip?: string, shipping_amount?: float, shipping_canceled?: float, shipping_description?: string, shipping_discount_amount?: float, shipping_discount_tax_compensation_amount?: float, shipping_incl_tax?: float, shipping_invoiced?: float, shipping_refunded?: float, shipping_tax_amount?: float, shipping_tax_refunded?: float, state?: string, status?: string, status_histories?: list, store_currency_code?: string, store_id?: int, store_name?: string, store_to_base_rate?: float, store_to_order_rate?: float, subtotal?: float, subtotal_canceled?: float, subtotal_incl_tax?: float, subtotal_invoiced?: float, subtotal_refunded?: float, tax_amount?: float, tax_canceled?: float, tax_invoiced?: float, tax_refunded?: float, total_canceled?: float, total_due?: float, total_invoiced?: float, total_item_count?: int, total_offline_refunded?: float, total_online_refunded?: float, total_paid?: float, total_qty_ordered?: float, total_refunded?: float, updated_at?: string, weight?: float, x_forwarded_for?: string}
]: any -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/orders/create")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# orders/items
#
# GET /V1/orders/items
# operationId: salesOrderItemRepositoryV1GetListGet
export def "v1-orders-items salesOrderItemRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/orders/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/items/{id}
#
# GET /V1/orders/items/{id}
# operationId: salesOrderItemRepositoryV1GetGet
export def "v1-orders-items salesOrderItemRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record<gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_base_price: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_id: string, gw_price: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, invoice_text_codes: list<string>, tax_codes: list<string>, vertex_tax_codes: list<string>>, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record<extension_attributes: record<bundle_options: list, configurable_item_options: list, custom_options: list, downloadable_option: record, giftcard_item_option: record>>, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/items/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}
#
# GET /V1/orders/{id}
# operationId: salesOrderRepositoryV1GetGet
export def "v1-orders salesOrderRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<adjustment_negative: float, adjustment_positive: float, applied_rule_ids: string, base_adjustment_negative: float, base_adjustment_positive: float, base_currency_code: string, base_discount_amount: float, base_discount_canceled: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_grand_total: float, base_shipping_amount: float, base_shipping_canceled: float, base_shipping_discount_amount: float, base_shipping_discount_tax_compensation_amnt: float, base_shipping_incl_tax: float, base_shipping_invoiced: float, base_shipping_refunded: float, base_shipping_tax_amount: float, base_shipping_tax_refunded: float, base_subtotal: float, base_subtotal_canceled: float, base_subtotal_incl_tax: float, base_subtotal_invoiced: float, base_subtotal_refunded: float, base_tax_amount: float, base_tax_canceled: float, base_tax_invoiced: float, base_tax_refunded: float, base_to_global_rate: float, base_to_order_rate: float, base_total_canceled: float, base_total_due: float, base_total_invoiced: float, base_total_invoiced_cost: float, base_total_offline_refunded: float, base_total_online_refunded: float, base_total_paid: float, base_total_qty_ordered: float, base_total_refunded: float, billing_address: record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int>, billing_address_id: int, can_ship_partially: int, can_ship_partially_item: int, coupon_code: string, created_at: string, customer_dob: string, customer_email: string, customer_firstname: string, customer_gender: int, customer_group_id: int, customer_id: int, customer_is_guest: int, customer_lastname: string, customer_middlename: string, customer_note: string, customer_note_notify: int, customer_prefix: string, customer_suffix: string, customer_taxvat: string, discount_amount: float, discount_canceled: float, discount_description: string, discount_invoiced: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, edit_increment: int, email_sent: int, entity_id: int, ext_customer_id: string, ext_order_id: string, extension_attributes: record<amazon_order_reference_id: string, applied_taxes: list<record>, base_customer_balance_amount: float, base_customer_balance_invoiced: float, base_customer_balance_refunded: float, base_customer_balance_total_refunded: float, base_gift_cards_amount: float, base_gift_cards_invoiced: float, base_gift_cards_refunded: float, base_reward_currency_amount: float, company_order_attributes: record<company_id: int, company_name: string, extension_attributes: record, order_id: int>, converting_from_quote: bool, customer_balance_amount: float, customer_balance_invoiced: float, customer_balance_refunded: float, customer_balance_total_refunded: float, gift_cards: list<record>, gift_cards_amount: float, gift_cards_invoiced: float, gift_cards_refunded: float, gift_message: record<customer_id: int, extension_attributes: record, gift_message_id: int, message: string, recipient: string, sender: string>, gw_add_card: string, gw_allow_gift_receipt: string, gw_base_price: string, gw_base_price_incl_tax: string, gw_base_price_invoiced: string, gw_base_price_refunded: string, gw_base_tax_amount: string, gw_base_tax_amount_invoiced: string, gw_base_tax_amount_refunded: string, gw_card_base_price: string, gw_card_base_price_incl_tax: string, gw_card_base_price_invoiced: string, gw_card_base_price_refunded: string, gw_card_base_tax_amount: string, gw_card_base_tax_invoiced: string, gw_card_base_tax_refunded: string, gw_card_price: string, gw_card_price_incl_tax: string, gw_card_price_invoiced: string, gw_card_price_refunded: string, gw_card_tax_amount: string, gw_card_tax_invoiced: string, gw_card_tax_refunded: string, gw_id: string, gw_items_base_price: string, gw_items_base_price_incl_tax: string, gw_items_base_price_invoiced: string, gw_items_base_price_refunded: string, gw_items_base_tax_amount: string, gw_items_base_tax_invoiced: string, gw_items_base_tax_refunded: string, gw_items_price: string, gw_items_price_incl_tax: string, gw_items_price_invoiced: string, gw_items_price_refunded: string, gw_items_tax_amount: string, gw_items_tax_invoiced: string, gw_items_tax_refunded: string, gw_price: string, gw_price_incl_tax: string, gw_price_invoiced: string, gw_price_refunded: string, gw_tax_amount: string, gw_tax_amount_invoiced: string, gw_tax_amount_refunded: string, item_applied_taxes: list<record>, payment_additional_info: list<record>, reward_currency_amount: float, reward_points_balance: int, shipping_assignments: list<record>>, forced_shipment_with_invoice: int, global_currency_code: string, grand_total: float, hold_before_state: string, hold_before_status: string, increment_id: string, is_virtual: int, items: table<additional_data: string, amount_refunded: float, applied_rule_ids: string, base_amount_refunded: float, base_cost: float, base_discount_amount: float, base_discount_invoiced: float, base_discount_refunded: float, base_discount_tax_compensation_amount: float, base_discount_tax_compensation_invoiced: float, base_discount_tax_compensation_refunded: float, base_original_price: float, base_price: float, base_price_incl_tax: float, base_row_invoiced: float, base_row_total: float, base_row_total_incl_tax: float, base_tax_amount: float, base_tax_before_discount: float, base_tax_invoiced: float, base_tax_refunded: float, base_weee_tax_applied_amount: float, base_weee_tax_applied_row_amnt: float, base_weee_tax_disposition: float, base_weee_tax_row_disposition: float, created_at: string, description: string, discount_amount: float, discount_invoiced: float, discount_percent: float, discount_refunded: float, discount_tax_compensation_amount: float, discount_tax_compensation_canceled: float, discount_tax_compensation_invoiced: float, discount_tax_compensation_refunded: float, event_id: int, ext_order_item_id: string, extension_attributes: record, free_shipping: int, gw_base_price: float, gw_base_price_invoiced: float, gw_base_price_refunded: float, gw_base_tax_amount: float, gw_base_tax_amount_invoiced: float, gw_base_tax_amount_refunded: float, gw_id: int, gw_price: float, gw_price_invoiced: float, gw_price_refunded: float, gw_tax_amount: float, gw_tax_amount_invoiced: float, gw_tax_amount_refunded: float, is_qty_decimal: int, is_virtual: int, item_id: int, locked_do_invoice: int, locked_do_ship: int, name: string, no_discount: int, order_id: int, original_price: float, parent_item: any, parent_item_id: int, price: float, price_incl_tax: float, product_id: int, product_option: record, product_type: string, qty_backordered: float, qty_canceled: float, qty_invoiced: float, qty_ordered: float, qty_refunded: float, qty_returned: float, qty_shipped: float, quote_item_id: int, row_invoiced: float, row_total: float, row_total_incl_tax: float, row_weight: float, sku: string, store_id: int, tax_amount: float, tax_before_discount: float, tax_canceled: float, tax_invoiced: float, tax_percent: float, tax_refunded: float, updated_at: string, weee_tax_applied: string, weee_tax_applied_amount: float, weee_tax_applied_row_amount: float, weee_tax_disposition: float, weee_tax_row_disposition: float, weight: float>, order_currency_code: string, original_increment_id: string, payment: record<account_status: string, additional_data: string, additional_information: list<string>, address_status: string, amount_authorized: float, amount_canceled: float, amount_ordered: float, amount_paid: float, amount_refunded: float, anet_trans_method: string, base_amount_authorized: float, base_amount_canceled: float, base_amount_ordered: float, base_amount_paid: float, base_amount_paid_online: float, base_amount_refunded: float, base_amount_refunded_online: float, base_shipping_amount: float, base_shipping_captured: float, base_shipping_refunded: float, cc_approval: string, cc_avs_status: string, cc_cid_status: string, cc_debug_request_body: string, cc_debug_response_body: string, cc_debug_response_serialized: string, cc_exp_month: string, cc_exp_year: string, cc_last4: string, cc_number_enc: string, cc_owner: string, cc_secure_verify: string, cc_ss_issue: string, cc_ss_start_month: string, cc_ss_start_year: string, cc_status: string, cc_status_description: string, cc_trans_id: string, cc_type: string, echeck_account_name: string, echeck_account_type: string, echeck_bank_name: string, echeck_routing_number: string, echeck_type: string, entity_id: int, extension_attributes: record<vault_payment_token: record>, last_trans_id: string, method: string, parent_id: int, po_number: string, protection_eligibility: string, quote_payment_id: int, shipping_amount: float, shipping_captured: float, shipping_refunded: float>, payment_auth_expiration: int, payment_authorization_amount: float, protect_code: string, quote_address_id: int, quote_id: int, relation_child_id: string, relation_child_real_id: string, relation_parent_id: string, relation_parent_real_id: string, remote_ip: string, shipping_amount: float, shipping_canceled: float, shipping_description: string, shipping_discount_amount: float, shipping_discount_tax_compensation_amount: float, shipping_incl_tax: float, shipping_invoiced: float, shipping_refunded: float, shipping_tax_amount: float, shipping_tax_refunded: float, state: string, status: string, status_histories: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, store_currency_code: string, store_id: int, store_name: string, store_to_base_rate: float, store_to_order_rate: float, subtotal: float, subtotal_canceled: float, subtotal_incl_tax: float, subtotal_invoiced: float, subtotal_refunded: float, tax_amount: float, tax_canceled: float, tax_invoiced: float, tax_refunded: float, total_canceled: float, total_due: float, total_invoiced: float, total_item_count: int, total_offline_refunded: float, total_online_refunded: float, total_paid: float, total_qty_ordered: float, total_refunded: float, updated_at: string, weight: float, x_forwarded_for: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/cancel
#
# POST /V1/orders/{id}/cancel
# operationId: salesOrderManagementV1CancelPost
export def "v1-orders-cancel salesOrderManagementV1CancelPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/cancel")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/comments
#
# GET /V1/orders/{id}/comments
# operationId: salesOrderManagementV1GetCommentsListGet
export def "v1-orders-comments salesOrderManagementV1GetCommentsListGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, entity_name: string, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/comments
#
# POST /V1/orders/{id}/comments
# operationId: salesOrderManagementV1AddCommentPost
# --statusHistory shape: {comment: string, created_at?: string, entity_id?: int, entity_name?: string, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status?: string}
export def "v1-orders-comments salesOrderManagementV1AddCommentPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  statusHistory: record # Order status history interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {comment: string, created_at?: string, entity_id?: int, entity_name?: string, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int, status?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/comments")
  let body = {statusHistory: $statusHistory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# orders/{id}/emails
#
# POST /V1/orders/{id}/emails
# operationId: salesOrderManagementV1NotifyPost
export def "v1-orders-emails salesOrderManagementV1NotifyPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/hold
#
# POST /V1/orders/{id}/hold
# operationId: salesOrderManagementV1HoldPost
export def "v1-orders-hold salesOrderManagementV1HoldPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/hold")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/statuses
#
# GET /V1/orders/{id}/statuses
# operationId: salesOrderManagementV1GetStatusGet
export def "v1-orders-statuses salesOrderManagementV1GetStatusGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/statuses")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{id}/unhold
#
# POST /V1/orders/{id}/unhold
# operationId: salesOrderManagementV1UnHoldPost
export def "v1-orders-unhold salesOrderManagementV1UnHoldPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($id)/unhold")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# orders/{parent_id}
#
# PUT /V1/orders/{parent_id}
# operationId: salesOrderAddressRepositoryV1SavePut
# --entity shape: {address_type: string, city: string, company?: string, country_id: string, customer_address_id?: int, customer_id?: int, email?: string, entity_id?: int, extension_attributes?: record, fax?: string, firstname: string, lastname: string, middlename?: string, parent_id?: int, postcode: string, prefix?: string, region?: string, region_code?: string, region_id?: int, street?: list, suffix?: string, telephone: string, vat_id?: string, vat_is_valid?: int, vat_request_date?: string, vat_request_id?: string, vat_request_success?: int}
export def "v1-orders salesOrderAddressRepositoryV1SavePut" [
  parent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Order address interface. An order is a document that a web store issues to a customer. Magento generates a sales order that lists the product items, billing and shipping addresses, and shipping and payment methods. A corresponding external document, known as a purchase order, is emailed to the customer. — shape: {address_type: string, city: string, company?: string, country_id: string, customer_address_id?: int, customer_id?: int, email?: string, entity_id?: int, extension_attributes?: record, fax?: string, firstname: string, lastname: string, middlename?: string, parent_id?: int, postcode: string, prefix?: string, region?: string, region_code?: string, region_id?: int, street?: list, suffix?: string, telephone: string, vat_id?: string, vat_is_valid?: int, vat_request_date?: string, vat_request_id?: string, vat_request_success?: int}
]: any -> record<address_type: string, city: string, company: string, country_id: string, customer_address_id: int, customer_id: int, email: string, entity_id: int, extension_attributes: record<checkout_fields: list<record>>, fax: string, firstname: string, lastname: string, middlename: string, parent_id: int, postcode: string, prefix: string, region: string, region_code: string, region_id: int, street: list<string>, suffix: string, telephone: string, vat_id: string, vat_is_valid: int, vat_request_date: string, vat_request_id: string, vat_request_success: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/orders/($parent_id)")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products
#
# GET /V1/products
# operationId: catalogProductRepositoryV1GetListGet
export def "v1-products catalogProductRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, created_at: string, custom_attributes: list, extension_attributes: record, id: int, media_gallery_entries: list, name: string, options: list, price: float, product_links: list, sku: string, status: int, tier_prices: list, type_id: string, updated_at: string, visibility: int, weight: float>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products
#
# POST /V1/products
# operationId: catalogProductRepositoryV1SavePost
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-products catalogProductRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
  --saveOptions: oneof<nothing, bool>
]: any -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products")
  let body = {product: $product, saveOptions: $saveOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products-render-info
#
# GET /V1/products-render-info
# operationId: catalogProductRenderListV1GetListGet
export def "v1-products-render-info catalogProductRenderListV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
  --storeId: int
  --currencyCode: string
]: nothing -> record<items: table<add_to_cart_button: record, add_to_compare_button: record, currency_code: string, extension_attributes: record, id: int, images: list, is_salable: string, name: string, price_info: record, store_id: int, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar") (serialize-qp "storeId" $storeId "scalar") (serialize-qp "currencyCode" $currencyCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products-render-info" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets
#
# POST /V1/products/attribute-sets
# operationId: catalogAttributeSetManagementV1CreatePost
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-products-attribute-sets catalogAttributeSetManagementV1CreatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attributeSet: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
  skeletonId: int
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets")
  let body = {attributeSet: $attributeSet, skeletonId: $skeletonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attribute-sets/attributes
#
# POST /V1/products/attribute-sets/attributes
# operationId: catalogProductAttributeManagementV1AssignPost
export def "v1-products-attribute-sets-attributes catalogProductAttributeManagementV1AssignPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attributeCode: string
  attributeGroupId: int
  attributeSetId: int
  sortOrder: int
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets/attributes")
  let body = {attributeCode: $attributeCode, attributeGroupId: $attributeGroupId, attributeSetId: $attributeSetId, sortOrder: $sortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attribute-sets/groups
#
# POST /V1/products/attribute-sets/groups
# operationId: catalogProductAttributeGroupRepositoryV1SavePost
# --group shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
export def "v1-products-attribute-sets-groups catalogProductAttributeGroupRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  group: record # Interface AttributeGroupInterface — shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
]: any -> record<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record<attribute_group_code: string, sort_order: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attribute-sets/groups")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attribute-sets/groups/list
#
# GET /V1/products/attribute-sets/groups/list
# operationId: catalogProductAttributeGroupRepositoryV1GetListGet
export def "v1-products-attribute-sets-groups-list catalogProductAttributeGroupRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attribute-sets/groups/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/groups/{groupId}
#
# DELETE /V1/products/attribute-sets/groups/{groupId}
# operationId: catalogProductAttributeGroupRepositoryV1DeleteByIdDelete
export def "v1-products-attribute-sets-groups catalogProductAttributeGroupRepositoryV1DeleteByIdDelete" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/groups/($groupId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/sets/list
#
# GET /V1/products/attribute-sets/sets/list
# operationId: catalogAttributeSetRepositoryV1GetListGet
export def "v1-products-attribute-sets-sets-list catalogAttributeSetRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attribute-sets/sets/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# DELETE /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1DeleteByIdDelete
export def "v1-products-attribute-sets catalogAttributeSetRepositoryV1DeleteByIdDelete" [
  attributeSetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# GET /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1GetGet
export def "v1-products-attribute-sets catalogAttributeSetRepositoryV1GetGet" [
  attributeSetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}
#
# PUT /V1/products/attribute-sets/{attributeSetId}
# operationId: catalogAttributeSetRepositoryV1SavePut
# --attributeSet shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
export def "v1-products-attribute-sets catalogAttributeSetRepositoryV1SavePut" [
  attributeSetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attributeSet: record # Interface AttributeSetInterface — shape: {attribute_set_id?: int, attribute_set_name: string, entity_type_id?: int, extension_attributes?: record, sort_order: int}
]: any -> record<attribute_set_id: int, attribute_set_name: string, entity_type_id: int, extension_attributes: record, sort_order: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)")
  let body = {attributeSet: $attributeSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attribute-sets/{attributeSetId}/attributes
#
# GET /V1/products/attribute-sets/{attributeSetId}/attributes
# operationId: catalogProductAttributeManagementV1GetAttributesGet
export def "v1-products-attribute-sets-attributes catalogProductAttributeManagementV1GetAttributesGet" [
  attributeSetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list<record>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list<record>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list<record>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)/attributes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}/attributes/{attributeCode}
#
# DELETE /V1/products/attribute-sets/{attributeSetId}/attributes/{attributeCode}
# operationId: catalogProductAttributeManagementV1UnassignDelete
export def "v1-products-attribute-sets-attributes catalogProductAttributeManagementV1UnassignDelete" [
  attributeSetId: string
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)/attributes/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attribute-sets/{attributeSetId}/groups
#
# PUT /V1/products/attribute-sets/{attributeSetId}/groups
# operationId: catalogProductAttributeGroupRepositoryV1SavePut
# --group shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
export def "v1-products-attribute-sets-groups catalogProductAttributeGroupRepositoryV1SavePut" [
  attributeSetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  group: record # Interface AttributeGroupInterface — shape: {attribute_group_id?: string, attribute_group_name?: string, attribute_set_id?: int, extension_attributes?: record}
]: any -> record<attribute_group_id: string, attribute_group_name: string, attribute_set_id: int, extension_attributes: record<attribute_group_code: string, sort_order: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attribute-sets/($attributeSetId)/groups")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attributes
#
# GET /V1/products/attributes
# operationId: catalogProductAttributeRepositoryV1GetListGet
export def "v1-products-attributes catalogProductAttributeRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<apply_to: list, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/products/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attributes
#
# POST /V1/products/attributes
# operationId: catalogProductAttributeRepositoryV1SavePost
# --attribute shape: {apply_to?: list, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, is_searchable?: string, is_unique?: string, is_used_for_promo_rules?: string, is_used_in_grid?: bool, is_user_defined?: bool, is_visible?: bool, is_visible_in_advanced_search?: string, is_visible_in_grid?: bool, is_visible_on_front?: string, is_wysiwyg_enabled?: bool, note?: string, options?: list, position?: int, scope?: string, source_model?: string, used_for_sort_by?: bool, used_in_product_listing?: string, validation_rules?: list}
export def "v1-products-attributes catalogProductAttributeRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attribute: record # shape: {apply_to?: list, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, is_searchable?: string, is_unique?: string, is_used_for_promo_rules?: string, is_used_in_grid?: bool, is_user_defined?: bool, is_visible?: bool, is_visible_in_advanced_search?: string, is_visible_in_grid?: bool, is_visible_on_front?: string, is_wysiwyg_enabled?: bool, note?: string, options?: list, position?: int, scope?: string, source_model?: string, used_for_sort_by?: bool, used_in_product_listing?: string, validation_rules?: list}
]: any -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attributes")
  let body = {attribute: $attribute} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attributes/types
#
# GET /V1/products/attributes/types
# operationId: catalogProductAttributeTypesListV1GetItemsGet
export def "v1-products-attributes-types catalogProductAttributeTypesListV1GetItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, label: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/attributes/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# DELETE /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1DeleteByIdDelete
export def "v1-products-attributes catalogProductAttributeRepositoryV1DeleteByIdDelete" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# GET /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1GetGet
export def "v1-products-attributes catalogProductAttributeRepositoryV1GetGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}
#
# PUT /V1/products/attributes/{attributeCode}
# operationId: catalogProductAttributeRepositoryV1SavePut
# --attribute shape: {apply_to?: list, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, is_searchable?: string, is_unique?: string, is_used_for_promo_rules?: string, is_used_in_grid?: bool, is_user_defined?: bool, is_visible?: bool, is_visible_in_advanced_search?: string, is_visible_in_grid?: bool, is_visible_on_front?: string, is_wysiwyg_enabled?: bool, note?: string, options?: list, position?: int, scope?: string, source_model?: string, used_for_sort_by?: bool, used_in_product_listing?: string, validation_rules?: list}
export def "v1-products-attributes catalogProductAttributeRepositoryV1SavePut" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  attribute: record # shape: {apply_to?: list, attribute_code: string, attribute_id?: int, backend_model?: string, backend_type?: string, custom_attributes?: list, default_frontend_label?: string, default_value?: string, entity_type_id: string, extension_attributes?: record, frontend_class?: string, frontend_input: string, frontend_labels: list, is_comparable?: string, is_filterable?: bool, is_filterable_in_grid?: bool, is_filterable_in_search?: bool, is_html_allowed_on_front?: bool, is_required: bool, is_searchable?: string, is_unique?: string, is_used_for_promo_rules?: string, is_used_in_grid?: bool, is_user_defined?: bool, is_visible?: bool, is_visible_in_advanced_search?: string, is_visible_in_grid?: bool, is_visible_on_front?: string, is_wysiwyg_enabled?: bool, note?: string, options?: list, position?: int, scope?: string, source_model?: string, used_for_sort_by?: bool, used_in_product_listing?: string, validation_rules?: list}
]: any -> record<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: table<attribute_code: string, value: string>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: table<label: string, store_id: int>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: table<is_default: bool, label: string, sort_order: int, store_labels: list, value: string>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)")
  let body = {attribute: $attribute} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attributes/{attributeCode}/options
#
# GET /V1/products/attributes/{attributeCode}/options
# operationId: catalogProductAttributeOptionManagementV1GetItemsGet
export def "v1-products-attributes-options catalogProductAttributeOptionManagementV1GetItemsGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<is_default: bool, label: string, sort_order: int, store_labels: list<record>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)/options")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/attributes/{attributeCode}/options
#
# POST /V1/products/attributes/{attributeCode}/options
# operationId: catalogProductAttributeOptionManagementV1AddPost
# --option shape: {is_default?: bool, label: string, sort_order?: int, store_labels?: list, value: string}
export def "v1-products-attributes-options catalogProductAttributeOptionManagementV1AddPost" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # Created from: — shape: {is_default?: bool, label: string, sort_order?: int, store_labels?: list, value: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)/options")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/attributes/{attributeCode}/options/{optionId}
#
# DELETE /V1/products/attributes/{attributeCode}/options/{optionId}
# operationId: catalogProductAttributeOptionManagementV1DeleteDelete
export def "v1-products-attributes-options catalogProductAttributeOptionManagementV1DeleteDelete" [
  attributeCode: string
  optionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/attributes/($attributeCode)/options/($optionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/base-prices
#
# POST /V1/products/base-prices
# operationId: catalogBasePriceStorageV1UpdatePost
# --prices item shape: {extension_attributes?: record, price: float, sku: string, store_id: int}
export def "v1-products-base-prices catalogBasePriceStorageV1UpdatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/base-prices")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/base-prices-information
#
# POST /V1/products/base-prices-information
# operationId: catalogBasePriceStorageV1GetPost
export def "v1-products-base-prices-information catalogBasePriceStorageV1GetPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  skus: list
]: any -> table<extension_attributes: record, price: float, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/base-prices-information")
  let body = {skus: $skus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/cost
#
# POST /V1/products/cost
# operationId: catalogCostStorageV1UpdatePost
# --prices item shape: {cost: float, extension_attributes?: record, sku: string, store_id: int}
export def "v1-products-cost catalogCostStorageV1UpdatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {cost: float, extension_attributes?: record, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/cost-delete
#
# POST /V1/products/cost-delete
# operationId: catalogCostStorageV1DeletePost
export def "v1-products-cost-delete catalogCostStorageV1DeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  skus: list
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost-delete")
  let body = {skus: $skus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/cost-information
#
# POST /V1/products/cost-information
# operationId: catalogCostStorageV1GetPost
export def "v1-products-cost-information catalogCostStorageV1GetPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  skus: list
]: any -> table<cost: float, extension_attributes: record, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/cost-information")
  let body = {skus: $skus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/downloadable-links/samples/{id}
#
# DELETE /V1/products/downloadable-links/samples/{id}
# operationId: downloadableSampleRepositoryV1DeleteDelete
export def "v1-products-downloadable-links-samples downloadableSampleRepositoryV1DeleteDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/downloadable-links/samples/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/downloadable-links/{id}
#
# DELETE /V1/products/downloadable-links/{id}
# operationId: downloadableLinkRepositoryV1DeleteDelete
export def "v1-products-downloadable-links downloadableLinkRepositoryV1DeleteDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/downloadable-links/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/links/types
#
# GET /V1/products/links/types
# operationId: catalogProductLinkTypeListV1GetItemsGet
export def "v1-products-links-types catalogProductLinkTypeListV1GetItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: int, extension_attributes: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/links/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/links/{type}/attributes
#
# GET /V1/products/links/{type}/attributes
# operationId: catalogProductLinkTypeListV1GetItemAttributesGet
export def "v1-products-links-attributes catalogProductLinkTypeListV1GetItemAttributesGet" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/links/($type)/attributes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/media/types/{attributeSetName}
#
# GET /V1/products/media/types/{attributeSetName}
# operationId: catalogProductMediaAttributeManagementV1GetListGet
export def "v1-products-media-types catalogProductMediaAttributeManagementV1GetListGet" [
  attributeSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<apply_to: list<string>, attribute_code: string, attribute_id: int, backend_model: string, backend_type: string, custom_attributes: list<record>, default_frontend_label: string, default_value: string, entity_type_id: string, extension_attributes: record, frontend_class: string, frontend_input: string, frontend_labels: list<record>, is_comparable: string, is_filterable: bool, is_filterable_in_grid: bool, is_filterable_in_search: bool, is_html_allowed_on_front: bool, is_required: bool, is_searchable: string, is_unique: string, is_used_for_promo_rules: string, is_used_in_grid: bool, is_user_defined: bool, is_visible: bool, is_visible_in_advanced_search: string, is_visible_in_grid: bool, is_visible_on_front: string, is_wysiwyg_enabled: bool, note: string, options: list<record>, position: int, scope: string, source_model: string, used_for_sort_by: bool, used_in_product_listing: string, validation_rules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/media/types/($attributeSetName)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/options
#
# POST /V1/products/options
# operationId: catalogProductCustomOptionRepositoryV1SavePost
# --option shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
export def "v1-products-options catalogProductCustomOptionRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
]: any -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/options")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/options/types
#
# GET /V1/products/options/types
# operationId: catalogProductCustomOptionTypeListV1GetItemsGet
export def "v1-products-options-types catalogProductCustomOptionTypeListV1GetItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, group: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/options/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/options/{optionId}
#
# PUT /V1/products/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1SavePut
# --option shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
export def "v1-products-options catalogProductCustomOptionRepositoryV1SavePut" [
  optionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  option: record # shape: {extension_attributes?: record, file_extension?: string, image_size_x?: int, image_size_y?: int, is_require: bool, max_characters?: int, option_id?: int, price?: float, price_type?: string, product_sku: string, sku?: string, sort_order: int, title: string, type: string, values?: list}
]: any -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/options/($optionId)")
  let body = {option: $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/special-price
#
# POST /V1/products/special-price
# operationId: catalogSpecialPriceStorageV1UpdatePost
# --prices item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
export def "v1-products-special-price catalogSpecialPriceStorageV1UpdatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/special-price-delete
#
# POST /V1/products/special-price-delete
# operationId: catalogSpecialPriceStorageV1DeletePost
# --prices item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
export def "v1-products-special-price-delete catalogSpecialPriceStorageV1DeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {extension_attributes?: record, price: float, price_from: string, price_to: string, sku: string, store_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price-delete")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/special-price-information
#
# POST /V1/products/special-price-information
# operationId: catalogSpecialPriceStorageV1GetPost
export def "v1-products-special-price-information catalogSpecialPriceStorageV1GetPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  skus: list
]: any -> table<extension_attributes: record, price: float, price_from: string, price_to: string, sku: string, store_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/special-price-information")
  let body = {skus: $skus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/tier-prices
#
# POST /V1/products/tier-prices
# operationId: catalogTierPriceStorageV1UpdatePost
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices catalogTierPriceStorageV1UpdatePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/tier-prices
#
# PUT /V1/products/tier-prices
# operationId: catalogTierPriceStorageV1ReplacePut
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices catalogTierPriceStorageV1ReplacePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/tier-prices-delete
#
# POST /V1/products/tier-prices-delete
# operationId: catalogTierPriceStorageV1DeletePost
# --prices item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
export def "v1-products-tier-prices-delete catalogTierPriceStorageV1DeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prices: list # item shape: {customer_group: string, extension_attributes?: record, price: float, price_type: string, quantity: float, sku: string, website_id: int}
]: any -> table<extension_attributes: record, message: string, parameters: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices-delete")
  let body = {prices: $prices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/tier-prices-information
#
# POST /V1/products/tier-prices-information
# operationId: catalogTierPriceStorageV1GetPost
export def "v1-products-tier-prices-information catalogTierPriceStorageV1GetPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  skus: list
]: any -> table<customer_group: string, extension_attributes: record, price: float, price_type: string, quantity: float, sku: string, website_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/tier-prices-information")
  let body = {skus: $skus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/types
#
# GET /V1/products/types
# operationId: catalogProductTypeListV1GetProductTypesGet
export def "v1-products-types catalogProductTypeListV1GetProductTypesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, label: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/products/types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{productSku}/stockItems/{itemId}
#
# PUT /V1/products/{productSku}/stockItems/{itemId}
# operationId: catalogInventoryStockRegistryV1UpdateStockItemBySkuPut
# --stockItem shape: {backorders: int, enable_qty_increments: bool, extension_attributes?: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id?: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id?: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id?: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool}
export def "v1-products-stock-items catalogInventoryStockRegistryV1UpdateStockItemBySkuPut" [
  productSku: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  stockItem: record # Interface StockItem — shape: {backorders: int, enable_qty_increments: bool, extension_attributes?: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id?: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id?: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id?: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($productSku)/stockItems/($itemId)")
  let body = {stockItem: $stockItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}
#
# DELETE /V1/products/{sku}
# operationId: catalogProductRepositoryV1DeleteByIdDelete
export def "v1-products catalogProductRepositoryV1DeleteByIdDelete" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}
#
# GET /V1/products/{sku}
# operationId: catalogProductRepositoryV1GetGet
export def "v1-products catalogProductRepositoryV1GetGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --editMode: oneof<nothing, bool>
  --storeId: int
  --forceReload: oneof<nothing, bool>
]: nothing -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editMode" $editMode "scalar") (serialize-qp "storeId" $storeId "scalar") (serialize-qp "forceReload" $forceReload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/products/($sku)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}
#
# PUT /V1/products/{sku}
# operationId: catalogProductRepositoryV1SavePut
# --product shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-products catalogProductRepositoryV1SavePut" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  product: record # shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
  --saveOptions: oneof<nothing, bool>
]: any -> record<attribute_set_id: int, created_at: string, custom_attributes: table<attribute_code: string, value: string>, extension_attributes: record<bundle_product_options: list<record>, category_links: list<record>, configurable_product_links: list<int>, configurable_product_options: list<record>, downloadable_product_links: list<record>, downloadable_product_samples: list<record>, giftcard_amounts: list<record>, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, website_ids: list<int>>, id: int, media_gallery_entries: table<content: record, disabled: bool, extension_attributes: record, file: string, id: int, label: string, media_type: string, position: int, types: list>, name: string, options: table<extension_attributes: record, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list>, price: float, product_links: table<extension_attributes: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string>, sku: string, status: int, tier_prices: table<customer_group_id: int, extension_attributes: record, qty: float, value: float>, type_id: string, updated_at: string, visibility: int, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)")
  let body = {product: $product, saveOptions: $saveOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/downloadable-links
#
# GET /V1/products/{sku}/downloadable-links
# operationId: downloadableLinkRepositoryV1GetListGet
export def "v1-products-downloadable-links downloadableLinkRepositoryV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, id: int, is_shareable: int, link_file: string, link_file_content: record<extension_attributes: record, file_data: string, name: string>, link_type: string, link_url: string, number_of_downloads: int, price: float, sample_file: string, sample_file_content: record<extension_attributes: record, file_data: string, name: string>, sample_type: string, sample_url: string, sort_order: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/downloadable-links
#
# POST /V1/products/{sku}/downloadable-links
# operationId: downloadableLinkRepositoryV1SavePost
# --link shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
export def "v1-products-downloadable-links downloadableLinkRepositoryV1SavePost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --isGlobalScopeContent: oneof<nothing, bool>
  link: record # shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links")
  let body = {isGlobalScopeContent: $isGlobalScopeContent, link: $link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/downloadable-links/samples
#
# GET /V1/products/{sku}/downloadable-links/samples
# operationId: downloadableSampleRepositoryV1GetListGet
export def "v1-products-downloadable-links-samples downloadableSampleRepositoryV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record, id: int, sample_file: string, sample_file_content: record<extension_attributes: record, file_data: string, name: string>, sample_type: string, sample_url: string, sort_order: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links/samples")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/downloadable-links/samples
#
# POST /V1/products/{sku}/downloadable-links/samples
# operationId: downloadableSampleRepositoryV1SavePost
# --sample shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
export def "v1-products-downloadable-links-samples downloadableSampleRepositoryV1SavePost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --isGlobalScopeContent: oneof<nothing, bool>
  sample: record # shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links/samples")
  let body = {isGlobalScopeContent: $isGlobalScopeContent, sample: $sample} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/downloadable-links/samples/{id}
#
# PUT /V1/products/{sku}/downloadable-links/samples/{id}
# operationId: downloadableSampleRepositoryV1SavePut
# --sample shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
export def "v1-products-downloadable-links-samples downloadableSampleRepositoryV1SavePut" [
  sku: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --isGlobalScopeContent: oneof<nothing, bool>
  sample: record # shape: {extension_attributes?: record, id?: int, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links/samples/($id)")
  let body = {isGlobalScopeContent: $isGlobalScopeContent, sample: $sample} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/downloadable-links/{id}
#
# PUT /V1/products/{sku}/downloadable-links/{id}
# operationId: downloadableLinkRepositoryV1SavePut
# --link shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
export def "v1-products-downloadable-links downloadableLinkRepositoryV1SavePut" [
  sku: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --isGlobalScopeContent: oneof<nothing, bool>
  link: record # shape: {extension_attributes?: record, id?: int, is_shareable: int, link_file?: string, link_file_content?: record, link_type: string, link_url?: string, number_of_downloads?: int, price: float, sample_file?: string, sample_file_content?: record, sample_type: string, sample_url?: string, sort_order: int, title?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/downloadable-links/($id)")
  let body = {isGlobalScopeContent: $isGlobalScopeContent, link: $link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/group-prices/{customerGroupId}/tiers
#
# GET /V1/products/{sku}/group-prices/{customerGroupId}/tiers
# operationId: catalogProductTierPriceManagementV1GetListGet
export def "v1-products-group-prices-tiers catalogProductTierPriceManagementV1GetListGet" [
  sku: string
  customerGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<customer_group_id: int, extension_attributes: record<percentage_value: float, website_id: int>, qty: float, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/group-prices/($customerGroupId)/tiers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/group-prices/{customerGroupId}/tiers/{qty}
#
# DELETE /V1/products/{sku}/group-prices/{customerGroupId}/tiers/{qty}
# operationId: catalogProductTierPriceManagementV1RemoveDelete
export def "v1-products-group-prices-tiers catalogProductTierPriceManagementV1RemoveDelete" [
  sku: string
  customerGroupId: string
  qty: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/group-prices/($customerGroupId)/tiers/($qty)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/group-prices/{customerGroupId}/tiers/{qty}/price/{price}
#
# POST /V1/products/{sku}/group-prices/{customerGroupId}/tiers/{qty}/price/{price}
# operationId: catalogProductTierPriceManagementV1AddPost
export def "v1-products-group-prices-tiers-price catalogProductTierPriceManagementV1AddPost" [
  sku: string
  customerGroupId: string
  price: float
  qty: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/group-prices/($customerGroupId)/tiers/($qty)/price/($price)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/links
#
# POST /V1/products/{sku}/links
# operationId: catalogProductLinkManagementV1SetProductLinksPost
# --items item shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
export def "v1-products-links catalogProductLinkManagementV1SetProductLinksPost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  items: list # item shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/links")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/links
#
# PUT /V1/products/{sku}/links
# operationId: catalogProductLinkRepositoryV1SavePut
# --entity shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
export def "v1-products-links catalogProductLinkRepositoryV1SavePut" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # shape: {extension_attributes?: record, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/links")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/links/{type}
#
# GET /V1/products/{sku}/links/{type}
# operationId: catalogProductLinkManagementV1GetLinkedItemsByTypeGet
export def "v1-products-links catalogProductLinkManagementV1GetLinkedItemsByTypeGet" [
  sku: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<qty: float>, link_type: string, linked_product_sku: string, linked_product_type: string, position: int, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/links/($type)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/links/{type}/{linkedProductSku}
#
# DELETE /V1/products/{sku}/links/{type}/{linkedProductSku}
# operationId: catalogProductLinkRepositoryV1DeleteByIdDelete
export def "v1-products-links catalogProductLinkRepositoryV1DeleteByIdDelete" [
  sku: string
  type: string
  linkedProductSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/links/($type)/($linkedProductSku)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/media
#
# GET /V1/products/{sku}/media
# operationId: catalogProductAttributeMediaGalleryManagementV1GetListGet
export def "v1-products-media catalogProductAttributeMediaGalleryManagementV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<content: record<base64_encoded_data: string, name: string, type: string>, disabled: bool, extension_attributes: record<video_content: record>, file: string, id: int, label: string, media_type: string, position: int, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/media")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/media
#
# POST /V1/products/{sku}/media
# operationId: catalogProductAttributeMediaGalleryManagementV1CreatePost
# --entry shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list}
export def "v1-products-media catalogProductAttributeMediaGalleryManagementV1CreatePost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entry: record # shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/media")
  let body = {entry: $entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/media/{entryId}
#
# DELETE /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1RemoveDelete
export def "v1-products-media catalogProductAttributeMediaGalleryManagementV1RemoveDelete" [
  sku: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/media/($entryId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/media/{entryId}
#
# GET /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1GetGet
export def "v1-products-media catalogProductAttributeMediaGalleryManagementV1GetGet" [
  sku: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<content: record<base64_encoded_data: string, name: string, type: string>, disabled: bool, extension_attributes: record<video_content: record<media_type: string, video_description: string, video_metadata: string, video_provider: string, video_title: string, video_url: string>>, file: string, id: int, label: string, media_type: string, position: int, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/media/($entryId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/media/{entryId}
#
# PUT /V1/products/{sku}/media/{entryId}
# operationId: catalogProductAttributeMediaGalleryManagementV1UpdatePut
# --entry shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list}
export def "v1-products-media catalogProductAttributeMediaGalleryManagementV1UpdatePut" [
  sku: string
  entryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entry: record # shape: {content?: record, disabled: bool, extension_attributes?: record, file?: string, id?: int, label: string, media_type: string, position: int, types: list}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/media/($entryId)")
  let body = {entry: $entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/options
#
# GET /V1/products/{sku}/options
# operationId: catalogProductCustomOptionRepositoryV1GetListGet
export def "v1-products-options catalogProductCustomOptionRepositoryV1GetListGet" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/options")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/options/{optionId}
#
# DELETE /V1/products/{sku}/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1DeleteByIdentifierDelete
export def "v1-products-options catalogProductCustomOptionRepositoryV1DeleteByIdentifierDelete" [
  sku: string
  optionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/options/($optionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/options/{optionId}
#
# GET /V1/products/{sku}/options/{optionId}
# operationId: catalogProductCustomOptionRepositoryV1GetGet
export def "v1-products-options catalogProductCustomOptionRepositoryV1GetGet" [
  sku: string
  optionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<extension_attributes: record<vertex_flex_field: string>, file_extension: string, image_size_x: int, image_size_y: int, is_require: bool, max_characters: int, option_id: int, price: float, price_type: string, product_sku: string, sku: string, sort_order: int, title: string, type: string, values: table<option_type_id: int, price: float, price_type: string, sku: string, sort_order: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/options/($optionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# products/{sku}/websites
#
# POST /V1/products/{sku}/websites
# operationId: catalogProductWebsiteLinkRepositoryV1SavePost
# --productWebsiteLink shape: {sku: string, website_id: int}
export def "v1-products-websites catalogProductWebsiteLinkRepositoryV1SavePost" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  productWebsiteLink: record # shape: {sku: string, website_id: int}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/websites")
  let body = {productWebsiteLink: $productWebsiteLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/websites
#
# PUT /V1/products/{sku}/websites
# operationId: catalogProductWebsiteLinkRepositoryV1SavePut
# --productWebsiteLink shape: {sku: string, website_id: int}
export def "v1-products-websites catalogProductWebsiteLinkRepositoryV1SavePut" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  productWebsiteLink: record # shape: {sku: string, website_id: int}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/websites")
  let body = {productWebsiteLink: $productWebsiteLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# products/{sku}/websites/{websiteId}
#
# DELETE /V1/products/{sku}/websites/{websiteId}
# operationId: catalogProductWebsiteLinkRepositoryV1DeleteByIdDelete
export def "v1-products-websites catalogProductWebsiteLinkRepositoryV1DeleteByIdDelete" [
  sku: string
  websiteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/products/($sku)/websites/($websiteId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# requisition_lists
#
# POST /V1/requisition_lists
# operationId: requisitionListRequisitionListRepositoryV1SavePost
# --requisitionList shape: {customer_id: int, description: string, extension_attributes?: record, id: int, items: list, name: string, updated_at: string}
export def "v1-requisition-lists requisitionListRequisitionListRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  requisitionList: record # Interface RequisitionListInterface — shape: {customer_id: int, description: string, extension_attributes?: record, id: int, items: list, name: string, updated_at: string}
]: any -> record<customer_id: int, description: string, extension_attributes: record, id: int, items: table<added_at: string, extension_attributes: record, id: int, options: list, qty: float, requisition_list_id: int, sku: string, store_id: int>, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/requisition_lists")
  let body = {requisitionList: $requisitionList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns
#
# GET /V1/returns
# operationId: rmaRmaManagementV1SearchGet
export def "v1-returns rmaRmaManagementV1SearchGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<comments: list, custom_attributes: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/returns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returns
#
# POST /V1/returns
# operationId: rmaRmaManagementV1SaveRmaPost
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns rmaRmaManagementV1SaveRmaPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rmaDataObject: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/returns")
  let body = {rmaDataObject: $rmaDataObject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns/{id}
#
# DELETE /V1/returns/{id}
# operationId: rmaRmaRepositoryV1DeleteDelete
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns rmaRmaRepositoryV1DeleteDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rmaDataObject: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)")
  let body = {rmaDataObject: $rmaDataObject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns/{id}
#
# GET /V1/returns/{id}
# operationId: rmaRmaRepositoryV1GetGet
export def "v1-returns rmaRmaRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returns/{id}
#
# PUT /V1/returns/{id}
# operationId: rmaRmaManagementV1SaveRmaPut
# --rmaDataObject shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
export def "v1-returns rmaRmaManagementV1SaveRmaPut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rmaDataObject: record # Interface RmaInterface — shape: {comments: list, custom_attributes?: list, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes?: record, increment_id: string, items: list, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: list}
]: any -> record<comments: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, custom_attributes: table<attribute_code: string, value: string>, customer_custom_email: string, customer_id: int, date_requested: string, entity_id: int, extension_attributes: record, increment_id: string, items: table<condition: string, entity_id: int, extension_attributes: record, order_item_id: int, qty_approved: int, qty_authorized: int, qty_requested: int, qty_returned: int, reason: string, resolution: string, rma_entity_id: int, status: string>, order_id: int, order_increment_id: string, status: string, store_id: int, tracks: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)")
  let body = {rmaDataObject: $rmaDataObject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns/{id}/comments
#
# GET /V1/returns/{id}/comments
# operationId: rmaCommentManagementV1CommentsListGet
export def "v1-returns-comments rmaCommentManagementV1CommentsListGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<admin: bool, comment: string, created_at: string, custom_attributes: list, customer_notified: bool, entity_id: int, extension_attributes: record, rma_entity_id: int, status: string, visible_on_front: bool>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returns/{id}/comments
#
# POST /V1/returns/{id}/comments
# operationId: rmaCommentManagementV1AddCommentPost
# --data shape: {admin: bool, comment: string, created_at: string, custom_attributes?: list, customer_notified: bool, entity_id: int, extension_attributes?: record, rma_entity_id: int, status: string, visible_on_front: bool}
export def "v1-returns-comments rmaCommentManagementV1AddCommentPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  data: record # Interface CommentInterface — shape: {admin: bool, comment: string, created_at: string, custom_attributes?: list, customer_notified: bool, entity_id: int, extension_attributes?: record, rma_entity_id: int, status: string, visible_on_front: bool}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/comments")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns/{id}/labels
#
# GET /V1/returns/{id}/labels
# operationId: rmaTrackManagementV1GetShippingLabelPdfGet
export def "v1-returns-labels rmaTrackManagementV1GetShippingLabelPdfGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/labels")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returns/{id}/tracking-numbers
#
# GET /V1/returns/{id}/tracking-numbers
# operationId: rmaTrackManagementV1GetTracksGet
export def "v1-returns-tracking-numbers rmaTrackManagementV1GetTracksGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<carrier_code: string, carrier_title: string, entity_id: int, extension_attributes: record, rma_entity_id: int, track_number: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/tracking-numbers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returns/{id}/tracking-numbers
#
# POST /V1/returns/{id}/tracking-numbers
# operationId: rmaTrackManagementV1AddTrackPost
# --track shape: {carrier_code: string, carrier_title: string, entity_id: int, extension_attributes?: record, rma_entity_id: int, track_number: string}
export def "v1-returns-tracking-numbers rmaTrackManagementV1AddTrackPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  track: record # Interface TrackInterface — shape: {carrier_code: string, carrier_title: string, entity_id: int, extension_attributes?: record, rma_entity_id: int, track_number: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/tracking-numbers")
  let body = {track: $track} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# returns/{id}/tracking-numbers/{trackId}
#
# DELETE /V1/returns/{id}/tracking-numbers/{trackId}
# operationId: rmaTrackManagementV1RemoveTrackByIdDelete
export def "v1-returns-tracking-numbers rmaTrackManagementV1RemoveTrackByIdDelete" [
  id: int
  trackId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returns/($id)/tracking-numbers/($trackId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata
#
# GET /V1/returnsAttributeMetadata
# operationId: rmaRmaAttributesManagementV1GetAllAttributesMetadataGet
export def "v1-returns-attribute-metadata rmaRmaAttributesManagementV1GetAllAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/returnsAttributeMetadata")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/custom
#
# GET /V1/returnsAttributeMetadata/custom
# operationId: rmaRmaAttributesManagementV1GetCustomAttributesMetadataGet
export def "v1-returns-attribute-metadata-custom rmaRmaAttributesManagementV1GetCustomAttributesMetadataGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --dataObjectClassName: string # Data object class name
]: nothing -> table<attribute_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataObjectClassName" $dataObjectClassName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/returnsAttributeMetadata/custom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/form/{formCode}
#
# GET /V1/returnsAttributeMetadata/form/{formCode}
# operationId: rmaRmaAttributesManagementV1GetAttributesGet
export def "v1-returns-attribute-metadata-form rmaRmaAttributesManagementV1GetAttributesGet" [
  formCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: list<record>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: list<record>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returnsAttributeMetadata/form/($formCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# returnsAttributeMetadata/{attributeCode}
#
# GET /V1/returnsAttributeMetadata/{attributeCode}
# operationId: rmaRmaAttributesManagementV1GetAttributeMetadataGet
export def "v1-returns-attribute-metadata rmaRmaAttributesManagementV1GetAttributeMetadataGet" [
  attributeCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<attribute_code: string, backend_type: string, data_model: string, frontend_class: string, frontend_input: string, frontend_label: string, input_filter: string, is_filterable_in_grid: bool, is_searchable_in_grid: bool, is_used_in_grid: bool, is_visible_in_grid: bool, multiline_count: int, note: string, options: table<label: string, options: list, value: string>, required: bool, sort_order: int, store_label: string, system: bool, user_defined: bool, validation_rules: table<name: string, value: string>, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/returnsAttributeMetadata/($attributeCode)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# reward/mine/use-reward
#
# POST /V1/reward/mine/use-reward
# operationId: rewardRewardManagementV1SetPost
export def "v1-reward-mine-use-reward rewardRewardManagementV1SetPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/reward/mine/use-reward")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# salesRules
#
# POST /V1/salesRules
# operationId: salesRuleRuleRepositoryV1SavePost
# --rule shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, times_used: int, to_date?: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list}
export def "v1-sales-rules salesRuleRuleRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rule: record # Interface RuleInterface — shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, times_used: int, to_date?: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list}
]: any -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/salesRules")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# salesRules/search
#
# GET /V1/salesRules/search
# operationId: salesRuleRuleRepositoryV1GetListGet
export def "v1-sales-rules-search salesRuleRuleRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<action_condition: record, apply_to_shipping: bool, condition: record, coupon_type: string, customer_group_ids: list, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: list, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/salesRules/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# DELETE /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1DeleteByIdDelete
export def "v1-sales-rules salesRuleRuleRepositoryV1DeleteByIdDelete" [
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/salesRules/($ruleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# GET /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1GetByIdGet
export def "v1-sales-rules salesRuleRuleRepositoryV1GetByIdGet" [
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/salesRules/($ruleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# salesRules/{ruleId}
#
# PUT /V1/salesRules/{ruleId}
# operationId: salesRuleRuleRepositoryV1SavePut
# --rule shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, times_used: int, to_date?: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list}
export def "v1-sales-rules salesRuleRuleRepositoryV1SavePut" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rule: record # Interface RuleInterface — shape: {action_condition?: record, apply_to_shipping: bool, condition?: record, coupon_type: string, customer_group_ids: list, description?: string, discount_amount: float, discount_qty?: float, discount_step: int, extension_attributes?: record, from_date?: string, is_active: bool, is_advanced: bool, is_rss: bool, name?: string, product_ids?: list, rule_id?: int, simple_action?: string, simple_free_shipping?: string, sort_order: int, stop_rules_processing: bool, store_labels?: list, times_used: int, to_date?: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list}
]: any -> record<action_condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, apply_to_shipping: bool, condition: record<aggregator_type: string, attribute_name: string, condition_type: string, conditions: list<any>, extension_attributes: record, operator: string, value: string>, coupon_type: string, customer_group_ids: list<int>, description: string, discount_amount: float, discount_qty: float, discount_step: int, extension_attributes: record<reward_points_delta: int>, from_date: string, is_active: bool, is_advanced: bool, is_rss: bool, name: string, product_ids: list<int>, rule_id: int, simple_action: string, simple_free_shipping: string, sort_order: int, stop_rules_processing: bool, store_labels: table<extension_attributes: record, store_id: int, store_label: string>, times_used: int, to_date: string, use_auto_generation: bool, uses_per_coupon: int, uses_per_customer: int, website_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/salesRules/($ruleId)")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# search
#
# GET /V1/search
# operationId: searchV1SearchGet
export def "v1-search searchV1SearchGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriarequestName: string
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<aggregations: record<bucket_names: list<string>, buckets: list<record>>, items: table<custom_attributes: list, id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, request_name: string, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[requestName]" $searchCriteriarequestName "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog
#
# POST /V1/sharedCatalog
# operationId: sharedCatalogSharedCatalogRepositoryV1SavePost
# --sharedCatalog shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
export def "v1-shared-catalog sharedCatalogSharedCatalogRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  sharedCatalog: record # SharedCatalogInterface interface. — shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/sharedCatalog")
  let body = {sharedCatalog: $sharedCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/
#
# GET /V1/sharedCatalog/
# operationId: sharedCatalogSharedCatalogRepositoryV1GetListGet
export def "v1-shared-catalog sharedCatalogSharedCatalogRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<created_at: string, created_by: int, customer_group_id: int, description: string, id: int, name: string, store_id: int, tax_class_id: int, type: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/sharedCatalog/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}
#
# PUT /V1/sharedCatalog/{id}
# operationId: sharedCatalogSharedCatalogRepositoryV1SavePut
# --sharedCatalog shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
export def "v1-shared-catalog sharedCatalogSharedCatalogRepositoryV1SavePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  sharedCatalog: record # SharedCatalogInterface interface. — shape: {created_at: string, created_by: int, customer_group_id: int, description: string, id?: int, name: string, store_id: int, tax_class_id: int, type: int}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)")
  let body = {sharedCatalog: $sharedCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{id}/assignCategories
#
# POST /V1/sharedCatalog/{id}/assignCategories
# operationId: sharedCatalogCategoryManagementV1AssignCategoriesPost
# --categories item shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-shared-catalog-assign-categories sharedCatalogCategoryManagementV1AssignCategoriesPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  categories: list # item shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/assignCategories")
  let body = {categories: $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{id}/assignProducts
#
# POST /V1/sharedCatalog/{id}/assignProducts
# operationId: sharedCatalogProductManagementV1AssignProductsPost
# --products item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-shared-catalog-assign-products sharedCatalogProductManagementV1AssignProductsPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  products: list # item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/assignProducts")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{id}/categories
#
# GET /V1/sharedCatalog/{id}/categories
# operationId: sharedCatalogCategoryManagementV1GetCategoriesGet
export def "v1-shared-catalog-categories sharedCatalogCategoryManagementV1GetCategoriesGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}/products
#
# GET /V1/sharedCatalog/{id}/products
# operationId: sharedCatalogProductManagementV1GetProductsGet
export def "v1-shared-catalog-products sharedCatalogProductManagementV1GetProductsGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/products")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{id}/unassignCategories
#
# POST /V1/sharedCatalog/{id}/unassignCategories
# operationId: sharedCatalogCategoryManagementV1UnassignCategoriesPost
# --categories item shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
export def "v1-shared-catalog-unassign-categories sharedCatalogCategoryManagementV1UnassignCategoriesPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  categories: list # item shape: {available_sort_by?: list, children?: string, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, include_in_menu?: bool, is_active?: bool, level?: int, name?: string, parent_id?: int, path?: string, position?: int, updated_at?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/unassignCategories")
  let body = {categories: $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{id}/unassignProducts
#
# POST /V1/sharedCatalog/{id}/unassignProducts
# operationId: sharedCatalogProductManagementV1UnassignProductsPost
# --products item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
export def "v1-shared-catalog-unassign-products sharedCatalogProductManagementV1UnassignProductsPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  products: list # item shape: {attribute_set_id?: int, created_at?: string, custom_attributes?: list, extension_attributes?: record, id?: int, media_gallery_entries?: list, name?: string, options?: list, price?: float, product_links?: list, sku: string, status?: int, tier_prices?: list, type_id?: string, updated_at?: string, visibility?: int, weight?: float}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($id)/unassignProducts")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{sharedCatalogId}
#
# DELETE /V1/sharedCatalog/{sharedCatalogId}
# operationId: sharedCatalogSharedCatalogRepositoryV1DeleteByIdDelete
export def "v1-shared-catalog sharedCatalogSharedCatalogRepositoryV1DeleteByIdDelete" [
  sharedCatalogId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($sharedCatalogId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}
#
# GET /V1/sharedCatalog/{sharedCatalogId}
# operationId: sharedCatalogSharedCatalogRepositoryV1GetGet
export def "v1-shared-catalog sharedCatalogSharedCatalogRepositoryV1GetGet" [
  sharedCatalogId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, created_by: int, customer_group_id: int, description: string, id: int, name: string, store_id: int, tax_class_id: int, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($sharedCatalogId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}/assignCompanies
#
# POST /V1/sharedCatalog/{sharedCatalogId}/assignCompanies
# operationId: sharedCatalogCompanyManagementV1AssignCompaniesPost
# --companies item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-shared-catalog-assign-companies sharedCatalogCompanyManagementV1AssignCompaniesPost" [
  sharedCatalogId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  companies: list # item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($sharedCatalogId)/assignCompanies")
  let body = {companies: $companies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# sharedCatalog/{sharedCatalogId}/companies
#
# GET /V1/sharedCatalog/{sharedCatalogId}/companies
# operationId: sharedCatalogCompanyManagementV1GetCompaniesGet
export def "v1-shared-catalog-companies sharedCatalogCompanyManagementV1GetCompaniesGet" [
  sharedCatalogId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($sharedCatalogId)/companies")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sharedCatalog/{sharedCatalogId}/unassignCompanies
#
# POST /V1/sharedCatalog/{sharedCatalogId}/unassignCompanies
# operationId: sharedCatalogCompanyManagementV1UnassignCompaniesPost
# --companies item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
export def "v1-shared-catalog-unassign-companies sharedCatalogCompanyManagementV1UnassignCompaniesPost" [
  sharedCatalogId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  companies: list # item shape: {city?: string, comment?: string, company_email?: string, company_name?: string, country_id?: string, customer_group_id: int, extension_attributes?: record, id?: int, legal_name?: string, postcode?: string, region?: string, region_id?: string, reject_reason: string, rejected_at: string, reseller_id?: string, sales_representative_id: int, status?: int, street: list, super_user_id: int, telephone?: string, vat_tax_id?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/sharedCatalog/($sharedCatalogId)/unassignCompanies")
  let body = {companies: $companies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# shipment/
#
# POST /V1/shipment/
# operationId: salesShipmentRepositoryV1SavePost
# --entity shape: {billing_address_id?: int, comments: list, created_at?: string, customer_id?: int, email_sent?: int, entity_id?: int, extension_attributes?: record, increment_id?: string, items: list, order_id: int, packages?: list, shipment_status?: int, shipping_address_id?: int, shipping_label?: string, store_id?: int, total_qty?: float, total_weight?: float, tracks: list, updated_at?: string}
export def "v1-shipment salesShipmentRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Shipment interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. — shape: {billing_address_id?: int, comments: list, created_at?: string, customer_id?: int, email_sent?: int, entity_id?: int, extension_attributes?: record, increment_id?: string, items: list, order_id: int, packages?: list, shipment_status?: int, shipping_address_id?: int, shipping_label?: string, store_id?: int, total_qty?: float, total_weight?: float, tracks: list, updated_at?: string}
]: any -> record<billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record<ext_location_id: string, ext_return_shipment_id: string, ext_shipment_id: string, ext_tracking_reference: string, ext_tracking_url: string>, increment_id: string, items: table<additional_data: string, description: string, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, product_id: int, qty: float, row_total: float, sku: string, weight: float>, order_id: int, packages: table<extension_attributes: record>, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: table<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/shipment/")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# shipment/track
#
# POST /V1/shipment/track
# operationId: salesShipmentTrackRepositoryV1SavePost
# --entity shape: {carrier_code: string, created_at?: string, description: string, entity_id?: int, extension_attributes?: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at?: string, weight: float}
export def "v1-shipment-track salesShipmentTrackRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Shipment track interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. Merchants and customers can track shipments. — shape: {carrier_code: string, created_at?: string, description: string, entity_id?: int, extension_attributes?: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at?: string, weight: float}
]: any -> record<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/shipment/track")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# shipment/track/{id}
#
# DELETE /V1/shipment/track/{id}
# operationId: salesShipmentTrackRepositoryV1DeleteByIdDelete
export def "v1-shipment-track salesShipmentTrackRepositoryV1DeleteByIdDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/track/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# shipment/{id}
#
# GET /V1/shipment/{id}
# operationId: salesShipmentRepositoryV1GetGet
export def "v1-shipment salesShipmentRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<billing_address_id: int, comments: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record<ext_location_id: string, ext_return_shipment_id: string, ext_shipment_id: string, ext_tracking_reference: string, ext_tracking_url: string>, increment_id: string, items: table<additional_data: string, description: string, entity_id: int, extension_attributes: record, name: string, order_item_id: int, parent_id: int, price: float, product_id: int, qty: float, row_total: float, sku: string, weight: float>, order_id: int, packages: table<extension_attributes: record>, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: table<carrier_code: string, created_at: string, description: string, entity_id: int, extension_attributes: record, order_id: int, parent_id: int, qty: float, title: string, track_number: string, updated_at: string, weight: float>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# shipment/{id}/comments
#
# GET /V1/shipment/{id}/comments
# operationId: salesShipmentManagementV1GetCommentsListGet
export def "v1-shipment-comments salesShipmentManagementV1GetCommentsListGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# shipment/{id}/comments
#
# POST /V1/shipment/{id}/comments
# operationId: salesShipmentCommentRepositoryV1SavePost
# --entity shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
export def "v1-shipment-comments salesShipmentCommentRepositoryV1SavePost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  entity: record # Shipment comment interface. A shipment is a delivery package that contains products. A shipment document accompanies the shipment. This document lists the products and their quantities in the delivery package. A shipment document can contain comments. — shape: {comment: string, created_at?: string, entity_id?: int, extension_attributes?: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int}
]: any -> record<comment: string, created_at: string, entity_id: int, extension_attributes: record, is_customer_notified: int, is_visible_on_front: int, parent_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/($id)/comments")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# shipment/{id}/emails
#
# POST /V1/shipment/{id}/emails
# operationId: salesShipmentManagementV1NotifyPost
export def "v1-shipment-emails salesShipmentManagementV1NotifyPost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/($id)/emails")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# shipment/{id}/label
#
# GET /V1/shipment/{id}/label
# operationId: salesShipmentManagementV1GetLabelGet
export def "v1-shipment-label salesShipmentManagementV1GetLabelGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/shipment/($id)/label")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# shipments
#
# GET /V1/shipments
# operationId: salesShipmentRepositoryV1GetListGet
export def "v1-shipments salesShipmentRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<billing_address_id: int, comments: list, created_at: string, customer_id: int, email_sent: int, entity_id: int, extension_attributes: record, increment_id: string, items: list, order_id: int, packages: list, shipment_status: int, shipping_address_id: int, shipping_label: string, store_id: int, total_qty: float, total_weight: float, tracks: list, updated_at: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/shipments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# stockItems/lowStock/
#
# GET /V1/stockItems/lowStock/
# operationId: catalogInventoryStockRegistryV1GetLowStockItemsGet
export def "v1-stock-items-low-stock catalogInventoryStockRegistryV1GetLowStockItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --scopeId: int
  --qty: float
  --currentPage: int
  --pageSize: int
]: nothing -> record<items: table<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, search_criteria: record<criteria_list: list<record>, filters: list<string>, limit: list<string>, mapper_interface_name: string, orders: list<string>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scopeId "scalar") (serialize-qp "qty" $qty "scalar") (serialize-qp "currentPage" $currentPage "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/stockItems/lowStock/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# stockItems/{productSku}
#
# GET /V1/stockItems/{productSku}
# operationId: catalogInventoryStockRegistryV1GetStockItemBySkuGet
export def "v1-stock-items catalogInventoryStockRegistryV1GetStockItemBySkuGet" [
  productSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --scopeId: int
]: nothing -> record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scopeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/stockItems/($productSku)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# stockStatuses/{productSku}
#
# GET /V1/stockStatuses/{productSku}
# operationId: catalogInventoryStockRegistryV1GetStockStatusBySkuGet
export def "v1-stock-statuses catalogInventoryStockRegistryV1GetStockStatusBySkuGet" [
  productSku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --scopeId: int
]: nothing -> record<extension_attributes: record, product_id: int, qty: int, stock_id: int, stock_item: record<backorders: int, enable_qty_increments: bool, extension_attributes: record, is_decimal_divided: bool, is_in_stock: bool, is_qty_decimal: bool, item_id: int, low_stock_date: string, manage_stock: bool, max_sale_qty: float, min_qty: float, min_sale_qty: float, notify_stock_qty: float, product_id: int, qty: float, qty_increments: float, show_default_notification_message: bool, stock_id: int, stock_status_changed_auto: int, use_config_backorders: bool, use_config_enable_qty_inc: bool, use_config_manage_stock: bool, use_config_max_sale_qty: bool, use_config_min_qty: bool, use_config_min_sale_qty: int, use_config_notify_stock_qty: bool, use_config_qty_increments: bool>, stock_status: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeId" $scopeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/V1/stockStatuses/($productSku)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# store/storeConfigs
#
# GET /V1/store/storeConfigs
# operationId: storeStoreConfigManagerV1GetStoreConfigsGet
export def "v1-store-store-configs storeStoreConfigManagerV1GetStoreConfigsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --storeCodes: list
]: nothing -> table<base_currency_code: string, base_link_url: string, base_media_url: string, base_static_url: string, base_url: string, code: string, default_display_currency_code: string, extension_attributes: record, id: int, locale: string, secure_base_link_url: string, secure_base_media_url: string, secure_base_static_url: string, secure_base_url: string, timezone: string, website_id: int, weight_unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeCodes" $storeCodes "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/store/storeConfigs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# store/storeGroups
#
# GET /V1/store/storeGroups
# operationId: storeGroupRepositoryV1GetListGet
export def "v1-store-store-groups storeGroupRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, default_store_id: int, extension_attributes: record, id: int, name: string, root_category_id: int, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/storeGroups")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# store/storeViews
#
# GET /V1/store/storeViews
# operationId: storeStoreRepositoryV1GetListGet
export def "v1-store-store-views storeStoreRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, extension_attributes: record, id: int, name: string, store_group_id: int, website_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/storeViews")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# store/websites
#
# GET /V1/store/websites
# operationId: storeWebsiteRepositoryV1GetListGet
export def "v1-store-websites storeWebsiteRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<code: string, default_group_id: int, extension_attributes: record, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/store/websites")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxClasses
#
# POST /V1/taxClasses
# operationId: taxTaxClassRepositoryV1SavePost
# --taxClass shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
export def "v1-tax-classes taxTaxClassRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  taxClass: record # Tax class interface. — shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxClasses")
  let body = {taxClass: $taxClass} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxClasses/search
#
# GET /V1/taxClasses/search
# operationId: taxTaxClassRepositoryV1GetListGet
export def "v1-tax-classes-search taxTaxClassRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<class_id: int, class_name: string, class_type: string, extension_attributes: record>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxClasses/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxClasses/{classId}
#
# PUT /V1/taxClasses/{classId}
# operationId: taxTaxClassRepositoryV1SavePut
# --taxClass shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
export def "v1-tax-classes taxTaxClassRepositoryV1SavePut" [
  classId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  taxClass: record # Tax class interface. — shape: {class_id?: int, class_name: string, class_type: string, extension_attributes?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxClasses/($classId)")
  let body = {taxClass: $taxClass} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxClasses/{taxClassId}
#
# DELETE /V1/taxClasses/{taxClassId}
# operationId: taxTaxClassRepositoryV1DeleteByIdDelete
export def "v1-tax-classes taxTaxClassRepositoryV1DeleteByIdDelete" [
  taxClassId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxClasses/($taxClassId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxClasses/{taxClassId}
#
# GET /V1/taxClasses/{taxClassId}
# operationId: taxTaxClassRepositoryV1GetGet
export def "v1-tax-classes taxTaxClassRepositoryV1GetGet" [
  taxClassId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<class_id: int, class_name: string, class_type: string, extension_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxClasses/($taxClassId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRates
#
# POST /V1/taxRates
# operationId: taxTaxRateRepositoryV1SavePost
# --taxRate shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
export def "v1-tax-rates taxTaxRateRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  taxRate: record # Tax rate interface. — shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
]: any -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRates")
  let body = {taxRate: $taxRate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxRates
#
# PUT /V1/taxRates
# operationId: taxTaxRateRepositoryV1SavePut
# --taxRate shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
export def "v1-tax-rates taxTaxRateRepositoryV1SavePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  taxRate: record # Tax rate interface. — shape: {code: string, extension_attributes?: record, id?: int, rate: float, region_name?: string, tax_country_id: string, tax_postcode?: string, tax_region_id?: int, titles?: list, zip_from?: int, zip_is_range?: int, zip_to?: int}
]: any -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRates")
  let body = {taxRate: $taxRate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxRates/search
#
# GET /V1/taxRates/search
# operationId: taxTaxRateRepositoryV1GetListGet
export def "v1-tax-rates-search taxTaxRateRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: list, zip_from: int, zip_is_range: int, zip_to: int>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxRates/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRates/{rateId}
#
# DELETE /V1/taxRates/{rateId}
# operationId: taxTaxRateRepositoryV1DeleteByIdDelete
export def "v1-tax-rates taxTaxRateRepositoryV1DeleteByIdDelete" [
  rateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxRates/($rateId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRates/{rateId}
#
# GET /V1/taxRates/{rateId}
# operationId: taxTaxRateRepositoryV1GetGet
export def "v1-tax-rates taxTaxRateRepositoryV1GetGet" [
  rateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, extension_attributes: record, id: int, rate: float, region_name: string, tax_country_id: string, tax_postcode: string, tax_region_id: int, titles: table<extension_attributes: record, store_id: string, value: string>, zip_from: int, zip_is_range: int, zip_to: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxRates/($rateId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRules
#
# POST /V1/taxRules
# operationId: taxTaxRuleRepositoryV1SavePost
# --rule shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list}
export def "v1-tax-rules taxTaxRuleRepositoryV1SavePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rule: record # Tax rule interface. — shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list}
]: any -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRules")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxRules
#
# PUT /V1/taxRules
# operationId: taxTaxRuleRepositoryV1SavePut
# --rule shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list}
export def "v1-tax-rules taxTaxRuleRepositoryV1SavePut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  rule: record # Tax rule interface. — shape: {calculate_subtotal?: bool, code: string, customer_tax_class_ids: list, extension_attributes?: record, id?: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list}
]: any -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/V1/taxRules")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# taxRules/search
#
# GET /V1/taxRules/search
# operationId: taxTaxRuleRepositoryV1GetListGet
export def "v1-tax-rules-search taxTaxRuleRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<calculate_subtotal: bool, code: string, customer_tax_class_ids: list, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list, tax_rate_ids: list>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/taxRules/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRules/{ruleId}
#
# DELETE /V1/taxRules/{ruleId}
# operationId: taxTaxRuleRepositoryV1DeleteByIdDelete
export def "v1-tax-rules taxTaxRuleRepositoryV1DeleteByIdDelete" [
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxRules/($ruleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# taxRules/{ruleId}
#
# GET /V1/taxRules/{ruleId}
# operationId: taxTaxRuleRepositoryV1GetGet
export def "v1-tax-rules taxTaxRuleRepositoryV1GetGet" [
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<calculate_subtotal: bool, code: string, customer_tax_class_ids: list<int>, extension_attributes: record, id: int, position: int, priority: int, product_tax_class_ids: list<int>, tax_rate_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/taxRules/($ruleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# team/
#
# GET /V1/team/
# operationId: companyTeamRepositoryV1GetListGet
export def "v1-team companyTeamRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<custom_attributes: list, description: string, extension_attributes: record, id: int, name: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/team/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# team/{companyId}
#
# POST /V1/team/{companyId}
# operationId: companyTeamRepositoryV1CreatePost
# --team shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
export def "v1-team companyTeamRepositoryV1CreatePost" [
  companyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  team: record # Team interface — shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
]: any -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/team/($companyId)")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# team/{teamId}
#
# DELETE /V1/team/{teamId}
# operationId: companyTeamRepositoryV1DeleteByIdDelete
export def "v1-team companyTeamRepositoryV1DeleteByIdDelete" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, errors: table<message: string, parameters: list>, message: string, parameters: table<fieldName: string, fieldValue: string, resources: string>, trace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/team/($teamId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# team/{teamId}
#
# GET /V1/team/{teamId}
# operationId: companyTeamRepositoryV1GetGet
export def "v1-team companyTeamRepositoryV1GetGet" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom_attributes: table<attribute_code: string, value: string>, description: string, extension_attributes: record, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/team/($teamId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# team/{teamId}
#
# PUT /V1/team/{teamId}
# operationId: companyTeamRepositoryV1SavePut
# --team shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
export def "v1-team companyTeamRepositoryV1SavePut" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  team: record # Team interface — shape: {custom_attributes?: list, description?: string, extension_attributes?: record, id?: int, name?: string}
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/team/($teamId)")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# temando/rma/{rmaId}/shipments
#
# PUT /V1/temando/rma/{rmaId}/shipments
# operationId: temandoShippingRmaRmaShipmentManagementV1AssignShipmentIdsPut
export def "v1-temando-rma-shipments temandoShippingRmaRmaShipmentManagementV1AssignShipmentIdsPut" [
  rmaId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  returnShipmentIds: list
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/temando/rma/($rmaId)/shipments")
  let body = {returnShipmentIds: $returnShipmentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# transactions
#
# GET /V1/transactions
# operationId: salesTransactionRepositoryV1GetListGet
export def "v1-transactions salesTransactionRepositoryV1GetListGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --searchCriteriafilterGroups0filters0field: string # Field
  --searchCriteriafilterGroups0filters0value: string # Value
  --searchCriteriafilterGroups0filters0conditionType: string # Condition type
  --searchCriteriasortOrders0field: string # Sorting field.
  --searchCriteriasortOrders0direction: string # Sorting direction.
  --searchCriteriapageSize: int # Page size.
  --searchCriteriacurrentPage: int # Current page.
]: nothing -> record<items: table<additional_information: list, child_transactions: list, created_at: string, extension_attributes: record, is_closed: int, order_id: int, parent_id: int, parent_txn_id: string, payment_id: int, transaction_id: int, txn_id: string, txn_type: string>, search_criteria: record<current_page: int, filter_groups: list<record>, page_size: int, sort_orders: list<record>>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchCriteria[filterGroups][0][filters][0][field]" $searchCriteriafilterGroups0filters0field "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][value]" $searchCriteriafilterGroups0filters0value "scalar") (serialize-qp "searchCriteria[filterGroups][0][filters][0][conditionType]" $searchCriteriafilterGroups0filters0conditionType "scalar") (serialize-qp "searchCriteria[sortOrders][0][field]" $searchCriteriasortOrders0field "scalar") (serialize-qp "searchCriteria[sortOrders][0][direction]" $searchCriteriasortOrders0direction "scalar") (serialize-qp "searchCriteria[pageSize]" $searchCriteriapageSize "scalar") (serialize-qp "searchCriteria[currentPage]" $searchCriteriacurrentPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/V1/transactions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# transactions/{id}
#
# GET /V1/transactions/{id}
# operationId: salesTransactionRepositoryV1GetGet
export def "v1-transactions salesTransactionRepositoryV1GetGet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<additional_information: list<string>, child_transactions: list<any>, created_at: string, extension_attributes: record, is_closed: int, order_id: int, parent_id: int, parent_txn_id: string, payment_id: int, transaction_id: int, txn_id: string, txn_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/transactions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# worldpay-guest-carts/{cartId}/payment-information
#
# POST /V1/worldpay-guest-carts/{cartId}/payment-information
# operationId: worldpayGuestPaymentInformationManagementProxyV1SavePaymentInformationAndPlaceOrderPost
# --billingAddress shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
# --paymentMethod shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
export def "v1-worldpay-guest-carts-payment-information worldpayGuestPaymentInformationManagementProxyV1SavePaymentInformationAndPlaceOrderPost" [
  cartId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --billingAddress: record # Interface AddressInterface — shape: {city: string, company?: string, country_id: string, custom_attributes?: list, customer_address_id?: int, customer_id?: int, email: string, extension_attributes?: record, fax?: string, firstname: string, id?: int, lastname: string, middlename?: string, postcode: string, prefix?: string, region: string, region_code: string, region_id: int, same_as_billing?: int, save_in_address_book?: int, street: list, suffix?: string, telephone: string, vat_id?: string}
  email: string
  paymentMethod: record # Interface PaymentInterface — shape: {additional_data?: list, extension_attributes?: record, method: string, po_number?: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/V1/worldpay-guest-carts/($cartId)/payment-information")
  let body = {billingAddress: $billingAddress, email: $email, paymentMethod: $paymentMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
