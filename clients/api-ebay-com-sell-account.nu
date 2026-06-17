# Auto-generated client for Account API vv1.9.0
# Source: https://api.apis.guru/v2/specs/api.ebay.com/sell-account/v1.9.0/openapi.json
# Auth: --token flag or $env.ACCOUNT_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/account/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ebay.com/sell/account/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "advertising-eligibility get" } } | get name | first)
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

# This method allows developers to check the seller eligibility status for eBay advertising programs.
#
# GET /advertising_eligibility
# operationId: getAdvertisingEligibility
export def "advertising-eligibility get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-types: string # A comma-separated list of eBay advertising programs.<br /><br /><span class="tablenote"><b>Tip:</b> See the <a href="/api-docs/sell/account/types/plser:AdvertisingProgramEnum"> AdvertisingProgramEnum</a> type for possible values.</span><br /><br />If no programs are specified, the results will be returned for all programs.
  --x-ebay-c-marketplace-id: string # The unique identifier of the eBay marketplace for which the seller eligibility status shall be checked.<br /><br /><span class="tablenote"><b>Note:</b> This value is case-sensitive.</span>
]: nothing -> record<advertisingEligibility: table<programType: string, reason: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "program_types" $program_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advertising_eligibility" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the list of custom policies specified by the <b>policy_types</b> query parameter for the selected eBay marketplace.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span><br/><br/>For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP" target="_blank">HTTP request headers</a>.
#
# GET /custom_policy/
# operationId: getCustomPolicies
export def "custom-policy get-custom-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-types: string # This query parameter specifies the type of custom policies to be returned.<br /><br />Multiple policy types may be requested in a single call by providing a comma-delimited set of all policy types to be returned.<br/><br/><span class="tablenote"><strong>Note:</strong> Omitting this query parameter from a request will also return policies of all policy types.</span><br/><br/>Two Custom Policy types are supported: <ul><li>Product Compliance (PRODUCT_COMPLIANCE)</li> <li>Takeback (TAKE_BACK)</li></ul>
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the <a href="/api-docs/sell/account/types/ba:MarketplaceIdEnum" target="_blank">MarketplaceIdEnum</a> type definition.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span>
]: nothing -> record<customPolicies: table<customPolicyId: string, label: string, name: string, policyType: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_types" $policy_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_policy/" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates a new custom policy in which a seller specifies their terms for complying with local governmental regulations. <br/><br/>Two Custom Policy types are supported: <ul><li>Product Compliance (PRODUCT_COMPLIANCE)</li> <li>Takeback (TAKE_BACK)</li></ul>Each Custom Policy targets a <b>policyType</b> and <b>eBay marketplace</b> combination. Multiple policies may be created as follows: <ul><li><b>Product Compliance</b>: a maximum of 10 policies per eBay marketplace may be created</li> <li><b>Takeback</b>: a maximum of 3 policies per eBay marketplace may be created</li></ul>A successful create policy call returns an HTTP status code of <b>201 Created</b> with the system-generated policy ID included in the <b>Location</b> response header.<br/><br/><b>Product Compliance Policy</b><br/><br/>Product Compliance policies disclose product information as required for regulatory compliance.<br/><br/><span class="tablenote"><strong>Note:</strong> A maximum of 10 Product Compliance policies per eBay marketplace may be created.</span> <br/><br/> <b>Takeback Policy</b><br/><br/>Takeback policies describe the seller's legal obligation to take back a previously purchased item when the buyer purchases a new one.<br/><br/><span class="tablenote"><strong>Note:</strong> A maximum of 3 Takeback policies per eBay marketplace may be created.</span>
#
# POST /custom_policy/
# operationId: createCustomPolicy
export def "custom-policy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the <a href="/api-docs/sell/account/types/ba:MarketplaceIdEnum" target="_blank">MarketplaceIdEnum</a> type definition.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span>
  --description: string # Details of the seller's specific policy and terms for this policy.<br/><br/><b>Max length:</b> 15,000
  --label: string # Customer-facing label shown on View Item pages for items to which the policy applies. This seller-defined string is displayed as a system-generated hyperlink pointing to detailed policy information.<br/><br/><b>Max length:</b> 65
  --name: string # The seller-defined name for the custom policy. Names must be unique for policies assigned to the same seller, policy type, and eBay marketplace.<br /><span class="tablenote"><strong>Note:</strong> This field is visible only to the seller. </span><br/><br/><b>Max length:</b> 65
  --policy-type: string # Specifies the type of custom policy being created. <br/><br/>Two Custom Policy types are supported: <ul><li>Product Compliance (PRODUCT_COMPLIANCE)</li> <li>Takeback (TAKE_BACK)</li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:CustomPolicyTypeEnum'>eBay API documentation</a>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_policy/")
  let body = {"description": $description, "label": $label, "name": $name, "policyType": $policy_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the custom policy specified by the <b>custom_policy_id</b> path parameter for the selected eBay marketplace.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span><br/><br/>For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP" target="_blank">HTTP request headers</a>.
#
# GET /custom_policy/{custom_policy_id}
# operationId: getCustomPolicy
export def "custom-policy get" [
  custom_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the <a href="/api-docs/sell/account/types/ba:MarketplaceIdEnum" target="_blank">MarketplaceIdEnum</a> type definition.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span>
]: nothing -> record<customPolicyId: string, description: string, label: string, name: string, policyType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({custom_policy_id: $custom_policy_id} | format pattern "/custom_policy/{custom_policy_id}"))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method updates an existing custom policy specified by the <b>custom_policy_id</b> path parameter for the selected marketplace. This method overwrites the policy's <b>Name</b>, <b>Label</b>, and <b>Description</b> fields. Therefore, the complete, current text of all three policy fields must be included in the request payload even when one or two of these fields will not actually be updated.<br/> <br/>For example, the value for the <b>Label</b> field is to be updated, but the <b>Name</b> and <b>Description</b> values will remain unchanged. The existing <b>Name</b> and <b>Description</b> values, as they are defined in the current policy, must also be passed in. <br/><br/>A successful policy update call returns an HTTP status code of <b>204 No Content</b>.<br/><br/><span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span><br/><br/>For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP">HTTP request headers</a>.
#
# PUT /custom_policy/{custom_policy_id}
# operationId: updateCustomPolicy
export def "custom-policy update" [
  custom_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the <a href="/api-docs/sell/account/types/ba:MarketplaceIdEnum" target="_blank">MarketplaceIdEnum</a> type definition.<br/> <br/> <span class="tablenote"><strong>Note:</strong> The following eBay marketplaces support Custom Policies: <ul><li>Germany (EBAY_DE)</li> <li>Canada (EBAY_CA)</li> <li>Australia (EBAY_AU)</li> <li>United States (EBAY_US)</li> <li>France (EBAY_FR)</li></ul></span>
  --description: string # Details of the seller's specific policy and terms for this policy.<br/><br/><b>Max length:</b> 15,000
  --label: string # Customer-facing label shown on View Item pages for items to which the policy applies. This seller-defined string is displayed as a system-generated hyperlink pointing to detailed policy information.<br/><br/><b>Max length:</b> 65
  --name: string # The seller-defined name for the custom policy. Names must be unique for policies assigned to the same seller, policy type, and eBay marketplace.<br /><span class="tablenote"><strong>Note:</strong> This field is visible only to the seller. </span><br/><br/><b>Max length:</b> 65
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({custom_policy_id: $custom_policy_id} | format pattern "/custom_policy/{custom_policy_id}"))
  let body = {"description": $description, "label": $label, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves all the fulfillment policies configured for the marketplace you specify using the <code>marketplace_id</code> query parameter.  <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policies for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get the policies for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP" target="_blank">HTTP request headers</a>.
#
# GET /fulfillment_policy
# operationId: getFulfillmentPolicies
export def "fulfillment-policy get-fulfillment-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policies you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
]: nothing -> record<fulfillmentPolicies: table<categoryTypes: list, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record, shippingOptions: list>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fulfillment_policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates a new fulfillment policy where the policy encapsulates seller's terms for fulfilling item purchases. Fulfillment policies include the shipment options that the seller offers to buyers.  <br/><br/>Each policy targets a specific eBay marketplace and a category group type, and you can create multiple policies for each combination. <br/><br/>A successful request returns the <b>getFulfillmentPolicy</b> URI to the new policy in the <b>Location</b> response header and the ID for the new policy is returned in the response payload.  <p class="tablenote"><b>Tip:</b> For details on creating and using the business policies supported by the Account API, see <a href="/api-docs/sell/static/seller-accounts/business-policies.html">eBay business policies</a>.</p>  <p><b>Using the eBay standard envelope service (eSE)</b></p>  <p>The eBay standard envelope service (eSE) is a domestic envelope service with tracking through eBay. This service applies to specific Trading Cards categories (not all categories are supported), and to Coins & Paper Money, Postcards, and Stamps. See <a href="/api-docs/sell/static/seller-accounts/using-the-ebay-standard-envelope-service.html" target="_blank">Using the eBay standard envelope (eSE) service</a>.</p>
#
# POST /fulfillment_policy/
# operationId: createFulfillmentPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --handlingTime shape: {unit?: string, value?: int}
# --shipToLocations shape: {regionExcluded?: list, regionIncluded?: list}
# --shippingOptions item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
export def "fulfillment-policy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the fulfillment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the fulfillment policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --freight-shipping: oneof<nothing, bool> # This field is included and set to <code>true</code> if freight shipping is available for the item. Freight shipping can be used for large items over 150 lbs.<br/><br/><b>Default</b>: false
  --global-shipping: oneof<nothing, bool> # This field is included and set to <code>true</code> if the seller wants to use the Global Shipping Program for international shipments. See the <a href="https://pages.ebay.com/help/sell/shipping-globally.html ">Global Shipping Program</a> help topic for more details and requirements on the Global Shipping Program.<br/><br/>It is possible for a seller to use a combination of the Global Shipping Program and other international shipping services. <br/><br/>If this value is set to <code>false</code> or if the field is omitted, the seller is responsible for manually specifying individual international shipping services (if the seller ships internationally)., as described in <a href="https://developer.ebay.com/api-docs/sell/static/seller-accounts/ht_shipping-worldwide.html ">Setting up worldwide shipping</a>. <br/><br/>Sellers can opt in or out of the Global Shipping Program through the Shipping preferences in My eBay.<br /><br /><span class="tablenote"><b>Note</b>: On the US marketplace, the <em><b>Global Shipping Program</b></em> is scheduled to be replaced by a new intermediated international shipping program called <em><b>eBay International Shipping</b></em>. US sellers who are opted in to the Global Shipping Program will be automatically opted in to eBay International Shipping when it becomes available to them. All US sellers will be migrated by March 31, 2023. <br /><br />eBay International Shipping is an account level setting, and no field needs to be set in a Fulfillment business policy to enable it. As long as the US seller's account is opted in to eBay International Shipping, this shipping option will be enabled automatically for all listings where international shipping is available. <br /><br />A US seller who is opted in to eBay International Shipping can also specify individual international shipping service options for a Fulfillment business policy.</span><p><b>Default</b>: false</p>
  --handling-time: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --local-pickup: oneof<nothing, bool> # This field should be included and set to <code>true</code> if local pickup is one of the fulfillment options available to the buyer. It is possible for the seller to make local pickup and some shipping service options available to the buyer.<br/><br/>With local pickup, the buyer and seller make arrangements for pickup time and location.<br/><br/><b>Default</b>: <code>false</code>
  --marketplace-id: string # The ID of the eBay marketplace to which this fulfillment policy applies. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this fulfillment policy. Names must be unique for policies assigned to the same marketplace. <br/><br/><b>Max length</b>: 64
  --pickup-drop-off: oneof<nothing, bool> # This field should be included and set to <code>true</code> if the seller offers the "Click and Collect" feature for an item. <p>To enable "Click and Collect" on a listing, a seller must be eligible for Click and Collect. Currently, Click and Collect is available to only large retail merchants selling in the eBay AU and UK marketplaces.</p>  <p>In addition to setting this field to <code>true</code>, the merchant must also do the following to enable the "Click and Collect" option on a listing: <ul><li>Have inventory for the product at one or more physical stores tied to the merchant's account. <p>Sellers can use the <b>createInventoryLocaion</b> method in the Inventory API to associate physical stores to their account and they can then can add inventory to specific store locations.</p></li><li>Set an immediate payment requirement on the item. The immediate payment feature requires the seller to: <ul><li>Set the <b>immediatePay</b> flag in the payment policy to 'true'.</li><li>Have a valid store location with a complete street address.</li></ul></li></ul><p>When a merchant successfully lists an item with Click and Collect, prospective buyers within a reasonable distance from one of the merchant's stores (that has stock available) will see the "Available for Click and Collect" option on the listing, along with information on the closest store that has the item.</p><b>Default</b>: false
  --ship-to-locations: record # This type consists of the <b>regionIncluded</b> and <b>regionExcluded</b> arrays, which indicate the areas to where the seller does and doesn't ship. — shape: {regionExcluded?: list, regionIncluded?: list}
  --shipping-options: list # This array is used to provide detailed information on the domestic and international shipping options available for the policy. <br /><br />A separate <b>ShippingOption</b> object is required for domestic shipping service options and for international shipping service options (if the seller ships to international locations). <ul><li>The <b>optionType</b> field is used to indicate whether the <b>ShippingOption</b> object applies to domestic or international shipping, and the <b>costType</b> field is used to indicate whether flat-rate shipping or calculated shipping will be used.</li> <li>The <b>rateTableId</b> field can be used to associate a defined shipping rate table to the policy, and the <b>packageHandlingCost</b> container can be used to set a handling charge for the policy.</li></ul> <p>A separate <b>ShippingServices</b> object will be used to specify cost and other details for every available domestic and international shipping service option. </p> — item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
]: any -> record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fulfillment_policy/")
  let body = {"categoryTypes": $category_types, "description": $description, "freightShipping": $freight_shipping, "globalShipping": $global_shipping, "handlingTime": $handling_time, "localPickup": $local_pickup, "marketplaceId": $marketplace_id, "name": $name, "pickupDropOff": $pickup_drop_off, "shipToLocations": $ship_to_locations, "shippingOptions": $shipping_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the details for a specific fulfillment policy. In the request, supply both the policy <code>name</code> and its associated <code>marketplace_id</code> as query parameters.   <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policy for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get a policy for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP">HTTP request headers</a>.
#
# GET /fulfillment_policy/get_by_policy_name
# operationId: getFulfillmentPolicyByName
export def "fulfillment-policy-get-by-policy-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
  --name: string # This query parameter specifies the seller-defined name of the fulfillment policy you want to retrieve.
]: nothing -> record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fulfillment_policy/get_by_policy_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method deletes a fulfillment policy. Supply the ID of the policy you want to delete in the <b>fulfillmentPolicyId</b> path parameter.
#
# DELETE /fulfillment_policy/{fulfillmentPolicyId}
# operationId: deleteFulfillmentPolicy
export def "fulfillment-policy delete" [
  fulfillment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_policy_id: $fulfillment_policy_id} | format pattern "/fulfillment_policy/{fulfillment_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the complete details of a fulfillment policy. Supply the ID of the policy you want to retrieve using the <b>fulfillmentPolicyId</b> path parameter.
#
# GET /fulfillment_policy/{fulfillmentPolicyId}
# operationId: getFulfillmentPolicy
export def "fulfillment-policy get" [
  fulfillment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_policy_id: $fulfillment_policy_id} | format pattern "/fulfillment_policy/{fulfillment_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method updates an existing fulfillment policy. Specify the policy you want to update using the <b>fulfillment_policy_id</b> path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /fulfillment_policy/{fulfillmentPolicyId}
# operationId: updateFulfillmentPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --handlingTime shape: {unit?: string, value?: int}
# --shipToLocations shape: {regionExcluded?: list, regionIncluded?: list}
# --shippingOptions item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
export def "fulfillment-policy update" [
  fulfillment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the fulfillment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the fulfillment policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --freight-shipping: oneof<nothing, bool> # This field is included and set to <code>true</code> if freight shipping is available for the item. Freight shipping can be used for large items over 150 lbs.<br/><br/><b>Default</b>: false
  --global-shipping: oneof<nothing, bool> # This field is included and set to <code>true</code> if the seller wants to use the Global Shipping Program for international shipments. See the <a href="https://pages.ebay.com/help/sell/shipping-globally.html ">Global Shipping Program</a> help topic for more details and requirements on the Global Shipping Program.<br/><br/>It is possible for a seller to use a combination of the Global Shipping Program and other international shipping services. <br/><br/>If this value is set to <code>false</code> or if the field is omitted, the seller is responsible for manually specifying individual international shipping services (if the seller ships internationally)., as described in <a href="https://developer.ebay.com/api-docs/sell/static/seller-accounts/ht_shipping-worldwide.html ">Setting up worldwide shipping</a>. <br/><br/>Sellers can opt in or out of the Global Shipping Program through the Shipping preferences in My eBay.<br /><br /><span class="tablenote"><b>Note</b>: On the US marketplace, the <em><b>Global Shipping Program</b></em> is scheduled to be replaced by a new intermediated international shipping program called <em><b>eBay International Shipping</b></em>. US sellers who are opted in to the Global Shipping Program will be automatically opted in to eBay International Shipping when it becomes available to them. All US sellers will be migrated by March 31, 2023. <br /><br />eBay International Shipping is an account level setting, and no field needs to be set in a Fulfillment business policy to enable it. As long as the US seller's account is opted in to eBay International Shipping, this shipping option will be enabled automatically for all listings where international shipping is available. <br /><br />A US seller who is opted in to eBay International Shipping can also specify individual international shipping service options for a Fulfillment business policy.</span><p><b>Default</b>: false</p>
  --handling-time: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --local-pickup: oneof<nothing, bool> # This field should be included and set to <code>true</code> if local pickup is one of the fulfillment options available to the buyer. It is possible for the seller to make local pickup and some shipping service options available to the buyer.<br/><br/>With local pickup, the buyer and seller make arrangements for pickup time and location.<br/><br/><b>Default</b>: <code>false</code>
  --marketplace-id: string # The ID of the eBay marketplace to which this fulfillment policy applies. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this fulfillment policy. Names must be unique for policies assigned to the same marketplace. <br/><br/><b>Max length</b>: 64
  --pickup-drop-off: oneof<nothing, bool> # This field should be included and set to <code>true</code> if the seller offers the "Click and Collect" feature for an item. <p>To enable "Click and Collect" on a listing, a seller must be eligible for Click and Collect. Currently, Click and Collect is available to only large retail merchants selling in the eBay AU and UK marketplaces.</p>  <p>In addition to setting this field to <code>true</code>, the merchant must also do the following to enable the "Click and Collect" option on a listing: <ul><li>Have inventory for the product at one or more physical stores tied to the merchant's account. <p>Sellers can use the <b>createInventoryLocaion</b> method in the Inventory API to associate physical stores to their account and they can then can add inventory to specific store locations.</p></li><li>Set an immediate payment requirement on the item. The immediate payment feature requires the seller to: <ul><li>Set the <b>immediatePay</b> flag in the payment policy to 'true'.</li><li>Have a valid store location with a complete street address.</li></ul></li></ul><p>When a merchant successfully lists an item with Click and Collect, prospective buyers within a reasonable distance from one of the merchant's stores (that has stock available) will see the "Available for Click and Collect" option on the listing, along with information on the closest store that has the item.</p><b>Default</b>: false
  --ship-to-locations: record # This type consists of the <b>regionIncluded</b> and <b>regionExcluded</b> arrays, which indicate the areas to where the seller does and doesn't ship. — shape: {regionExcluded?: list, regionIncluded?: list}
  --shipping-options: list # This array is used to provide detailed information on the domestic and international shipping options available for the policy. <br /><br />A separate <b>ShippingOption</b> object is required for domestic shipping service options and for international shipping service options (if the seller ships to international locations). <ul><li>The <b>optionType</b> field is used to indicate whether the <b>ShippingOption</b> object applies to domestic or international shipping, and the <b>costType</b> field is used to indicate whether flat-rate shipping or calculated shipping will be used.</li> <li>The <b>rateTableId</b> field can be used to associate a defined shipping rate table to the policy, and the <b>packageHandlingCost</b> container can be used to set a handling charge for the policy.</li></ul> <p>A separate <b>ShippingServices</b> object will be used to specify cost and other details for every available domestic and international shipping service option. </p> — item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
]: any -> record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_policy_id: $fulfillment_policy_id} | format pattern "/fulfillment_policy/{fulfillment_policy_id}"))
  let body = {"categoryTypes": $category_types, "description": $description, "freightShipping": $freight_shipping, "globalShipping": $global_shipping, "handlingTime": $handling_time, "localPickup": $local_pickup, "marketplaceId": $marketplace_id, "name": $name, "pickupDropOff": $pickup_drop_off, "shipToLocations": $ship_to_locations, "shippingOptions": $shipping_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b>This method was originally created to see which onboarding requirements were still pending for sellers being onboarded for eBay managed payments, but now that all seller accounts are onboarded globally, this method should now just returne an empty payload with a <code>204 No Content</code> HTTP status code. </span>
#
# GET /kyc
# operationId: getKYC
export def "kyc get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kycChecks: table<alert: string, dataRequired: string, detailMessage: string, dueDate: string, remedyUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kyc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves all the payment policies configured for the marketplace you specify using the <code>marketplace_id</code> query parameter.  <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policies for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get the policies for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP" target="_blank">HTTP request headers</a>.
#
# GET /payment_policy
# operationId: getPaymentPolicies
export def "payment-policy get-payment-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policies you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
]: nothing -> record<href: string, limit: int, next: string, offset: int, paymentPolicies: table<categoryTypes: list, deposit: record, description: string, fullPaymentDueIn: record, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: list, paymentPolicyId: string>, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates a new payment policy where the policy encapsulates seller's terms for order payments.  <br/><br/>Each policy targets a specific eBay marketplace and category group, and you can create multiple policies for each combination.  <br/><br/>A successful request returns the <b>getPaymentPolicy</b> URI to the new policy in the <b>Location</b> response header and the ID for the new policy is returned in the response payload.  <p class="tablenote"><b>Tip:</b> For details on creating and using the business policies supported by the Account API, see <a href="/api-docs/sell/static/seller-accounts/business-policies.html">eBay business policies</a>.</p>
#
# POST /payment_policy
# operationId: createPaymentPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --deposit shape: {amount?: record, dueIn?: record, paymentMethods?: list}
# --fullPaymentDueIn shape: {unit?: string, value?: int}
# --paymentMethods item shape: {brands?: list, paymentMethodType?: string, recipientAccountReference?: record}
export def "payment-policy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the payment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --deposit: record # This type is used to specify/indicate that an initial deposit is required for a motor vehicle listing. — shape: {amount?: record, dueIn?: record, paymentMethods?: list}
  --description: string # A seller-defined description of the payment business policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --full-payment-due-in: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --immediate-pay: oneof<nothing, bool> # This field should be included and set to <code>true</code> if the seller wants to require immediate payment from the buyer for: <ul><li>A fixed-price item</li><li>An auction item where the buyer is using the 'Buy it Now' option</li><li>A deposit for a motor vehicle listing</li></ul><br /><b>Default:</b> False
  --marketplace-id: string # The ID of the eBay marketplace to which this payment business policy applies. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this payment business policy. Names must be unique for policies assigned to the same marketplace.<br /><br /><b>Max length:</b> 64
  --payment-instructions: string # <p class="tablenote"><b>Note:</b> DO NOT USE THIS FIELD. Payment instructions are no longer supported by payment business policies.</p>A free-form string field that allows sellers to add detailed payment instructions to their listings.
  --payment-methods: list # <p class="tablenote"><b>Note:</b> This field applies only when the seller needs to specify one or more offline payment methods. eBay now manages the electronic payment options available to buyers to pay for the item.</p>This array is used to specify one or more offline payment methods that will be accepted for payment that occurs off of eBay's platform. — item shape: {brands?: list, paymentMethodType?: string, recipientAccountReference?: record}
]: any -> record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_policy")
  let body = {"categoryTypes": $category_types, "deposit": $deposit, "description": $description, "fullPaymentDueIn": $full_payment_due_in, "immediatePay": $immediate_pay, "marketplaceId": $marketplace_id, "name": $name, "paymentInstructions": $payment_instructions, "paymentMethods": $payment_methods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the details of a specific payment policy. Supply both the policy <code>name</code> and its associated <code>marketplace_id</code> in the request query parameters.   <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policy for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get a policy for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP">HTTP request headers</a>.
#
# GET /payment_policy/get_by_policy_name
# operationId: getPaymentPolicyByName
export def "payment-policy-get-by-policy-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
  --name: string # This query parameter specifies the seller-defined name of the payment policy you want to retrieve.
]: nothing -> record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_policy/get_by_policy_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method deletes a payment policy. Supply the ID of the policy you want to delete in the <b>paymentPolicyId</b> path parameter. 
#
# DELETE /payment_policy/{payment_policy_id}
# operationId: deletePaymentPolicy
export def "payment-policy delete" [
  payment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_policy_id: $payment_policy_id} | format pattern "/payment_policy/{payment_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the complete details of a payment policy. Supply the ID of the policy you want to retrieve using the <b>paymentPolicyId</b> path parameter.
#
# GET /payment_policy/{payment_policy_id}
# operationId: getPaymentPolicy
export def "payment-policy get" [
  payment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_policy_id: $payment_policy_id} | format pattern "/payment_policy/{payment_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method updates an existing payment policy. Specify the policy you want to update using the <b>payment_policy_id</b> path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /payment_policy/{payment_policy_id}
# operationId: updatePaymentPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --deposit shape: {amount?: record, dueIn?: record, paymentMethods?: list}
# --fullPaymentDueIn shape: {unit?: string, value?: int}
# --paymentMethods item shape: {brands?: list, paymentMethodType?: string, recipientAccountReference?: record}
export def "payment-policy update" [
  payment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the payment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --deposit: record # This type is used to specify/indicate that an initial deposit is required for a motor vehicle listing. — shape: {amount?: record, dueIn?: record, paymentMethods?: list}
  --description: string # A seller-defined description of the payment business policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --full-payment-due-in: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --immediate-pay: oneof<nothing, bool> # This field should be included and set to <code>true</code> if the seller wants to require immediate payment from the buyer for: <ul><li>A fixed-price item</li><li>An auction item where the buyer is using the 'Buy it Now' option</li><li>A deposit for a motor vehicle listing</li></ul><br /><b>Default:</b> False
  --marketplace-id: string # The ID of the eBay marketplace to which this payment business policy applies. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this payment business policy. Names must be unique for policies assigned to the same marketplace.<br /><br /><b>Max length:</b> 64
  --payment-instructions: string # <p class="tablenote"><b>Note:</b> DO NOT USE THIS FIELD. Payment instructions are no longer supported by payment business policies.</p>A free-form string field that allows sellers to add detailed payment instructions to their listings.
  --payment-methods: list # <p class="tablenote"><b>Note:</b> This field applies only when the seller needs to specify one or more offline payment methods. eBay now manages the electronic payment options available to buyers to pay for the item.</p>This array is used to specify one or more offline payment methods that will be accepted for payment that occurs off of eBay's platform. — item shape: {brands?: list, paymentMethodType?: string, recipientAccountReference?: record}
]: any -> record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_policy_id: $payment_policy_id} | format pattern "/payment_policy/{payment_policy_id}"))
  let body = {"categoryTypes": $category_types, "deposit": $deposit, "description": $description, "fullPaymentDueIn": $full_payment_due_in, "immediatePay": $immediate_pay, "marketplaceId": $marketplace_id, "name": $name, "paymentInstructions": $payment_instructions, "paymentMethods": $payment_methods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is no longer applicable, as all seller accounts globally have been enabled for the new eBay payment and checkout flow.</span><br/><br/>This method returns whether or not the user is opted-in to the specified payments program. Sellers opt-in to payments programs by marketplace and you use the <b>marketplace_id</b> path parameter to specify the marketplace of the status flag you want returned.
#
# GET /payments_program/{marketplace_id}/{payments_program_type}
# operationId: getPaymentsProgram
export def "payments-program get" [
  marketplace_id: string
  payments_program_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<marketplaceId: string, paymentsProgramType: string, status: string, wasPreviouslyOptedIn: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_id: $marketplace_id, payments_program_type: $payments_program_type} | format pattern "/payments_program/{marketplace_id}/{payments_program_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is no longer applicable, as all seller accounts globally have been enabled for the new eBay payment and checkout flow.</span><br/><br/>This method retrieves a seller's onboarding status for a payments program for a specified marketplace. The overall onboarding status of the seller and the status of each onboarding step is returned.
#
# GET /payments_program/{marketplace_id}/{payments_program_type}/onboarding
# operationId: getPaymentsProgramOnboarding
export def "payments-program-onboarding get" [
  marketplace_id: string
  payments_program_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<onboardingStatus: string, steps: table<name: string, status: string, webUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_id: $marketplace_id, payments_program_type: $payments_program_type} | format pattern "/payments_program/{marketplace_id}/{payments_program_type}/onboarding"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the seller's current set of privileges, including whether or not the seller's eBay registration has been completed, as well as the details of their site-wide <b>sellingLimt</b> (the amount and quantity they can sell on a given day).
#
# GET /privilege
# operationId: getPrivileges
export def "privilege get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sellerRegistrationCompleted: bool, sellingLimit: record<amount: record<currency: string, value: string>, quantity: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/privilege")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method gets a list of the seller programs that the seller has opted-in to.
#
# GET /program/get_opted_in_programs
# operationId: getOptedInPrograms
export def "program-get-opted-in-programs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<programs: table<programType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/program/get_opted_in_programs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method opts the seller in to an eBay seller program. Refer to the <a href="/api-docs/sell/account/overview.html#opt-in" target="_blank">Account API overview</a> for information about available eBay seller programs.<br /><br /><span class="tablenote"><b>Note:</b> It can take up to 24-hours for eBay to process your request to opt-in to a Seller Program. Use the <a href="/api-docs/sell/account/resources/program/methods/getOptedInPrograms" target="_blank">getOptedInPrograms</a> call to check the status of your request after the processing period has passed.</span>
#
# POST /program/opt_in
# operationId: optInToProgram
export def "program-opt-in optInToProgram" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-type: string # A seller program in to which a seller can opt-in. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ProgramTypeEnum'>eBay API documentation</a>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/program/opt_in")
  let body = {"programType": $program_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method opts the seller out of a seller program to which you have previously opted-in to. Get a list of the seller programs you have opted-in to using the <b>getOptedInPrograms</b> call.
#
# POST /program/opt_out
# operationId: optOutOfProgram
export def "program-opt-out optOutOfProgram" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-type: string # A seller program in to which a seller can opt-in. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ProgramTypeEnum'>eBay API documentation</a>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/program/opt_out")
  let body = {"programType": $program_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves a seller's <i>shipping rate tables</i> for the country specified in the <b>country_code</b> query parameter. If you call this method without specifying a country code, the call returns all of the seller's shipping rate tables.  <br/><br/>The method's response includes a <b>rateTableId</b> for each table defined by the seller. This <b>rateTableId</b> value is used in add/revise item call or in create/update fulfillment business policy call to specify the shipping rate table to use for that policy's domestic or international shipping options. <br/><br/>This call currently supports getting rate tables related to the following marketplaces:<ul><li><code>EBAY_AU</code></li> <li><code>EBAY_CA</code></li> <li><code>EBAY_DE</code></li> <li><code>EBAY_ES</code></li> <li><code>EBAY_FR</code></li> <li><code>EBAY_GB</code></li> <li><code>EBAY_IT</code></li> <li><code>EBAY_US</code></li></ul>  <span class="tablenote"><b>Note:</b> Rate tables created with the Trading API might not have been assigned a <b>rateTableId</b> at the time of their creation. This method can assign and return <b>rateTableId</b> values for rate tables with missing IDs if you make a request using the <b>country_code</b> where the seller has defined rate tables.</span>  <br/><br/>Sellers can define up to 40 shipping rate tables for their account, which lets them set up different rate tables for each of the marketplaces they sell into. Go to <a href="https://www.ebay.com/ship/rt ">Shipping rate tables</a> in  <b>My eBay</b> to create and update rate tables.
#
# GET /rate_table
# operationId: getRateTables
export def "rate-table get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # This query parameter specifies the two-letter <a href="https://www.iso.org/iso-3166-country-codes.html " title="https://www.iso.org " target="_blank">ISO 3166</a> code of country for which you want shipping rate table information. If you do not specify a country code, the request returns all of the seller's defined shipping rate tables for all eBay marketplaces. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:CountryCodeEnum
]: nothing -> record<rateTables: table<countryCode: string, locality: string, name: string, rateTableId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rate_table" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves all the return policies configured for the marketplace you specify using the <code>marketplace_id</code> query parameter.  <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policies for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get the policies for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP" target="_blank">HTTP request headers</a>.
#
# GET /return_policy
# operationId: getReturnPolicies
export def "return-policy get-return-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the ID of the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, returnPolicies: table<categoryTypes: list, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/return_policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates a new return policy where the policy encapsulates seller's terms for returning items.  <br/><br/>Each policy targets a specific marketplace, and you can create multiple policies for each marketplace. Return policies are not applicable to motor-vehicle listings.<br/><br/>A successful request returns the <b>getReturnPolicy</b> URI to the new policy in the <b>Location</b> response header and the ID for the new policy is returned in the response payload.  <p class="tablenote"><b>Tip:</b> For details on creating and using the business policies supported by the Account API, see <a href="/api-docs/sell/static/seller-accounts/business-policies.html">eBay business policies</a>.</p>
#
# POST /return_policy
# operationId: createReturnPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --internationalOverride shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
# --returnPeriod shape: {unit?: string, value?: int}
export def "return-policy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container indicates which category group that the return policy applies to.<br/><br/><span class="tablenote"><b>Note</b>: Return business policies are not applicable to motor vehicle listings, so the <b>categoryTypes.name</b> value must be set to <code>ALL_EXCLUDING_MOTORS_VEHICLES</code> for return business policies.</span> — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the return business policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --extended-holiday-returns-offered: oneof<nothing, bool> # <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is deprecated, since eBay no longer supports extended holiday returns. Any value supplied in this field is neither read nor returned.</p> 
  --international-override: record # This type defines the fields for a seller's international return policy. Sellers have the ability to set separate domestic and international return policies, but if an international return policy is not set, the same return policy settings specified for the domestic return policy are also used for returns for international buyers.  — shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
  --marketplace-id: string # The ID of the eBay marketplace to which this return business policy applies.  For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this return business policy. Names must be unique for policies assigned to the same marketplace. <br/><br/><b>Max length</b>: 64
  --refund-method: string # This value indicates the refund method that will be used by the seller for buyer returns.<p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> If this field is not included in a return business policy, it will default to MONEY_BACK.</p> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:RefundMethodEnum'>eBay API documentation</a>
  --restocking-fee-percentage: string # <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is deprecated, since eBay no longer allows sellers to charge a restocking fee for buyer remorse returns. If this field is included, it is ignored.</p>
  --return-instructions: string # This text-based field provides more details on seller-specified return instructions. <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is no longer supported on many eBay marketplaces. To see if a marketplace and eBay category does support this field, call <a href="/api-docs/sell/metadata/resources/marketplace/methods/getReturnPolicies">getReturnPolicies</a> method of the <b>Metadata API</b>. Then you will look for the <b>policyDescriptionEnabled</b> field with a value of <code>true</code> for the eBay category.</span></p><br/><b>Max length</b>: 5000 (8000 for DE)
  --return-method: string # This field can be used if the seller is willing and able to offer a replacement item as an alternative to 'Money Back'. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ReturnMethodEnum'>eBay API documentation</a>
  --return-period: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --return-shipping-cost-payer: string # This field indicates who is responsible for paying for the shipping charges for returned items. The field can be set to either <code>BUYER</code> or <code>SELLER</code>.  <br/><br/>Depending on the return policy and specifics of the return, either the buyer or the seller can be responsible for the return shipping costs. Note that the seller is always responsible for return shipping costs for SNAD-related issues.  <br/><br/>This field is conditionally required if <b>returnsAccepted</b> is set to <code>true</code>. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ReturnShippingCostPayerEnum'>eBay API documentation</a>
  --returns-accepted: oneof<nothing, bool> # If set to <code>true</code>, the seller accepts returns. <p><span class="tablenote"><strong>Note:</strong>Top-Rated sellers must accept item returns and the <b>handlingTime</b> should be set to zero days or one day for a listing to receive a Top-Rated Plus badge on the View Item or search result pages. For more information on eBay's Top-Rated seller program, see <a href="http://pages.ebay.com/help/sell/top-rated.html ">Becoming a Top Rated Seller and qualifying for Top Rated Plus benefits</a>.</span></p>
]: any -> record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/return_policy")
  let body = {"categoryTypes": $category_types, "description": $description, "extendedHolidayReturnsOffered": $extended_holiday_returns_offered, "internationalOverride": $international_override, "marketplaceId": $marketplace_id, "name": $name, "refundMethod": $refund_method, "restockingFeePercentage": $restocking_fee_percentage, "returnInstructions": $return_instructions, "returnMethod": $return_method, "returnPeriod": $return_period, "returnShippingCostPayer": $return_shipping_cost_payer, "returnsAccepted": $returns_accepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the details of a specific return policy. Supply both the policy <code>name</code> and its associated <code>marketplace_id</code> in the request query parameters.   <br/><br/><b>Marketplaces and locales</b>  <br/><br/>Get the correct policy for a marketplace that supports multiple locales using the <code>Content-Language</code> request header. For example, get a policy for the French locale of the Canadian marketplace by specifying <code>fr-CA</code> for the <code>Content-Language</code> header. Likewise, target the Dutch locale of the Belgium marketplace by setting <code>Content-Language: nl-BE</code>. For details on header values, see <a href="/api-docs/static/rest-request-components.html#HTTP">HTTP request headers</a>.
#
# GET /return_policy/get_by_policy_name
# operationId: getReturnPolicyByName
export def "return-policy-get-by-policy-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the ID of the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum
  --name: string # This query parameter specifies the seller-defined name of the return policy you want to retrieve.
]: nothing -> record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/return_policy/get_by_policy_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method deletes a return policy. Supply the ID of the policy you want to delete in the <b>returnPolicyId</b> path parameter.
#
# DELETE /return_policy/{return_policy_id}
# operationId: deleteReturnPolicy
export def "return-policy delete" [
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({return_policy_id: $return_policy_id} | format pattern "/return_policy/{return_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the complete details of the return policy specified by the <b>returnPolicyId</b> path parameter.
#
# GET /return_policy/{return_policy_id}
# operationId: getReturnPolicy
export def "return-policy get" [
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({return_policy_id: $return_policy_id} | format pattern "/return_policy/{return_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method updates an existing return policy. Specify the policy you want to update using the <b>return_policy_id</b> path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /return_policy/{return_policy_id}
# operationId: updateReturnPolicy
# --categoryTypes item shape: {default?: bool, name?: string}
# --internationalOverride shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
# --returnPeriod shape: {unit?: string, value?: int}
export def "return-policy update" [
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container indicates which category group that the return policy applies to.<br/><br/><span class="tablenote"><b>Note</b>: Return business policies are not applicable to motor vehicle listings, so the <b>categoryTypes.name</b> value must be set to <code>ALL_EXCLUDING_MOTORS_VEHICLES</code> for return business policies.</span> — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the return business policy. This description is only for the seller's use, and is not exposed on any eBay pages.  <br/><br/><b>Max length</b>: 250
  --extended-holiday-returns-offered: oneof<nothing, bool> # <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is deprecated, since eBay no longer supports extended holiday returns. Any value supplied in this field is neither read nor returned.</p> 
  --international-override: record # This type defines the fields for a seller's international return policy. Sellers have the ability to set separate domestic and international return policies, but if an international return policy is not set, the same return policy settings specified for the domestic return policy are also used for returns for international buyers.  — shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
  --marketplace-id: string # The ID of the eBay marketplace to which this return business policy applies.  For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # A seller-defined name for this return business policy. Names must be unique for policies assigned to the same marketplace. <br/><br/><b>Max length</b>: 64
  --refund-method: string # This value indicates the refund method that will be used by the seller for buyer returns.<p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> If this field is not included in a return business policy, it will default to MONEY_BACK.</p> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:RefundMethodEnum'>eBay API documentation</a>
  --restocking-fee-percentage: string # <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is deprecated, since eBay no longer allows sellers to charge a restocking fee for buyer remorse returns. If this field is included, it is ignored.</p>
  --return-instructions: string # This text-based field provides more details on seller-specified return instructions. <p class="tablenote"><span  style="color: #dd1e31;"><b>Important!</b></span> This field is no longer supported on many eBay marketplaces. To see if a marketplace and eBay category does support this field, call <a href="/api-docs/sell/metadata/resources/marketplace/methods/getReturnPolicies">getReturnPolicies</a> method of the <b>Metadata API</b>. Then you will look for the <b>policyDescriptionEnabled</b> field with a value of <code>true</code> for the eBay category.</span></p><br/><b>Max length</b>: 5000 (8000 for DE)
  --return-method: string # This field can be used if the seller is willing and able to offer a replacement item as an alternative to 'Money Back'. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ReturnMethodEnum'>eBay API documentation</a>
  --return-period: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.<br/><br/>Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --return-shipping-cost-payer: string # This field indicates who is responsible for paying for the shipping charges for returned items. The field can be set to either <code>BUYER</code> or <code>SELLER</code>.  <br/><br/>Depending on the return policy and specifics of the return, either the buyer or the seller can be responsible for the return shipping costs. Note that the seller is always responsible for return shipping costs for SNAD-related issues.  <br/><br/>This field is conditionally required if <b>returnsAccepted</b> is set to <code>true</code>. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/account/types/api:ReturnShippingCostPayerEnum'>eBay API documentation</a>
  --returns-accepted: oneof<nothing, bool> # If set to <code>true</code>, the seller accepts returns. <p><span class="tablenote"><strong>Note:</strong>Top-Rated sellers must accept item returns and the <b>handlingTime</b> should be set to zero days or one day for a listing to receive a Top-Rated Plus badge on the View Item or search result pages. For more information on eBay's Top-Rated seller program, see <a href="http://pages.ebay.com/help/sell/top-rated.html ">Becoming a Top Rated Seller and qualifying for Top Rated Plus benefits</a>.</span></p>
]: any -> record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({return_policy_id: $return_policy_id} | format pattern "/return_policy/{return_policy_id}"))
  let body = {"categoryTypes": $category_types, "description": $description, "extendedHolidayReturnsOffered": $extended_holiday_returns_offered, "internationalOverride": $international_override, "marketplaceId": $marketplace_id, "name": $name, "refundMethod": $refund_method, "restockingFeePercentage": $restocking_fee_percentage, "returnInstructions": $return_instructions, "returnMethod": $return_method, "returnPeriod": $return_period, "returnShippingCostPayer": $return_shipping_cost_payer, "returnsAccepted": $returns_accepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this call to retrieve all sales tax table entries that the seller has defined for a specific country. All four response fields will be returned for each tax jurisdiction that matches the search criteria. <br/><br/><span class="tablenote"><b>Important!</b> In most US states and territories, eBay now 'collects and remits' sales tax, so sellers can no longer configure sales tax rates for these states/territories.</span>
#
# GET /sales_tax
# operationId: getSalesTaxes
export def "sales-tax get-sales-taxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # This path parameter specifies the two-letter <a href="https://www.iso.org/iso-3166-country-codes.html " title="https://www.iso.org " target="_blank">ISO 3166</a> code for the country whose tax table you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:CountryCodeEnum
]: nothing -> record<salesTaxes: table<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sales_tax" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This call deletes a sales tax table entry for a jurisdiction. Specify the jurisdiction to delete using the <b>countryCode</b> and <b>jurisdictionId</b> path parameters.
#
# DELETE /sales_tax/{countryCode}/{jurisdictionId}
# operationId: deleteSalesTax
export def "sales-tax delete" [
  country_code: string
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_code: $country_code, jurisdiction_id: $jurisdiction_id} | format pattern "/sales_tax/{country_code}/{jurisdiction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This call gets the current sales tax table entry for a specific tax jurisdiction. Specify the jurisdiction to retrieve using the <b>countryCode</b> and <b>jurisdictionId</b> path parameters. All four response fields will be returned if a sales tax entry exists for the tax jurisdiction. Otherwise, the response will be returned as empty.<br/><br/><span class="tablenote"><b>Important!</b> In most US states and territories, eBay now 'collects and remits' sales tax, so sellers can no longer configure sales tax rates for these states/territories.</span>
#
# GET /sales_tax/{countryCode}/{jurisdictionId}
# operationId: getSalesTax
export def "sales-tax get" [
  country_code: string
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_code: $country_code, jurisdiction_id: $jurisdiction_id} | format pattern "/sales_tax/{country_code}/{jurisdiction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates or updates a sales tax table entry for a jurisdiction. Specify the tax table entry you want to configure using the two path parameters: <b>countryCode</b> and <b>jurisdictionId</b>.  <br/><br/>A tax table entry for a jurisdiction is comprised of two fields: one for the jurisdiction's sales-tax rate and another that's a boolean value indicating whether or not shipping and handling are taxed in the jurisdiction.  <br/><br/>You can set up <i>tax tables</i> for countries that support different <i>tax jurisdictions</i>. Currently, only Canada, India, and the US support separate tax jurisdictions. If you sell into any of these countries, you can set up tax tables for any of the country's jurisdictions. Retrieve valid jurisdiction IDs using <b>getSalesTaxJurisdictions</b> in the Metadata API.  <br/><br/>For details on using this call, see <a href="/api-docs/sell/static/seller-accounts/tax-tables.html">Establishing sales-tax tables</a>. <br/><br/><span class="tablenote"><b>Important!</b> In the US, eBay now 'collects and remits' sales tax for every US state except for Missouri (and a few US territories), so sellers can no longer configure sales tax rates for any states except Missouri. With eBay 'collect and remit', eBay calculates the sales tax, collects the sales tax from the buyer, and remits the sales tax to the tax authorities at the buyer's location.</span>
#
# PUT /sales_tax/{countryCode}/{jurisdictionId}
# operationId: createOrReplaceSalesTax
export def "sales-tax create-or-replace" [
  country_code: string
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sales-tax-percentage: string # This field is used to set the sales tax rate for the tax jurisdiction set in the call URI. When applicable to an order, this sales tax rate will be applied to sales price. The <b>shippingAndHandlingTaxed</b> value will indicate whether or not sales tax is also applied to shipping and handling charges<br><br>Although it is a string, a percentage value is set here, such as <code>7.75</code>.
  --shipping-and-handling-taxed: oneof<nothing, bool> # This field is set to <code>true</code> if the seller wishes to apply sales tax to shipping and handling charges, and not just the total sales price of the order. Otherwise, this field's value should be set to <code>false</code>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_code: $country_code, jurisdiction_id: $jurisdiction_id} | format pattern "/sales_tax/{country_code}/{jurisdiction_id}"))
  let body = {"salesTaxPercentage": $sales_tax_percentage, "shippingAndHandlingTaxed": $shipping_and_handling_taxed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves a list of subscriptions associated with the seller account.
#
# GET /subscription
# operationId: getSubscription
export def "subscription get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # This field is for future use.
  --continuation-token: string # This field is for future use.
]: nothing -> record<href: string, limit: int, next: string, subscriptions: table<marketplaceId: string, subscriptionId: string, subscriptionLevel: string, subscriptionType: string, term: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "continuation_token" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
