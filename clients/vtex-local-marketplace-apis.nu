# Auto-generated client for Marketplace API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Marketplace-APIs/1.0/openapi.json
# Auth: --token flag or $env.MARKETPLACE_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARKETPLACE_API_TOKEN | default "" }
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
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br/api"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "notificator-changenotification-inventory create-notification" } } | get name | first)
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

# Notify marketplace of inventory update
#
# POST /notificator/{sellerId}/changenotification/{skuId}/inventory
# operationId: InventoryNotification
export def "notificator-changenotification-inventory create-notification" [
  seller_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. The notification will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/notificator/{seller_id}/changenotification/{sku_id}/inventory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Notify marketplace of price update
#
# POST /notificator/{sellerId}/changenotification/{skuId}/price
# operationId: PriceNotification
export def "notificator-changenotification-price create-notification" [
  seller_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. The notification will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/notificator/{seller_id}/changenotification/{sku_id}/price") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Matched Offers List
#
# GET /offer-manager/pvt/offers
# operationId: Getofferslist
export def "offer-manager-pvt-offers get-getofferslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Criteria used to sort the list of offers. For sorting values in ascending order, use `asc`, while for descending order, use `desc`. To fill in the field, insert the sorting criteria, followed by 'asc', or 'desc', separated by a comma. You can sort by the following criteria: - **price:** sorts offers by price. *Ascending* goes from lowest to highest price, while *Descending* goes from highest to lowest price. - **name:** sorts offers by *productName*, in alphabetical order. *Ascending* goes from *A* to *Z*, while *Descending* goes from *Z* to *A*. - **availability:** availability in the sales channel (sc). The default value is 1. Ex. sort=availability,desc Ex. sort=name,asc Ex. price,desc (e.g. availability,desc)
  --rows: int # Number of rows included in the response. Each row corresponds to a single offer. The default amount of rows in the response is 1, and the maximum amount is 50. To have more than one offer listed in the response, please add the `rows` parameter with a number greater than 1. (default: 20)
  --start: int # Number corresponding to the row from which the offer list will begin, used for pagination. Filters the list of offers by retrieving the offers starting from the row defined. The default value is 0, if the param is not included in the call. (default: 21)
  --fq: string # This filter query can be used to filter offers by the criteria described below. It should be filled in by following the format: `fq={{criteriaName}}:{{criteriaValue}}`. - **productId:** integer of the product ID - **productName:** string of the product's name - **skuId:** integer of the SKU ID - **eanId:** string of the EAN ID - **refId:** string of the Ref ID - **categoryId:** integer of the category ID - **brandId:** integer of the brand ID - **sellerId:** string of the seller ID - **sc:** integer of the sales channel's ID (trade policy in VTEX) Ex: skuId:172 Ex: categoryId:13 Ex. productName:Product example-123 (e.g. skuId:172)
  --account-name: string # Name of the VTEX account. Used as part of the URL (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> table<BrandId: int, CategoryId: int, LastModified: string, ProductId: string, ProductName: string, Skus: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "fq" $fq "scalar") (serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offer-manager/pvt/offers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Matched Offer's Data by Product ID
#
# GET /offer-manager/pvt/product/{productId}
# operationId: GetProductoffers
export def "offer-manager-pvt-product get-productoffers" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/offer-manager/pvt/product/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Matched Offer's Data by SKU ID
#
# GET /offer-manager/pvt/product/{productId}/sku/{skuId}
# operationId: GetSKUoffers
export def "offer-manager-pvt-product-sku get-sk-uoffers" [
  product_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account. Used as part of the URL. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/offer-manager/pvt/product/{product_id}/sku/{sku_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Seller Leads
#
# GET /seller-register/pvt/seller-leads
# operationId: ListSellerLeads
export def "seller-register-pvt-seller-leads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --offset: int # This field determines the limit used to retrieve the list of sellers. The response includes objects starting `from` the value inputted here. (format: int32, default: 0)
  --limit: int # This field determines the limit used to retrieve the list of sellers. The response includes objects until the value inputted here. (format: int32, default: 15)
  --is-connected: string # Query param that enables results to be filter by whether the seller lead is already connected to the marketplace or not. (default: )
  --search: string # Custom search field, that filters sellers invited by specific marketplace operator's email. (default: user email)
  --status: string # Seller Lead's status. Includes `accepted`, `connected` or `invited`. (default: invited)
  --order-by: string # Query param determining how data will be ordered in the response, ordering by name or ID in descending our ascending order. Includes the following values: `namesort` = desc/asc `idsort` = desc/asc
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "isConnected" $is_connected "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seller-register/pvt/seller-leads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Invite Seller Lead
#
# POST /seller-register/pvt/seller-leads
# operationId: CreateSellerLead
# --accountable shape: {email: string, name: string, phone: string}
# --address shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
export def "seller-register-pvt-seller-leads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexample)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  account_id: string # Marketplace's account ID (default: 5fb38ace-d95e-45ad-970d-ee97cce9fbcd)
  accountable: record # shape: {email: string, name: string, phone: string}
  address: record # shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
  document: string # Company's legal document code. (default: 12345671000)
  email: string # default: email@email.com
  --has-accepted-legal-terms: oneof<nothing, bool> # Indicates if the seller has accepted the platform's legal terms and conditions. (default: true)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (default: 1)
  seller_account_name: string # Name of the seller's account, part of the url of their VTEX Admin. (default: seller123)
  seller_email: string # Seller's contact email; (default: selleremail@email.com)
  seller_name: string # Seller's store's name. (default: Seller Name)
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seller-register/pvt/seller-leads" $qp)
  let req_body = {"accountId": $account_id, "accountable": $accountable, "address": $address, "document": $document, "email": $email, "hasAcceptedLegalTerms": $has_accepted_legal_terms, "salesChannel": $sales_channel, "sellerAccountName": $seller_account_name, "sellerEmail": $seller_email, "sellerName": $seller_name, "sellerType": $seller_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Seller Lead
#
# DELETE /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: RemoveSellerLead
export def "seller-register-pvt-seller-leads delete" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_lead_id: (encode-path-segment $seller_lead_id)} | format pattern "/seller-register/pvt/seller-leads/{seller_lead_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Seller Lead's Data by Id
#
# GET /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: RetrieveSellerLead
export def "seller-register-pvt-seller-leads get" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_lead_id: (encode-path-segment $seller_lead_id)} | format pattern "/seller-register/pvt/seller-leads/{seller_lead_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Accept Seller Lead
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}
# operationId: AcceptSellerLead
# --accountable shape: {email: string, name: string, phone: string}
# --address shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
export def "seller-register-pvt-seller-leads update-accept" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  account_id: string # Marketplace's account ID (default: 5fb38ace-d95e-45ad-970d-ee97cce9fbcd)
  accountable: record # shape: {email: string, name: string, phone: string}
  address: record # shape: {city: string, complement: string, neighborhood: string, number: string, postalcode: string, state: string, street: string}
  document: string # Company's legal document code. (default: 12345671000)
  email: string # email of the admin responsible for the seller. (default: seller@email.com)
  --has-accepted-legal-terms: oneof<nothing, bool> # Indicates if the seller has accepted the platform's legal terms and conditions. (default: true)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (default: 1)
  seller_account_name: string # Name of the seller's account, part of the url of their VTEX Admin. (default: seller123)
  seller_email: string # Seller's contact email. (default: selleremail@email.com)
  seller_name: string # Seller's store's name. (default: Seller Name)
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_lead_id: (encode-path-segment $seller_lead_id)} | format pattern "/seller-register/pvt/seller-leads/{seller_lead_id}") $qp)
  let req_body = {"accountId": $account_id, "accountable": $accountable, "address": $address, "document": $document, "email": $email, "hasAcceptedLegalTerms": $has_accepted_legal_terms, "salesChannel": $sales_channel, "sellerAccountName": $seller_account_name, "sellerEmail": $seller_email, "sellerName": $seller_name, "sellerType": $seller_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Seller From Lead
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}/seller
# operationId: CreateSellerFromSellerLead
export def "seller-register-pvt-seller-leads-seller create" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Marketplace's account name, the same one inputted on the endpoint's path. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --is-active: oneof<nothing, bool> # Whether the Seller Lead is `active` or not in Seller Portal. This request only supports the value `false` in this field. If that´s not the case, the request will respond with an internal error. (default: false)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "isActive" $is_active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_lead_id: (encode-path-segment $seller_lead_id)} | format pattern "/seller-register/pvt/seller-leads/{seller_lead_id}/seller") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resend Seller Lead Invite
#
# PUT /seller-register/pvt/seller-leads/{sellerLeadId}/status
# operationId: ResendSellerLeadRequest
export def "seller-register-pvt-seller-leads-status resend-request" [
  seller_lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  status: string # Seller Lead's status. Includes `accepted`, `connected` or `invited`. (default: accepted)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_lead_id: (encode-path-segment $seller_lead_id)} | format pattern "/seller-register/pvt/seller-leads/{seller_lead_id}/status") $qp)
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# List Sellers
#
# GET /seller-register/pvt/sellers
# operationId: GetListSellers
export def "seller-register-pvt-sellers get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --qp-from: float # The start number of pagination, being `0` the default value. (default: 0)
  --qp-to: float # The end number of pagination, being `100` the default value. (default: 100)
  --keyword: string # Search sellers by a keyword in `sellerId` or `sellerName`. (default: keyword)
  --integration: string # Filters sellers by the name of who made the integration, if VTEX or an external hub. The possible values for VTEX integrations are: `vtex-sellerportal`, `vtex-seller` and `vtex-franchise`. (default: vtex-seller)
  --group: string # Groups are defined by keywords that group sellers into categories defined by the marketplace. (default: Group)
  --is-active: oneof<nothing, bool> # Enables to filter sellers that are active (`true`) or unactive (`false`) in the marketplace. (default: false)
  --is-better-scope: oneof<nothing, bool> # The flag `isBetterScope` is used by the VTEX Checkout to simulate shopping carts, products, and shipping only in sellers with the field set as `true`, avoiding performance issues. When used as a query param, `isBetterScope` filters sellers that have the flag set as `true` or `false`. (default: false)
  --is-vtex: oneof<nothing, bool> # When set as `true`, the list returned will be of sellers who have a VTEX store configured. When set as `false`, the list will be of sellers who do not have a VTEX store configured. (default: false)
  --sc: string # Filters sellers available for the marketplace's sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) indicated in this field. (default: 1)
  --seller-type: int # Filters sellers by their type, which can be regular seller (`1`) or whitelabel seller (`2`). (default: 1)
  --qp-sort: string # Narrow the search filtering by the fields: `id`, `name` or `pendingoffers`. The list retrieved can be organized in an ascending (`asc`) or descending (`desc`) order. The standardized format is `{field}:{order}`, and the default value is `id:asc`. (default: id:asc)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "integration" $integration "scalar") (serialize-qp "group " $group "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "isBetterScope" $is_better_scope "scalar") (serialize-qp "isVtex" $is_vtex "scalar") (serialize-qp "sc" $sc "scalar") (serialize-qp "sellerType" $seller_type "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seller-register/pvt/sellers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Configure Seller Account
#
# POST /seller-register/pvt/sellers
# operationId: UpsertSellerRequest
# --availableSalesChannels item shape: {id: int, isSelected: bool, name: string}
# --groups item shape: {id?: string, name?: string}
export def "seller-register-pvt-sellers update-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Marketplace's account name, the same one inputted on the endpoint's path. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  csc_identification: string # SKU Seller Identification (default: cscidentification 123)
  account: string # Seller's account name (default: partner01)
  --allow-hybrid-payments: oneof<nothing, bool> # Flag that allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (default: false)
  available_sales_channels: list # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) available. (default: []) — item shape: {id: int, isSelected: bool, name: string}
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `https://{sellerName}.vtexcommercestable.com.br/api/catalog_system/.` (default: https://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  channel: string # Channel's name. (default: channel name)
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (default: Describe delivery policy)
  description: string # String describing the seller (default: Seller A, from the B industry.)
  email: string # email of the admin responsible for the seller. (default: seller@email.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (default: Describe exchange and returns policy)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. For **external sellers**, please include the URL of the seller's endpoint. External sellers have different endpoint standards. The seller must inform this endpoint to the marketplace so that the marketplace can complete the configuration process. For **VTEX Stores**, the field format will be as follows: `https://{SellerName}.vtexcommercestable.com.br/api/fulfillment?&sc={TradePolicyID}`. The value `SellerName` corresponds to the store name if the seller is a VTEX store. The value `TradePolicyID` corresponds to the [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV#master-data) created by the seller in their own VTEX environment. The seller must inform this ID to the marketplace so that the marketplace can complete the configuration process. The value `AffiliateID` corresponds to the 3-digit affiliate identification code created by the seller. The seller must inform this ID to the marketplace so that the marketplace can complete the configuration process. To configure the [Multilevel Omnichannel Inventory](https://developers.vtex.com/vtex-rest-api/docs/multilevel-omnichannel-inventory) feature, fill in this field with the checkout endpoint following this example: `https://{{sellerAccount}}.vtexcommercestable.com.br/api/checkout?affiliateid={{affiliateId}}&sc={{salesChannel` (default: http://{SellerName}.vtexcommercestable.com.br/api/fulfillment?&sc={TradePolicyID})
  fulfillment_seller_id: string # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be nulled. (default: seller1)
  --groups: list # Array of groups attached to the seller. Groups are defined by key-words that group sellers into categories defined by the marketplace when adding a new seller through the [Configure Seller Account](https://developers.vtex.com/vtex-rest-api/reference/sellers#putupsertseller) endpoint. It is possible to filter sellers by group in the Seller Management page in your VTEX Admin. Know more about groups through our [Seller Management](https://help.vtex.com/en/tutorial/gerenciamento-de-sellers-beta--6eEiOISwxuAWJ8w6MtK7iv#groups) documentation. — item shape: {id?: string, name?: string}
  id: string # Seller ID assigned by the marketplace. We recommend filling it in with the seller's account name. (default: seller123)
  --is-active: oneof<nothing, bool> # Whether the seller is active on the marketplace or not. (default: true)
  --is-better-scope: oneof<nothing, bool> # Flag used by the VTEX Checkout to simmulate shopping carts, products and shipping only in sellers with the boolean set as `true`, avoiding performance issues. (default: true)
  --is-vtex: oneof<nothing, bool> # Flag determining whether the seller configured is a VTEX store or not. (default: true)
  name: string # Name of the seller's store, configured in the seller's environment. (default: Seller Name)
  --password: string # User password, if you are using a hub to integrate with the external seller. (nullable, default: integrationHubPassword)
  sales_channel: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) associated to the seller account created. If no value is specified, the system will automatically use the sales channel configured in the seller's [affiliate](https://help.vtex.com/en/tutorial/configuring-affiliates--tutorials_187) ID. (default: 1)
  score: float # Score attributed to this seller. (default: 0)
  --security-privacy-policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (nullable, default: Describe privacy and security policy)
  seller_commission_configuration: record
  seller_type: int # Type of seller, including: `1`: regular seller `2`: whitelabel seller (format: int32, default: 1)
  tax_code: string # This code is the Identity Number for the legal entity and is linked to information in its base country. (default: 34444)
  trust_policy: string # the marketplace must first allow VTEX to share clients’ email addresses with the seller. To do so, it is necessary to set 'AllowEmailSharing' as the value for the TrustPolicy field (default: AllowEmailSharing)
  --user: string # Username, if you are using a hub to integrate with the external seller. (nullable, default: integrationHubUserName)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seller-register/pvt/sellers" $qp)
  let req_body = {"CSCIdentification": $csc_identification, "account": $account, "allowHybridPayments": $allow_hybrid_payments, "availableSalesChannels": $available_sales_channels, "catalogSystemEndpoint": $catalog_system_endpoint, "channel": $channel, "deliveryPolicy": $delivery_policy, "description": $description, "email": $email, "exchangeReturnPolicy": $exchange_return_policy, "fulfillmentEndpoint": $fulfillment_endpoint, "fulfillmentSellerId": $fulfillment_seller_id, "groups": $groups, "id": $id, "isActive": $is_active, "isBetterScope": $is_better_scope, "isVtex": $is_vtex, "name": $name, "password": $password, "salesChannel": $sales_channel, "score": $score, "securityPrivacyPolicy": $security_privacy_policy, "sellerCommissionConfiguration": $seller_commission_configuration, "sellerType": $seller_type, "taxCode": $tax_code, "trustPolicy": $trust_policy, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Seller data by ID
#
# GET /seller-register/pvt/sellers/{sellerId}
# operationId: GetRetrieveSeller
export def "seller-register-pvt-sellers get-get" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --sc: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) associated to the seller account created. (default: 1)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Seller by Seller ID
#
# PATCH /seller-register/pvt/sellers/{sellerId}
# operationId: UpdateSeller
export def "seller-register-pvt-sellers update" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# List Seller Commissions by seller ID
#
# GET /seller-register/pvt/sellers/{sellerId}/commissions
# operationId: ListSellerCommissions
export def "seller-register-pvt-sellers-commissions list" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/commissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upsert Seller Commissions in Bulk
#
# PUT /seller-register/pvt/sellers/{sellerId}/commissions/categories
# operationId: BulkUpsertSellerCommissions
export def "seller-register-pvt-sellers-commissions-categories update-bulk" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/commissions/categories") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Remove Seller Commissions by Category ID
#
# DELETE /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: RemoveSellerCommissions
export def "seller-register-pvt-sellers-commissions delete" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), category_id: (encode-path-segment $category_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/commissions/{category_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Seller Commissions by Category ID
#
# GET /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: RetrieveSellerCommissions
export def "seller-register-pvt-sellers-commissions get" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), category_id: (encode-path-segment $category_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/commissions/{category_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upsert Seller Commissions by Category ID
#
# PUT /seller-register/pvt/sellers/{sellerId}/commissions/{categoryId}
# operationId: UpsertSellerCommissions
export def "seller-register-pvt-sellers-commissions update" [
  seller_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. All data extracted, and changes added will be posted into this account. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --category-full-path: string # Full path to the SKU's category. It should be written as {department}/{category}. For example: if the department is **Appliances** and the category is **Oven**, the full path should be 'Appliances/Oven'. (nullable, default: Appliances/Oven)
  --body-category-id: string # Marketplace's Category ID that the product belongs to, configured in the Catalog. (default: 6)
  freight_commission_percentage: float # Percentage of the comission applied to the freight in decimals. (default: 2.43)
  product_commission_percentage: float # Percentage of the comission applied to the product in decimals. (default: 9.85)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), category_id: (encode-path-segment $category_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/commissions/{category_id}") $qp)
  let req_body = {"categoryFullPath": $category_full_path, "categoryId": $body_category_id, "freightCommissionPercentage": $freight_commission_percentage, "productCommissionPercentage": $product_commission_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Sales Channel Mapping Data
#
# GET /seller-register/pvt/sellers/{sellerId}/sales-channel/mapping
# operationId: RetrieveMapping
export def "seller-register-pvt-sellers-sales-channel-mapping get" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. Used as part of the URL (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --an: string # Marketplace's account name, the same one inputted on the endpoint's path. (default: apiexamples)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> table<marketplaceSalesChannel: string, sellerChannel: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/sales-channel/mapping") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upsert Sales Channel Mapping
#
# PUT /seller-register/pvt/sellers/{sellerId}/sales-channel/mapping
# operationId: UpsertMapping
export def "seller-register-pvt-sellers-sales-channel-mapping update" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Name of the VTEX account that belongs to the marketplace. Used as part of the URL. (default: apiexamples)
  --environment: string # Environment to use. Used as part of the URL. (default: vtexcommercestable)
  --an: string # Marketplace's account name, the same one inputted on the endpoint's path. (default: apiexamples)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> table<marketplaceSalesChannel: string, sellerChannel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountName" $account_name "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/seller-register/pvt/sellers/{seller_id}/sales-channel/mapping") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}
