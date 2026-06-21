# Auto-generated client for Swagger API2Cart v1.1
# Source: https://api.apis.guru/v2/specs/api2cart.com/1.1/openapi.json
# Auth: --token flag or $env.SWAGGER_API2CART_TOKEN

const BASE_URL = "https://api.api2cart.com/v1.1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SWAGGER_API2CART_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {x-api-key: $token_val}, query: "", location: "header"} }
    "x-store-key" => { {scheme: $scheme, headers: {x-store-key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.api2cart.com/v1.1"] }
def auth-scheme-completer [] { ["x-api-key" "x-store-key"] }

# Completers for enum parameters
def amazon-sp-aws-region-completer [] { ["eu-west-1" "us-east-1" "us-west-2"] }
def cart-id-completer [] { ["3DCart" "3DCartApi" "AceShop" "Amazon" "AmazonSP" "AspDotNetStorefront" "BigcommerceApi" "CommerceHQ" "Creloaded" "Cscart" "Cubecart" "Demandware" "EBay" "Ecwid" "Etsy" "EtsyAPIv3" "Gambio" "Hybris" "Interspire" "JooCart" "LightSpeed" "Magento1212" "Magento2Api" "MercadoLibre" "MijoShop" "Neto" "Opencart14" "Oscmax2" "Oscommerce22ms2" "Oxid" "Pinnacle" "Prestashop" "PrestashopApi" "SSPremium" "Shopify" "Shopware" "ShopwareApi" "Squarespace" "Tomatocart" "Ubercart" "Virtuemart" "Volusion" "WPecommerce" "Walmart" "WebAsyst" "Wix" "Woocommerce" "WoocommerceApi" "Xcart" "Xtcommerce" "XtcommerceVeyton" "Zencart137" "Zid"] }
def type-completer [] { ["boolean" "date" "multiselect" "price" "select" "text" "textarea"] }
def action-apply-to-completer [] { ["item_price" "order_total" "shipping"] }
def action-scope-completer [] { ["matching_items" "order"] }
def action-type-completer [] { ["fixed" "percent"] }
def entity-completer [] { ["customer" "order" "order_shipping_address" "product"] }
def key-completer [] { ["category_id" "country" "customer_id" "item_price" "item_quantity" "item_total_price" "product_id" "shipping_total" "subtotal" "total" "total_quantity" "total_weight" "variant_id"] }
def operator-completer [] { ["<" "<=" "==" ">" ">=" "ONE_OF"] }
def type-completer-1 [] { ["base" "thumbnail"] }
def type-completer-2 [] { ["additional" "base" "small" "thumbnail"] }
def type-completer-3 [] { ["option_type_checkbox" "option_type_date" "option_type_datetime" "option_type_file" "option_type_multicheckbox" "option_type_multiselect" "option_type_radio" "option_type_readonly" "option_type_select" "option_type_text" "option_type_textarea" "option_type_time"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-cart-add-json create" } } | get name | first)
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

# Add store to the account
#
# POST /account.cart.add.json
# operationId: AccountCartAdd
# --hybris_websites item shape: {storeIds: list<string>, uid: string, url: string}
export def "account-cart-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --3dcart-access-token: string # 3DCart Token
  --3dcart-private-key: string # 3DCart Private Key
  --3dcartapi-api-key: string # 3DCart API Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --amazon-access-token: string # MWS Auth Token. Access token authorizing the app to access resources on behalf of a user
  --amazon-marketplaces-ids: string # Amazon Marketplace IDs comma separated string
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-seller-id: string # Amazon Seller ID (Merchant token)
  --amazon-sp-api-environment: string # Amazon SP API environment (default: production)
  amazon_sp_aws_region: string@amazon-sp-aws-region-completer # Amazon AWS Region
  amazon_sp_aws_role_arn: string # Amazon AWS Role ARN
  amazon_sp_aws_user_key_id: string # Amazon AWS user access key ID
  amazon_sp_aws_user_secret: string # Amazon AWS user secret access key
  amazon_sp_client_id: string # Amazon SP API app client id
  amazon_sp_client_secret: string # Amazon SP API app client secret
  amazon_sp_refresh_token: string # Amazon SP API OAuth refresh token
  --aspdotnetstorefront-api-pass: string # AspDotNetStorefront API Password
  --aspdotnetstorefront-api-user: string # It's a AspDotNetStorefront account for which API is available
  --bigcommerceapi-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --bigcommerceapi-admin-account: string # It's a BigCommerce account for which API is enabled
  --bigcommerceapi-api-key: string # Bigcommerce API Key
  --bigcommerceapi-api-path: string # BigCommerce API URL
  --bigcommerceapi-client-id: string # Client ID of the requesting app
  --bigcommerceapi-context: string # API Path section unique to the store
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  cart_id: string@cart-id-completer # Store’s identifier which you can get from cart_list method
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --db-tables-prefix: string # DB tables prefix
  --demandware-api-password: string # Demandware api password
  --demandware-client-id: string # Demandware client id
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-environment: string # eBay environment (default: production)
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-site-id: int # eBay global ID (default: 0)
  --ecwid-acess-token: string # Access token authorizing the app to access resources on behalf of a user
  --ecwid-store-id: string # Store Id
  --etsy-access-token: string # Access token authorizing the app to access resources on behalf of a user
  etsy_client_id: string # Etsy Client Id
  --etsy-keystring: string # Etsy keystring
  etsy_refresh_token: string # Etsy Refresh token
  --etsy-shared-secret: string # Etsy shared secret
  --etsy-token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --ftp-host: string # FTP connection host
  --ftp-password: string # FTP Password
  --ftp-port: int # FTP Port
  --ftp-store-dir: string # FTP Store dir
  --ftp-user: string # FTP User
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-password: string # User password
  --hybris-username: string # User Name
  --hybris-websites: list # Websites to stores mapping data — item shape: {storeIds: list<string>, uid: string, url: string}
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --magento-access-token: string # Magento Access Token
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-token-secret: string # Magento Token Secret
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --neto-api-key: string # Neto API Key
  --neto-api-username: string # Neto User Name
  --prestashop-webservice-key: string # Prestashop webservice key
  --shopify-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --shopify-api-key: string # Shopify API Key
  --shopify-api-password: string # Shopify API Password
  --shopify-shared-secret: string # Shared secret
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --squarespace-api-key: string # Squarespace API Key
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  store_url: string # A web address of a store that you would like to connect to API2Cart
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
  --verify: oneof<nothing, bool> # Enables or disables cart's verification (default: true)
  --volusion-login: string # It's a Volusion account for which API is enabled
  --volusion-password: string # Volusion API Password
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-refresh-token: string # Zid refresh token
]: any -> record<result: record<store_key: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account.cart.add.json")
  let req_body = {"3dcart_access_token": $3dcart_access_token, "3dcart_private_key": $3dcart_private_key, "3dcartapi_api_key": $3dcartapi_api_key, "amazon_access_key_id": $amazon_access_key_id, "amazon_access_token": $amazon_access_token, "amazon_marketplaces_ids": $amazon_marketplaces_ids, "amazon_secret_key": $amazon_secret_key, "amazon_seller_id": $amazon_seller_id, "amazon_sp_api_environment": $amazon_sp_api_environment, "amazon_sp_aws_region": $amazon_sp_aws_region, "amazon_sp_aws_role_arn": $amazon_sp_aws_role_arn, "amazon_sp_aws_user_key_id": $amazon_sp_aws_user_key_id, "amazon_sp_aws_user_secret": $amazon_sp_aws_user_secret, "amazon_sp_client_id": $amazon_sp_client_id, "amazon_sp_client_secret": $amazon_sp_client_secret, "amazon_sp_refresh_token": $amazon_sp_refresh_token, "aspdotnetstorefront_api_pass": $aspdotnetstorefront_api_pass, "aspdotnetstorefront_api_user": $aspdotnetstorefront_api_user, "bigcommerceapi_access_token": $bigcommerceapi_access_token, "bigcommerceapi_admin_account": $bigcommerceapi_admin_account, "bigcommerceapi_api_key": $bigcommerceapi_api_key, "bigcommerceapi_api_path": $bigcommerceapi_api_path, "bigcommerceapi_client_id": $bigcommerceapi_client_id, "bigcommerceapi_context": $bigcommerceapi_context, "bridge_url": $bridge_url, "cart_id": $cart_id, "commercehq_api_key": $commercehq_api_key, "commercehq_api_password": $commercehq_api_password, "db_tables_prefix": $db_tables_prefix, "demandware_api_password": $demandware_api_password, "demandware_client_id": $demandware_client_id, "demandware_user_name": $demandware_user_name, "demandware_user_password": $demandware_user_password, "ebay_access_token": $ebay_access_token, "ebay_client_id": $ebay_client_id, "ebay_client_secret": $ebay_client_secret, "ebay_environment": $ebay_environment, "ebay_refresh_token": $ebay_refresh_token, "ebay_runame": $ebay_runame, "ebay_site_id": $ebay_site_id, "ecwid_acess_token": $ecwid_acess_token, "ecwid_store_id": $ecwid_store_id, "etsy_access_token": $etsy_access_token, "etsy_client_id": $etsy_client_id, "etsy_keystring": $etsy_keystring, "etsy_refresh_token": $etsy_refresh_token, "etsy_shared_secret": $etsy_shared_secret, "etsy_token_secret": $etsy_token_secret, "ftp_host": $ftp_host, "ftp_password": $ftp_password, "ftp_port": $ftp_port, "ftp_store_dir": $ftp_store_dir, "ftp_user": $ftp_user, "hybris_client_id": $hybris_client_id, "hybris_client_secret": $hybris_client_secret, "hybris_password": $hybris_password, "hybris_username": $hybris_username, "hybris_websites": $hybris_websites, "lightspeed_api_key": $lightspeed_api_key, "lightspeed_api_secret": $lightspeed_api_secret, "magento_access_token": $magento_access_token, "magento_consumer_key": $magento_consumer_key, "magento_consumer_secret": $magento_consumer_secret, "magento_token_secret": $magento_token_secret, "mercado_libre_app_id": $mercado_libre_app_id, "mercado_libre_app_secret_key": $mercado_libre_app_secret_key, "mercado_libre_refresh_token": $mercado_libre_refresh_token, "neto_api_key": $neto_api_key, "neto_api_username": $neto_api_username, "prestashop_webservice_key": $prestashop_webservice_key, "shopify_access_token": $shopify_access_token, "shopify_api_key": $shopify_api_key, "shopify_api_password": $shopify_api_password, "shopify_shared_secret": $shopify_shared_secret, "shopware_access_key": $shopware_access_key, "shopware_api_key": $shopware_api_key, "shopware_api_secret": $shopware_api_secret, "squarespace_api_key": $squarespace_api_key, "store_key": $store_key, "store_root": $store_root, "store_url": $store_url, "validate_version": $validate_version, "verify": $verify, "volusion_login": $volusion_login, "volusion_password": $volusion_password, "walmart_channel_type": $walmart_channel_type, "walmart_client_id": $walmart_client_id, "walmart_client_secret": $walmart_client_secret, "walmart_environment": $walmart_environment, "wc_consumer_key": $wc_consumer_key, "wc_consumer_secret": $wc_consumer_secret, "wix_app_id": $wix_app_id, "wix_app_secret_key": $wix_app_secret_key, "wix_refresh_token": $wix_refresh_token, "zid_access_token": $zid_access_token, "zid_authorization": $zid_authorization, "zid_client_id": $zid_client_id, "zid_client_secret": $zid_client_secret, "zid_refresh_token": $zid_refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of carts.
#
# GET /account.cart.list.json
# operationId: AccountCartList
export def "account-cart-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --request-from-date: string # Retrieve entities from their creation date
  --request-to-date: string # Retrieve entities to their creation date
  --store-url: string # A web address of a store
  --store-key: string # Find store by store key
]: nothing -> record<result: record<carts: list<record>, carts_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "request_from_date" $request_from_date "scalar") (serialize-qp "request_to_date" $request_to_date "scalar") (serialize-qp "store_url" $store_url "scalar") (serialize-qp "store_key" $store_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account.cart.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "exclude": $exclude, "request_from_date": $request_from_date, "request_to_date": $request_to_date, "store_url": $store_url, "store_key": $store_key} | compact), body: null}
}

# Update configs in the API2Cart database.
#
# PUT /account.config.update.json
# operationId: AccountConfigUpdate
export def "account-config-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-store-key: string # Update store key
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  --db-tables-prefix: string # DB tables prefix
  --3dcart-private-key: string # 3DCart Private Key
  --3dcart-access-token: string # 3DCart Token
  --3dcartapi-api-key: string # 3DCart API Key
  --amazon-sp-client-id: string # Amazon SP API app client id
  --amazon-sp-client-secret: string # Amazon SP API app client secret
  --amazon-sp-aws-user-key-id: string # Amazon AWS user access key ID
  --amazon-sp-aws-user-secret: string # Amazon AWS user secret access key
  --amazon-sp-aws-region: string # Amazon AWS Region
  --amazon-sp-aws-role-arn: string # Amazon AWS Role ARN
  --amazon-sp-refresh-token: string # Amazon SP API OAuth refresh token
  --amazon-sp-api-environment: string # Amazon SP API environment (default: production)
  --amazon-access-token: string # MWS Auth Token. Access token authorizing the app to access resources on behalf of a user
  --amazon-seller-id: string # Amazon Seller ID (Merchant token)
  --amazon-marketplaces-ids: string # Amazon Marketplace IDs comma separated string
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --aspdotnetstorefront-api-user: string # It's a AspDotNetStorefront account for which API is available
  --aspdotnetstorefront-api-pass: string # AspDotNetStorefront API Password
  --bigcommerceapi-admin-account: string # It's a BigCommerce account for which API is enabled
  --bigcommerceapi-api-path: string # BigCommerce API URL
  --bigcommerceapi-api-key: string # Bigcommerce API Key
  --bigcommerceapi-client-id: string # Client ID of the requesting app
  --bigcommerceapi-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --bigcommerceapi-context: string # API Path section unique to the store
  --demandware-client-id: string # Demandware client id
  --demandware-api-password: string # Demandware api password
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-environment: string # eBay environment
  --ebay-site-id: int # eBay global ID (default: 0)
  --ecwid-acess-token: string # Access token authorizing the app to access resources on behalf of a user
  --ecwid-store-id: string # Store Id
  --etsy-keystring: string # Etsy keystring
  --etsy-shared-secret: string # Etsy shared secret
  --etsy-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --etsy-token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --etsy-client-id: string # Etsy Client Id
  --etsy-refresh-token: string # Etsy Refresh token
  --neto-api-key: string # Neto API Key
  --neto-api-username: string # Neto User Name
  --shopify-api-key: string # Shopify API Key
  --shopify-api-password: string # Shopify API Password
  --shopify-shared-secret: string # Shared secret
  --shopify-access-token: string # Access token authorizing the app to access resources on behalf of a user
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --volusion-login: string # It's a Volusion account for which API is enabled
  --volusion-password: string # Volusion API Password
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --squarespace-api-key: string # Squarespace API Key
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-username: string # User Name
  --hybris-password: string # User password
  --hybris-websites: list<string> # Websites to stores mapping data
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-access-token: string # Magento Access Token
  --magento-token-secret: string # Magento Token Secret
  --prestashop-webservice-key: string # Prestashop webservice key
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-refresh-token: string # Zid refresh token
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "new_store_key" $new_store_key "scalar") (serialize-qp "bridge_url" $bridge_url "scalar") (serialize-qp "store_root" $store_root "scalar") (serialize-qp "db_tables_prefix" $db_tables_prefix "scalar") (serialize-qp "3dcart_private_key" $3dcart_private_key "scalar") (serialize-qp "3dcart_access_token" $3dcart_access_token "scalar") (serialize-qp "3dcartapi_api_key" $3dcartapi_api_key "scalar") (serialize-qp "amazon_sp_client_id" $amazon_sp_client_id "scalar") (serialize-qp "amazon_sp_client_secret" $amazon_sp_client_secret "scalar") (serialize-qp "amazon_sp_aws_user_key_id" $amazon_sp_aws_user_key_id "scalar") (serialize-qp "amazon_sp_aws_user_secret" $amazon_sp_aws_user_secret "scalar") (serialize-qp "amazon_sp_aws_region" $amazon_sp_aws_region "scalar") (serialize-qp "amazon_sp_aws_role_arn" $amazon_sp_aws_role_arn "scalar") (serialize-qp "amazon_sp_refresh_token" $amazon_sp_refresh_token "scalar") (serialize-qp "amazon_sp_api_environment" $amazon_sp_api_environment "scalar") (serialize-qp "amazon_access_token" $amazon_access_token "scalar") (serialize-qp "amazon_seller_id" $amazon_seller_id "scalar") (serialize-qp "amazon_marketplaces_ids" $amazon_marketplaces_ids "scalar") (serialize-qp "amazon_secret_key" $amazon_secret_key "scalar") (serialize-qp "amazon_access_key_id" $amazon_access_key_id "scalar") (serialize-qp "aspdotnetstorefront_api_user" $aspdotnetstorefront_api_user "scalar") (serialize-qp "aspdotnetstorefront_api_pass" $aspdotnetstorefront_api_pass "scalar") (serialize-qp "bigcommerceapi_admin_account" $bigcommerceapi_admin_account "scalar") (serialize-qp "bigcommerceapi_api_path" $bigcommerceapi_api_path "scalar") (serialize-qp "bigcommerceapi_api_key" $bigcommerceapi_api_key "scalar") (serialize-qp "bigcommerceapi_client_id" $bigcommerceapi_client_id "scalar") (serialize-qp "bigcommerceapi_access_token" $bigcommerceapi_access_token "scalar") (serialize-qp "bigcommerceapi_context" $bigcommerceapi_context "scalar") (serialize-qp "demandware_client_id" $demandware_client_id "scalar") (serialize-qp "demandware_api_password" $demandware_api_password "scalar") (serialize-qp "demandware_user_name" $demandware_user_name "scalar") (serialize-qp "demandware_user_password" $demandware_user_password "scalar") (serialize-qp "ebay_client_id" $ebay_client_id "scalar") (serialize-qp "ebay_client_secret" $ebay_client_secret "scalar") (serialize-qp "ebay_runame" $ebay_runame "scalar") (serialize-qp "ebay_access_token" $ebay_access_token "scalar") (serialize-qp "ebay_refresh_token" $ebay_refresh_token "scalar") (serialize-qp "ebay_environment" $ebay_environment "scalar") (serialize-qp "ebay_site_id" $ebay_site_id "scalar") (serialize-qp "ecwid_acess_token" $ecwid_acess_token "scalar") (serialize-qp "ecwid_store_id" $ecwid_store_id "scalar") (serialize-qp "etsy_keystring" $etsy_keystring "scalar") (serialize-qp "etsy_shared_secret" $etsy_shared_secret "scalar") (serialize-qp "etsy_access_token" $etsy_access_token "scalar") (serialize-qp "etsy_token_secret" $etsy_token_secret "scalar") (serialize-qp "etsy_client_id" $etsy_client_id "scalar") (serialize-qp "etsy_refresh_token" $etsy_refresh_token "scalar") (serialize-qp "neto_api_key" $neto_api_key "scalar") (serialize-qp "neto_api_username" $neto_api_username "scalar") (serialize-qp "shopify_api_key" $shopify_api_key "scalar") (serialize-qp "shopify_api_password" $shopify_api_password "scalar") (serialize-qp "shopify_shared_secret" $shopify_shared_secret "scalar") (serialize-qp "shopify_access_token" $shopify_access_token "scalar") (serialize-qp "shopware_access_key" $shopware_access_key "scalar") (serialize-qp "shopware_api_key" $shopware_api_key "scalar") (serialize-qp "shopware_api_secret" $shopware_api_secret "scalar") (serialize-qp "volusion_login" $volusion_login "scalar") (serialize-qp "volusion_password" $volusion_password "scalar") (serialize-qp "walmart_client_id" $walmart_client_id "scalar") (serialize-qp "walmart_client_secret" $walmart_client_secret "scalar") (serialize-qp "walmart_environment" $walmart_environment "scalar") (serialize-qp "walmart_channel_type" $walmart_channel_type "scalar") (serialize-qp "squarespace_api_key" $squarespace_api_key "scalar") (serialize-qp "hybris_client_id" $hybris_client_id "scalar") (serialize-qp "hybris_client_secret" $hybris_client_secret "scalar") (serialize-qp "hybris_username" $hybris_username "scalar") (serialize-qp "hybris_password" $hybris_password "scalar") (serialize-qp "hybris_websites" $hybris_websites "csv") (serialize-qp "lightspeed_api_key" $lightspeed_api_key "scalar") (serialize-qp "lightspeed_api_secret" $lightspeed_api_secret "scalar") (serialize-qp "commercehq_api_key" $commercehq_api_key "scalar") (serialize-qp "commercehq_api_password" $commercehq_api_password "scalar") (serialize-qp "wc_consumer_key" $wc_consumer_key "scalar") (serialize-qp "wc_consumer_secret" $wc_consumer_secret "scalar") (serialize-qp "magento_consumer_key" $magento_consumer_key "scalar") (serialize-qp "magento_consumer_secret" $magento_consumer_secret "scalar") (serialize-qp "magento_access_token" $magento_access_token "scalar") (serialize-qp "magento_token_secret" $magento_token_secret "scalar") (serialize-qp "prestashop_webservice_key" $prestashop_webservice_key "scalar") (serialize-qp "wix_app_id" $wix_app_id "scalar") (serialize-qp "wix_app_secret_key" $wix_app_secret_key "scalar") (serialize-qp "wix_refresh_token" $wix_refresh_token "scalar") (serialize-qp "mercado_libre_app_id" $mercado_libre_app_id "scalar") (serialize-qp "mercado_libre_app_secret_key" $mercado_libre_app_secret_key "scalar") (serialize-qp "mercado_libre_refresh_token" $mercado_libre_refresh_token "scalar") (serialize-qp "zid_client_id" $zid_client_id "scalar") (serialize-qp "zid_client_secret" $zid_client_secret "scalar") (serialize-qp "zid_access_token" $zid_access_token "scalar") (serialize-qp "zid_authorization" $zid_authorization "scalar") (serialize-qp "zid_refresh_token" $zid_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account.config.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"new_store_key": $new_store_key, "bridge_url": $bridge_url, "store_root": $store_root, "db_tables_prefix": $db_tables_prefix, "3dcart_private_key": $3dcart_private_key, "3dcart_access_token": $3dcart_access_token, "3dcartapi_api_key": $3dcartapi_api_key, "amazon_sp_client_id": $amazon_sp_client_id, "amazon_sp_client_secret": $amazon_sp_client_secret, "amazon_sp_aws_user_key_id": $amazon_sp_aws_user_key_id, "amazon_sp_aws_user_secret": $amazon_sp_aws_user_secret, "amazon_sp_aws_region": $amazon_sp_aws_region, "amazon_sp_aws_role_arn": $amazon_sp_aws_role_arn, "amazon_sp_refresh_token": $amazon_sp_refresh_token, "amazon_sp_api_environment": $amazon_sp_api_environment, "amazon_access_token": $amazon_access_token, "amazon_seller_id": $amazon_seller_id, "amazon_marketplaces_ids": $amazon_marketplaces_ids, "amazon_secret_key": $amazon_secret_key, "amazon_access_key_id": $amazon_access_key_id, "aspdotnetstorefront_api_user": $aspdotnetstorefront_api_user, "aspdotnetstorefront_api_pass": $aspdotnetstorefront_api_pass, "bigcommerceapi_admin_account": $bigcommerceapi_admin_account, "bigcommerceapi_api_path": $bigcommerceapi_api_path, "bigcommerceapi_api_key": $bigcommerceapi_api_key, "bigcommerceapi_client_id": $bigcommerceapi_client_id, "bigcommerceapi_access_token": $bigcommerceapi_access_token, "bigcommerceapi_context": $bigcommerceapi_context, "demandware_client_id": $demandware_client_id, "demandware_api_password": $demandware_api_password, "demandware_user_name": $demandware_user_name, "demandware_user_password": $demandware_user_password, "ebay_client_id": $ebay_client_id, "ebay_client_secret": $ebay_client_secret, "ebay_runame": $ebay_runame, "ebay_access_token": $ebay_access_token, "ebay_refresh_token": $ebay_refresh_token, "ebay_environment": $ebay_environment, "ebay_site_id": $ebay_site_id, "ecwid_acess_token": $ecwid_acess_token, "ecwid_store_id": $ecwid_store_id, "etsy_keystring": $etsy_keystring, "etsy_shared_secret": $etsy_shared_secret, "etsy_access_token": $etsy_access_token, "etsy_token_secret": $etsy_token_secret, "etsy_client_id": $etsy_client_id, "etsy_refresh_token": $etsy_refresh_token, "neto_api_key": $neto_api_key, "neto_api_username": $neto_api_username, "shopify_api_key": $shopify_api_key, "shopify_api_password": $shopify_api_password, "shopify_shared_secret": $shopify_shared_secret, "shopify_access_token": $shopify_access_token, "shopware_access_key": $shopware_access_key, "shopware_api_key": $shopware_api_key, "shopware_api_secret": $shopware_api_secret, "volusion_login": $volusion_login, "volusion_password": $volusion_password, "walmart_client_id": $walmart_client_id, "walmart_client_secret": $walmart_client_secret, "walmart_environment": $walmart_environment, "walmart_channel_type": $walmart_channel_type, "squarespace_api_key": $squarespace_api_key, "hybris_client_id": $hybris_client_id, "hybris_client_secret": $hybris_client_secret, "hybris_username": $hybris_username, "hybris_password": $hybris_password, "hybris_websites": $hybris_websites, "lightspeed_api_key": $lightspeed_api_key, "lightspeed_api_secret": $lightspeed_api_secret, "commercehq_api_key": $commercehq_api_key, "commercehq_api_password": $commercehq_api_password, "wc_consumer_key": $wc_consumer_key, "wc_consumer_secret": $wc_consumer_secret, "magento_consumer_key": $magento_consumer_key, "magento_consumer_secret": $magento_consumer_secret, "magento_access_token": $magento_access_token, "magento_token_secret": $magento_token_secret, "prestashop_webservice_key": $prestashop_webservice_key, "wix_app_id": $wix_app_id, "wix_app_secret_key": $wix_app_secret_key, "wix_refresh_token": $wix_refresh_token, "mercado_libre_app_id": $mercado_libre_app_id, "mercado_libre_app_secret_key": $mercado_libre_app_secret_key, "mercado_libre_refresh_token": $mercado_libre_refresh_token, "zid_client_id": $zid_client_id, "zid_client_secret": $zid_client_secret, "zid_access_token": $zid_access_token, "zid_authorization": $zid_authorization, "zid_refresh_token": $zid_refresh_token} | compact), body: null}
}

# List webhooks that was not delivered to the callback.
#
# GET /account.failed_webhooks.json
# operationId: AccountFailedWebhooks
export def "account-failed-webhooks-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --ids: string # List of сomma-separated webhook ids
]: nothing -> record<result: record<all_failed_webhook: string, webhook: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account.failed_webhooks.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "start": $start, "ids": $ids} | compact), body: null}
}

# Get list of supported platforms
#
# GET /account.supported_platforms.json
# operationId: AccountSupportedPlatforms
export def "account-supported-platforms-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<supported_platforms: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account.supported_platforms.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add new attribute
#
# POST /attribute.add.json
# operationId: AttributeAdd
export def "attribute-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Defines attribute's type
  --code: string # Entity code
  --name: string # Defines attributes's name
  --store-id: string # Store Id
  --lang-id: string # Language id
  --visible: oneof<nothing, bool> # Set visibility status (default: false)
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --position: int # Attribute`s position (default: 0)
  --attribute-group-id: string # Filter by attribute_group_id
  --is-global: string # Attribute saving scope (default: Store)
  --is-searchable: oneof<nothing, bool> # Use attribute in Quick Search (default: false)
  --is-filterable: string # Use In Layered Navigation (default: No)
  --is-comparable: oneof<nothing, bool> # Comparable on Front-end (default: false)
  --is-html-allowed-on-front: oneof<nothing, bool> # Allow HTML Tags on Frontend (default: false)
  --is-filterable-in-search: oneof<nothing, bool> # Use In Search Results Layered Navigation (default: false)
  --is-configurable: oneof<nothing, bool> # Use To Create Configurable Product (default: false)
  --is-visible-in-advanced-search: oneof<nothing, bool> # Use in Advanced Search (default: false)
  --is-used-for-promo-rules: oneof<nothing, bool> # Use for Promo Rule Conditions (default: false)
  --used-in-product-listing: oneof<nothing, bool> # Used in Product Listing (default: false)
  --used-for-sort-by: oneof<nothing, bool> # Used for Sorting in Product Listing (default: false)
  --apply-to: string # Types of products which can have this attribute (default: all_types)
]: nothing -> record<result: record<id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "attribute_group_id" $attribute_group_id "scalar") (serialize-qp "is_global" $is_global "scalar") (serialize-qp "is_searchable" $is_searchable "scalar") (serialize-qp "is_filterable" $is_filterable "scalar") (serialize-qp "is_comparable" $is_comparable "scalar") (serialize-qp "is_html_allowed_on_front" $is_html_allowed_on_front "scalar") (serialize-qp "is_filterable_in_search" $is_filterable_in_search "scalar") (serialize-qp "is_configurable" $is_configurable "scalar") (serialize-qp "is_visible_in_advanced_search" $is_visible_in_advanced_search "scalar") (serialize-qp "is_used_for_promo_rules" $is_used_for_promo_rules "scalar") (serialize-qp "used_in_product_listing" $used_in_product_listing "scalar") (serialize-qp "used_for_sort_by" $used_for_sort_by "scalar") (serialize-qp "apply_to" $apply_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "code": $code, "name": $name, "store_id": $store_id, "lang_id": $lang_id, "visible": $visible, "required": $required, "position": $position, "attribute_group_id": $attribute_group_id, "is_global": $is_global, "is_searchable": $is_searchable, "is_filterable": $is_filterable, "is_comparable": $is_comparable, "is_html_allowed_on_front": $is_html_allowed_on_front, "is_filterable_in_search": $is_filterable_in_search, "is_configurable": $is_configurable, "is_visible_in_advanced_search": $is_visible_in_advanced_search, "is_used_for_promo_rules": $is_used_for_promo_rules, "used_in_product_listing": $used_in_product_listing, "used_for_sort_by": $used_for_sort_by, "apply_to": $apply_to} | compact), body: null}
}

# Assign attribute to the group
#
# POST /attribute.assign.group.json
# operationId: AttributeAssignGroup
export def "attribute-assign-group-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --group-id: string # Attribute group_id
  --attribute-set-id: string # Attribute set id
]: nothing -> record<result: record<assigned: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "attribute_set_id" $attribute_set_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.assign.group.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "group_id": $group_id, "attribute_set_id": $attribute_set_id} | compact), body: null}
}

# Assign attribute to the attribute set
#
# POST /attribute.assign.set.json
# operationId: AttributeAssignSet
export def "attribute-assign-set-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --group-id: string # Attribute group_id
  --attribute-set-id: string # Attribute set id
]: nothing -> record<result: record<assigned: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "attribute_set_id" $attribute_set_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.assign.set.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "group_id": $group_id, "attribute_set_id": $attribute_set_id} | compact), body: null}
}

# Get attribute_set list
#
# GET /attribute.attributeset.list.json
# operationId: AttributeAttributesetList
export def "attribute-attributeset-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.attributeset.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Get attributes count
#
# GET /attribute.count.json
# operationId: AttributeCount
export def "attribute-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Defines attribute's type
  --store-id: string # Store Id
  --lang-id: string # Language id
  --visible: oneof<nothing, bool> # Filter items by visibility status
  --required: oneof<nothing, bool> # Defines if the option is required
  --system: oneof<nothing, bool> # True if attribute is system
]: nothing -> record<result: record<attributes_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "system" $system "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "store_id": $store_id, "lang_id": $lang_id, "visible": $visible, "required": $required, "system": $system} | compact), body: null}
}

# Delete attribute from store
#
# DELETE /attribute.delete.json
# operationId: AttributeDelete
export def "attribute-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --id: string # Entity id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "id": $id} | compact), body: null}
}

# Get attribute group list
#
# GET /attribute.group.list.json
# operationId: AttributeGroupList
export def "attribute-group-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --attribute-set-id: string # Attribute set id
]: nothing -> record<result: table<additional_fields: record, assigned_attribute_ids: list, attribute_set_id: string, custom_fields: record, id: string, name: string, position: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "attribute_set_id" $attribute_set_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.group.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "lang_id": $lang_id, "params": $params, "exclude": $exclude, "response_fields": $response_fields, "attribute_set_id": $attribute_set_id} | compact), body: null}
}

# Get attribute info
#
# GET /attribute.info.json
# operationId: AttributeInfo
export def "attribute-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: record<additional_fields: record, code: string, custom_fields: record, default_values: list<string>, id: string, lang_id: string, name: string, position: int, required: bool, store_id: string, system: bool, type: string, values: list<string>, visible: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "store_id": $store_id, "lang_id": $lang_id, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Get attributes list
#
# GET /attribute.list.json
# operationId: AttributeList
export def "attribute-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --type: string # Defines attribute's type
  --attribute-ids: string # Filter attributes by ids
  --store-id: string # Store Id
  --lang-id: string # Retrieves attributes on specified language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,code,type)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --visible: oneof<nothing, bool> # Filter items by visibility status
  --required: oneof<nothing, bool> # Defines if the option is required
  --system: oneof<nothing, bool> # True if attribute is system
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, attributes_count: int, custom_fields: record>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "attribute_ids" $attribute_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "system" $system "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "type": $type, "attribute_ids": $attribute_ids, "store_id": $store_id, "lang_id": $lang_id, "params": $params, "exclude": $exclude, "response_fields": $response_fields, "visible": $visible, "required": $required, "system": $system} | compact), body: null}
}

# Get list of supported attributes types
#
# GET /attribute.type.list.json
# operationId: AttributeTypeList
export def "attribute-type-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<attribute_type: list<string>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attribute.type.list.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unassign attribute from group
#
# POST /attribute.unassign.group.json
# operationId: AttributeUnassignGroup
export def "attribute-unassign-group-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --group-id: string # Customer group_id
]: nothing -> record<result: record<unassigned: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.unassign.group.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "group_id": $group_id} | compact), body: null}
}

# Unassign attribute from attribute set
#
# POST /attribute.unassign.set.json
# operationId: AttributeUnassignSet
export def "attribute-unassign-set-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --attribute-set-id: string # Attribute set id
]: nothing -> record<result: record<unassigned: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "attribute_set_id" $attribute_set_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.unassign.set.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "attribute_set_id": $attribute_set_id} | compact), body: null}
}

# Update attribute data
#
# POST /attribute.update.json
# operationId: AttributeUpdate
export def "attribute-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --name: string # Defines new attributes's name
  --store-id: string # Store Id
  --lang-id: string # Language id
]: nothing -> record<result: record<updated: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attribute.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name, "store_id": $store_id, "lang_id": $lang_id} | compact), body: null}
}

# Retrieve basket information.
#
# GET /basket.info.json
# operationId: BasketInfo
export def "basket-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: record<additional_fields: record, basket_products: list<record>, basket_url: string, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/basket.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "store_id": $store_id, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Add item to basket
#
# POST /basket.item.add.json
# operationId: BasketItemAdd
export def "basket-item-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --product-id: string # Defines id of the product which should be added to the basket
  --variant-id: string # Defines product's variants specified by variant id
  --quantity: float # Defines new items quantity (default: 0)
  --store-id: string # Store Id
]: nothing -> record<result: record<added: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "variant_id" $variant_id "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/basket.item.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customer_id": $customer_id, "product_id": $product_id, "variant_id": $variant_id, "quantity": $quantity, "store_id": $store_id} | compact), body: null}
}

# Create live shipping rate service. (Beta)
#
# POST /basket.live_shipping_service.create.json
# operationId: BasketLiveShippingServiceCreate
export def "basket-live-shipping-service-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --name: string # Shipping Service Name
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data.
]: nothing -> record<result: record<id: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/basket.live_shipping_service.create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "name": $name, "callback": $callback} | compact), body: null}
}

# Delete live shipping rate service. (Beta)
#
# DELETE /basket.live_shipping_service.delete.json
# operationId: BasketLiveShippingServiceDelete
export def "basket-live-shipping-service-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Entity id
]: nothing -> record<result: record<status: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/basket.live_shipping_service.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Retrieve a list of live shipping rate services. (Beta)
#
# GET /basket.live_shipping_service.list.json
# operationId: BasketLiveShippingServiceList
export def "basket-live-shipping-service-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
]: nothing -> record<result: record<live_shipping_services: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/basket.live_shipping_service.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "start": $start, "count": $count} | compact), body: null}
}

# Delete bridge from the store.
#
# POST /bridge.delete.json
# operationId: BridgeDelete
export def "bridge-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<deleted: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bridge.delete.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download bridge for store
#
# GET /bridge.download.file
# operationId: BridgeDownload
export def "bridge-download-file download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --whitelabel: oneof<nothing, bool> # Identifies if there is a necessity to download whitelabel bridge. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "whitelabel" $whitelabel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bridge.download.file" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"whitelabel": $whitelabel} | compact), body: null}
}

# Update bridge in the store.
#
# POST /bridge.update.json
# operationId: BridgeUpdate
export def "bridge-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<updated: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bridge.update.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get bridge key and store key
#
# GET /cart.bridge.json
# operationId: CartBridge
export def "cart-bridge-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<bridge: string, store_key: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.bridge.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get count of cart catalog price rules discounts.
#
# GET /cart.catalog_price_rules.count.json
# operationId: CartCatalogPriceRulesCount
export def "cart-catalog-price-rules-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<catalog_price_rules_count: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.catalog_price_rules.count.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get cart catalog price rules discounts.
#
# GET /cart.catalog_price_rules.list.json
# operationId: CartCatalogPriceRulesList
export def "cart-catalog-price-rules-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --ids: string # Retrieves catalog_price_rules by ids
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, catalog_price_rules: list<record>, catalog_price_rules_count: int, custom_fields: record>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.catalog_price_rules.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "ids": $ids, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Clear cache on store.
#
# POST /cart.clear_cache.json
# operationId: CartClearCache
export def "cart-clear-cache-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-type: string # Defines which cache should be cleared.
]: nothing -> record<result: record<cache_cleared: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cache_type" $cache_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.clear_cache.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cache_type": $cache_type} | compact), body: null}
}

# Get list of cart configs
#
# GET /cart.config.json
# operationId: CartConfig
export def "cart-config-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: store_name,store_url,db_prefix)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<result: record<db_prefix: string, store_name: string, store_url: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.config.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "exclude": $exclude} | compact), body: null}
}

# Use this API method to update custom data in client database.
#
# PUT /cart.config.update.json
# DEPRECATED
# operationId: CartConfigUpdate
@deprecated
export def "cart-config-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # This parameter sets the list of params to the shopping cart.
  --db-tables-prefix: string # This parameter is deprecated for this method. Please, use this parameter in method account.config.update
  --store-id: string # Store Id
]: any -> record<result: record, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.config.update.json")
  let req_body = {"custom_fields": $custom_fields, "db_tables_prefix": $db_tables_prefix, "store_id": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create new coupon
#
# POST /cart.coupon.add.json
# operationId: CartCouponAdd
export def "cart-coupon-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action_amount: float # Defines the discount amount value.
  action_apply_to: string@action-apply-to-completer # Defines where discount should be applied
  --action-condition-entity: string # Defines entity for action condition.
  --action-condition-key: string # Defines entity attribute code for action condition.
  --action-condition-operator: string # Defines condition operator.
  --action-condition-value: string # Defines condition attribute value/s. Can be comma separated string.
  action_scope: string@action-scope-completer # Specify how discount should be applied. If scope=matching_items, then discount will be applied to each of the items that match action conditions. Scope order means that discount will be applied once.
  action_type: string@action-type-completer # Coupon discount type
  code: string # Coupon code
  --codes: list<string> # Entity codes
  --date-end: string # Defines when discount code will be expired.
  --date-start: string # Defines when discount code will be available. (default: now)
  --name: string # Coupon name
  --store-id: string # Store Id
  --usage-limit: int # Usage limit for coupon.
  --usage-limit-per-customer: int # Usage limit per customer.
]: any -> record<result: record<coupon_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.coupon.add.json")
  let req_body = {"action_amount": $action_amount, "action_apply_to": $action_apply_to, "action_condition_entity": $action_condition_entity, "action_condition_key": $action_condition_key, "action_condition_operator": $action_condition_operator, "action_condition_value": $action_condition_value, "action_scope": $action_scope, "action_type": $action_type, "code": $code, "codes": $codes, "date_end": $date_end, "date_start": $date_start, "name": $name, "store_id": $store_id, "usage_limit": $usage_limit, "usage_limit_per_customer": $usage_limit_per_customer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create new coupon condition
#
# POST /cart.coupon.condition.add.json
# operationId: CartCouponConditionAdd
export def "cart-coupon-condition-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --coupon-id: string # Coupon Id
  --target: string # Defines condition operator (default: coupon_prerequisite)
  --entity: string@entity-completer # Defines condition entity type
  --key: string@key-completer # Defines condition entity attribute key
  --operator: string@operator-completer # Defines condition operator
  --value: string # Defines condition value, can be comma separated according to the operator.
]: nothing -> record<result: record<status: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "coupon_id" $coupon_id "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "operator" $operator "scalar") (serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.coupon.condition.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "coupon_id": $coupon_id, "target": $target, "entity": $entity, "key": $key, "operator": $operator, "value": $value} | compact), body: null}
}

# Get cart coupons count.
#
# GET /cart.coupon.count.json
# operationId: CartCouponCount
export def "cart-coupon-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --date-start-from: string # Filter entity by date_start (greater or equal)
  --date-start-to: string # Filter entity by date_start (less or equal)
  --date-end-from: string # Filter entity by date_end (greater or equal)
  --date-end-to: string # Filter entity by date_end (less or equal)
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> record<result: record<coupons_count: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "date_start_from" $date_start_from "scalar") (serialize-qp "date_start_to" $date_start_to "scalar") (serialize-qp "date_end_from" $date_end_from "scalar") (serialize-qp "date_end_to" $date_end_to "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.coupon.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "date_start_from": $date_start_from, "date_start_to": $date_start_to, "date_end_from": $date_end_from, "date_end_to": $date_end_to, "avail": $avail} | compact), body: null}
}

# Delete coupon
#
# DELETE /cart.coupon.delete.json
# operationId: CartCouponDelete
export def "cart-coupon-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --store-id: string # Store Id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.coupon.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "store_id": $store_id} | compact), body: null}
}

# Get cart coupon discounts.
#
# GET /cart.coupon.list.json
# operationId: CartCouponList
export def "cart-coupon-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --coupons-ids: string # Filter coupons by ids
  --store-id: string # Filter coupons by store id
  --date-start-from: string # Filter entity by date_start (greater or equal)
  --date-start-to: string # Filter entity by date_start (less or equal)
  --date-end-from: string # Filter entity by date_end (greater or equal)
  --date-end-to: string # Filter entity by date_end (less or equal)
  --avail: oneof<nothing, bool> # Filter coupons by avail status
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,code,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, coupon: list<record>, coupon_count: int, custom_fields: record>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "coupons_ids" $coupons_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "date_start_from" $date_start_from "scalar") (serialize-qp "date_start_to" $date_start_to "scalar") (serialize-qp "date_end_from" $date_end_from "scalar") (serialize-qp "date_end_to" $date_end_to "scalar") (serialize-qp "avail" $avail "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.coupon.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "coupons_ids": $coupons_ids, "store_id": $store_id, "date_start_from": $date_start_from, "date_start_to": $date_start_to, "date_end_from": $date_end_from, "date_end_to": $date_end_to, "avail": $avail, "lang_id": $lang_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Add store to the account
#
# POST /cart.create.json
# DEPRECATED
# operationId: CartCreate
@deprecated
export def "cart-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart-id: string@cart-id-completer # Store’s identifier which you can get from cart_list method
  --store-url: string # A web address of a store that you would like to connect to API2Cart
  --bridge-url: string # This parameter allows to set up store with custom bridge url (also you must use store_root parameter if a bridge folder is not in the root folder of the store)
  --store-root: string # Absolute path to the store root directory (used with "bridge_url" parameter)
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --shared-secret: string # Shared secret
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
  --verify: oneof<nothing, bool> # Enables or disables cart's verification (default: true)
  --db-tables-prefix: string # DB tables prefix
  --ftp-host: string # FTP connection host
  --ftp-user: string # FTP User
  --ftp-password: string # FTP Password
  --ftp-port: int # FTP Port
  --ftp-store-dir: string # FTP Store dir
  --api-key-3dcart: string # 3DCart API Key
  --admin-account: string # It's a BigCommerce account for which API is enabled
  --api-path: string # BigCommerce API URL
  --api-key: string # Bigcommerce API Key
  --client-id: string # Client ID of the requesting app
  --access-token: string # Access token authorizing the app to access resources on behalf of a user
  --context: string # API Path section unique to the store
  --access-token-2: string # Access token authorizing the app to access resources on behalf of a user (disambiguated-2)
  --api-key-shopify: string # Shopify API Key
  --api-password: string # Shopify API Password
  --access-token-shopify: string # Access token authorizing the app to access resources on behalf of a user
  --api-key-2: string # Neto API Key (disambiguated-2)
  --api-username: string # Neto User Name
  --encrypted-password: string # Volusion API Password
  --login: string # It's a Volusion account for which API is enabled
  --api-user-adnsf: string # It's a AspDotNetStorefront account for which API is available
  --api-pass: string # AspDotNetStorefront API Password
  --access-key-scelite: string # Shopping Cart Elite Access Key
  --api-key-scelite: string # Shopping Cart Elite API Key
  --api-secret-key-scelite: string # Shopping Cart Elite API Secret Key
  --private-key: string # 3DCart Application Private Key
  --app-token: string # 3DCart Token from Application
  --etsy-keystring: string # Etsy keystring
  --etsy-shared-secret: string # Etsy shared secret
  --token-secret: string # Secret token authorizing the app to access resources on behalf of a user
  --etsy-client-id: string # Etsy Client Id
  --etsy-refresh-token: string # Etsy Refresh token
  --ebay-client-id: string # Application ID (AppID).
  --ebay-client-secret: string # Shared Secret from eBay application
  --ebay-runame: string # The RuName value that eBay assigns to your application.
  --ebay-access-token: string # Used to authenticate API requests.
  --ebay-refresh-token: string # Used to renew the access token.
  --ebay-environment: string # eBay environment (default: production)
  --ebay-site-id: int # eBay global ID (default: 0)
  --dw-client-id: string # Demandware client id
  --dw-api-pass: string # Demandware api password
  --demandware-user-name: string # Demandware user name
  --demandware-user-password: string # Demandware user password
  --store-id: string # Store Id
  --seller-id: string # Seller Id
  --amazon-secret-key: string # Amazon Secret Key
  --amazon-access-key-id: string # Amazon Secret Key Id
  --marketplaces-ids: string # Comma separated marketplaces ids
  --environment: string # default: production
  --hybris-client-id: string # Omni Commerce Connector Client ID
  --hybris-client-secret: string # Omni Commerce Connector Client Secret
  --hybris-username: string # User Name
  --hybris-password: string # User password
  --hybris-websites: list<string> # Websites to stores mapping data
  --walmart-client-id: string # Walmart client ID
  --walmart-client-secret: string # Walmart client secret
  --walmart-environment: string # Walmart environment (default: production)
  --walmart-channel-type: string # Walmart WM_CONSUMER.CHANNEL.TYPE header
  --lightspeed-api-key: string # LightSpeed api key
  --lightspeed-api-secret: string # LightSpeed api secret
  --shopware-access-key: string # Shopware access key
  --shopware-api-key: string # Shopware api key
  --shopware-api-secret: string # Shopware client secret access key
  --commercehq-api-key: string # CommerceHQ api key
  --commercehq-api-password: string # CommerceHQ api password
  --3dcart-private-key: string # 3DCart Private Key
  --3dcart-access-token: string # 3DCart Token
  --wc-consumer-key: string # Woocommerce consumer key
  --wc-consumer-secret: string # Woocommerce consumer secret
  --magento-consumer-key: string # Magento Consumer Key
  --magento-consumer-secret: string # Magento Consumer Secret
  --magento-access-token: string # Magento Access Token
  --magento-token-secret: string # Magento Token Secret
  --prestashop-webservice-key: string # Prestashop webservice key
  --wix-app-id: string # Wix App ID
  --wix-app-secret-key: string # Wix App Secret Key
  --wix-refresh-token: string # Wix refresh token
  --mercado-libre-app-id: string # Mercado Libre App ID
  --mercado-libre-app-secret-key: string # Mercado Libre App Secret Key
  --mercado-libre-refresh-token: string # Mercado Libre Refresh Token
  --zid-client-id: int # Zid Client ID
  --zid-client-secret: string # Zid Client Secret
  --zid-access-token: string # Zid Access Token
  --zid-authorization: string # Zid Authorization
  --zid-refresh-token: string # Zid refresh token
]: nothing -> record<result: record<store_key: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cart_id" $cart_id "scalar") (serialize-qp "store_url" $store_url "scalar") (serialize-qp "bridge_url" $bridge_url "scalar") (serialize-qp "store_root" $store_root "scalar") (serialize-qp "store_key" $store_key "scalar") (serialize-qp "shared_secret" $shared_secret "scalar") (serialize-qp "validate_version" $validate_version "scalar") (serialize-qp "verify" $verify "scalar") (serialize-qp "db_tables_prefix" $db_tables_prefix "scalar") (serialize-qp "ftp_host" $ftp_host "scalar") (serialize-qp "ftp_user" $ftp_user "scalar") (serialize-qp "ftp_password" $ftp_password "scalar") (serialize-qp "ftp_port" $ftp_port "scalar") (serialize-qp "ftp_store_dir" $ftp_store_dir "scalar") (serialize-qp "apiKey_3dcart" $api_key_3dcart "scalar") (serialize-qp "AdminAccount" $admin_account "scalar") (serialize-qp "ApiPath" $api_path "scalar") (serialize-qp "ApiKey" $api_key "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "accessToken" $access_token "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "access_token" $access_token_2 "scalar") (serialize-qp "apiKey_shopify" $api_key_shopify "scalar") (serialize-qp "apiPassword" $api_password "scalar") (serialize-qp "accessToken_shopify" $access_token_shopify "scalar") (serialize-qp "apiKey" $api_key_2 "scalar") (serialize-qp "apiUsername" $api_username "scalar") (serialize-qp "EncryptedPassword" $encrypted_password "scalar") (serialize-qp "Login" $login "scalar") (serialize-qp "apiUser_adnsf" $api_user_adnsf "scalar") (serialize-qp "apiPass" $api_pass "scalar") (serialize-qp "accessKey_scelite" $access_key_scelite "scalar") (serialize-qp "apiKey_scelite" $api_key_scelite "scalar") (serialize-qp "apiSecretKey_scelite" $api_secret_key_scelite "scalar") (serialize-qp "privateKey" $private_key "scalar") (serialize-qp "appToken" $app_token "scalar") (serialize-qp "etsy_keystring" $etsy_keystring "scalar") (serialize-qp "etsy_shared_secret" $etsy_shared_secret "scalar") (serialize-qp "tokenSecret" $token_secret "scalar") (serialize-qp "etsy_client_id" $etsy_client_id "scalar") (serialize-qp "etsy_refresh_token" $etsy_refresh_token "scalar") (serialize-qp "ebay_client_id" $ebay_client_id "scalar") (serialize-qp "ebay_client_secret" $ebay_client_secret "scalar") (serialize-qp "ebay_runame" $ebay_runame "scalar") (serialize-qp "ebay_access_token" $ebay_access_token "scalar") (serialize-qp "ebay_refresh_token" $ebay_refresh_token "scalar") (serialize-qp "ebay_environment" $ebay_environment "scalar") (serialize-qp "ebay_site_id" $ebay_site_id "scalar") (serialize-qp "dw_client_id" $dw_client_id "scalar") (serialize-qp "dw_api_pass" $dw_api_pass "scalar") (serialize-qp "demandware_user_name" $demandware_user_name "scalar") (serialize-qp "demandware_user_password" $demandware_user_password "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "seller_id" $seller_id "scalar") (serialize-qp "amazon_secret_key" $amazon_secret_key "scalar") (serialize-qp "amazon_access_key_id" $amazon_access_key_id "scalar") (serialize-qp "marketplaces_ids" $marketplaces_ids "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "hybris_client_id" $hybris_client_id "scalar") (serialize-qp "hybris_client_secret" $hybris_client_secret "scalar") (serialize-qp "hybris_username" $hybris_username "scalar") (serialize-qp "hybris_password" $hybris_password "scalar") (serialize-qp "hybris_websites" $hybris_websites "csv") (serialize-qp "walmart_client_id" $walmart_client_id "scalar") (serialize-qp "walmart_client_secret" $walmart_client_secret "scalar") (serialize-qp "walmart_environment" $walmart_environment "scalar") (serialize-qp "walmart_channel_type" $walmart_channel_type "scalar") (serialize-qp "lightspeed_api_key" $lightspeed_api_key "scalar") (serialize-qp "lightspeed_api_secret" $lightspeed_api_secret "scalar") (serialize-qp "shopware_access_key" $shopware_access_key "scalar") (serialize-qp "shopware_api_key" $shopware_api_key "scalar") (serialize-qp "shopware_api_secret" $shopware_api_secret "scalar") (serialize-qp "commercehq_api_key" $commercehq_api_key "scalar") (serialize-qp "commercehq_api_password" $commercehq_api_password "scalar") (serialize-qp "3dcart_private_key" $3dcart_private_key "scalar") (serialize-qp "3dcart_access_token" $3dcart_access_token "scalar") (serialize-qp "wc_consumer_key" $wc_consumer_key "scalar") (serialize-qp "wc_consumer_secret" $wc_consumer_secret "scalar") (serialize-qp "magento_consumer_key" $magento_consumer_key "scalar") (serialize-qp "magento_consumer_secret" $magento_consumer_secret "scalar") (serialize-qp "magento_access_token" $magento_access_token "scalar") (serialize-qp "magento_token_secret" $magento_token_secret "scalar") (serialize-qp "prestashop_webservice_key" $prestashop_webservice_key "scalar") (serialize-qp "wix_app_id" $wix_app_id "scalar") (serialize-qp "wix_app_secret_key" $wix_app_secret_key "scalar") (serialize-qp "wix_refresh_token" $wix_refresh_token "scalar") (serialize-qp "mercado_libre_app_id" $mercado_libre_app_id "scalar") (serialize-qp "mercado_libre_app_secret_key" $mercado_libre_app_secret_key "scalar") (serialize-qp "mercado_libre_refresh_token" $mercado_libre_refresh_token "scalar") (serialize-qp "zid_client_id" $zid_client_id "scalar") (serialize-qp "zid_client_secret" $zid_client_secret "scalar") (serialize-qp "zid_access_token" $zid_access_token "scalar") (serialize-qp "zid_authorization" $zid_authorization "scalar") (serialize-qp "zid_refresh_token" $zid_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cart_id": $cart_id, "store_url": $store_url, "bridge_url": $bridge_url, "store_root": $store_root, "store_key": $store_key, "shared_secret": $shared_secret, "validate_version": $validate_version, "verify": $verify, "db_tables_prefix": $db_tables_prefix, "ftp_host": $ftp_host, "ftp_user": $ftp_user, "ftp_password": $ftp_password, "ftp_port": $ftp_port, "ftp_store_dir": $ftp_store_dir, "apiKey_3dcart": $api_key_3dcart, "AdminAccount": $admin_account, "ApiPath": $api_path, "ApiKey": $api_key, "client_id": $client_id, "accessToken": $access_token, "context": $context, "access_token": $access_token_2, "apiKey_shopify": $api_key_shopify, "apiPassword": $api_password, "accessToken_shopify": $access_token_shopify, "apiKey": $api_key_2, "apiUsername": $api_username, "EncryptedPassword": $encrypted_password, "Login": $login, "apiUser_adnsf": $api_user_adnsf, "apiPass": $api_pass, "accessKey_scelite": $access_key_scelite, "apiKey_scelite": $api_key_scelite, "apiSecretKey_scelite": $api_secret_key_scelite, "privateKey": $private_key, "appToken": $app_token, "etsy_keystring": $etsy_keystring, "etsy_shared_secret": $etsy_shared_secret, "tokenSecret": $token_secret, "etsy_client_id": $etsy_client_id, "etsy_refresh_token": $etsy_refresh_token, "ebay_client_id": $ebay_client_id, "ebay_client_secret": $ebay_client_secret, "ebay_runame": $ebay_runame, "ebay_access_token": $ebay_access_token, "ebay_refresh_token": $ebay_refresh_token, "ebay_environment": $ebay_environment, "ebay_site_id": $ebay_site_id, "dw_client_id": $dw_client_id, "dw_api_pass": $dw_api_pass, "demandware_user_name": $demandware_user_name, "demandware_user_password": $demandware_user_password, "store_id": $store_id, "seller_id": $seller_id, "amazon_secret_key": $amazon_secret_key, "amazon_access_key_id": $amazon_access_key_id, "marketplaces_ids": $marketplaces_ids, "environment": $environment, "hybris_client_id": $hybris_client_id, "hybris_client_secret": $hybris_client_secret, "hybris_username": $hybris_username, "hybris_password": $hybris_password, "hybris_websites": $hybris_websites, "walmart_client_id": $walmart_client_id, "walmart_client_secret": $walmart_client_secret, "walmart_environment": $walmart_environment, "walmart_channel_type": $walmart_channel_type, "lightspeed_api_key": $lightspeed_api_key, "lightspeed_api_secret": $lightspeed_api_secret, "shopware_access_key": $shopware_access_key, "shopware_api_key": $shopware_api_key, "shopware_api_secret": $shopware_api_secret, "commercehq_api_key": $commercehq_api_key, "commercehq_api_password": $commercehq_api_password, "3dcart_private_key": $3dcart_private_key, "3dcart_access_token": $3dcart_access_token, "wc_consumer_key": $wc_consumer_key, "wc_consumer_secret": $wc_consumer_secret, "magento_consumer_key": $magento_consumer_key, "magento_consumer_secret": $magento_consumer_secret, "magento_access_token": $magento_access_token, "magento_token_secret": $magento_token_secret, "prestashop_webservice_key": $prestashop_webservice_key, "wix_app_id": $wix_app_id, "wix_app_secret_key": $wix_app_secret_key, "wix_refresh_token": $wix_refresh_token, "mercado_libre_app_id": $mercado_libre_app_id, "mercado_libre_app_secret_key": $mercado_libre_app_secret_key, "mercado_libre_refresh_token": $mercado_libre_refresh_token, "zid_client_id": $zid_client_id, "zid_client_secret": $zid_client_secret, "zid_access_token": $zid_access_token, "zid_authorization": $zid_authorization, "zid_refresh_token": $zid_refresh_token} | compact), body: null}
}

# Remove store from API2Cart
#
# DELETE /cart.delete.json
# operationId: CartDelete
export def "cart-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-bridge: oneof<nothing, bool> # Identifies if there is a necessity to delete bridge (default: true)
]: nothing -> record<result: record<store: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_bridge" $delete_bridge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"delete_bridge": $delete_bridge} | compact), body: null}
}

# Disconnect with the store and clear store session data.
#
# GET /cart.disconnect.json
# DEPRECATED
# operationId: CartDisconnect
@deprecated
export def "cart-disconnect-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-bridge: oneof<nothing, bool> # Identifies if there is a necessity to delete bridge (default: false)
]: nothing -> record<result: record<connection: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_bridge" $delete_bridge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.disconnect.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"delete_bridge": $delete_bridge} | compact), body: null}
}

# Create new gift card
#
# POST /cart.giftcard.add.json
# operationId: CartGiftcardAdd
export def "cart-giftcard-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # Defines the gift card amount value.
  --code: string # Gift card code
  --owner-email: string # Gift card owner email
  --recipient-email: string # Gift card recipient email
]: nothing -> record<result: record<code: string, id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "owner_email" $owner_email "scalar") (serialize-qp "recipient_email" $recipient_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.giftcard.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"amount": $amount, "code": $code, "owner_email": $owner_email, "recipient_email": $recipient_email} | compact), body: null}
}

# Get gift cards count.
#
# GET /cart.giftcard.count.json
# operationId: CartGiftcardCount
export def "cart-giftcard-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
]: nothing -> record<result: record<gift_cards_count: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.giftcard.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id} | compact), body: null}
}

# Get gift cards list.
#
# GET /cart.giftcard.list.json
# operationId: CartGiftcardList
export def "cart-giftcard-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,code,name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, gift_card: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.giftcard.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "store_id": $store_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Get cart information
#
# GET /cart.info.json
# operationId: CartInfo
export def "cart-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: store_name,store_url,db_prefix)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
]: nothing -> record<result: record<additional_fields: record, custom_fields: record, db_prefix: string, name: string, shipping_zones: list<record>, stores_info: list<record>, url: string, version: string, warehouses: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id} | compact), body: null}
}

# Get list of supported carts
#
# GET /cart.list.json
# DEPRECATED
# operationId: CartList
@deprecated
export def "cart-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<supported_carts: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.list.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get entity meta data
#
# GET /cart.meta_data.list.json
# operationId: CartMetaDataList
export def "cart-meta-data-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: key,value)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.meta_data.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "entity": $entity, "store_id": $store_id, "key": $key, "count": $count, "page_cursor": $page_cursor, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Set meta data for a specific entity
#
# POST /cart.meta_data.set.json
# operationId: CartMetaDataSet
export def "cart-meta-data-set-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key
  --value: string # Value
  --namespace: string # Metafield namespace
]: nothing -> record<result: record<id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.meta_data.set.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "entity": $entity, "store_id": $store_id, "key": $key, "value": $value, "namespace": $namespace} | compact), body: null}
}

# Unset meta data for a specific entity
#
# DELETE /cart.meta_data.unset.json
# operationId: CartMetaDataUnset
export def "cart-meta-data-unset-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # Entity Id
  --entity: string # Entity (default: product)
  --store-id: string # Store Id
  --key: string # Key
  --id: string # Entity id
]: nothing -> record<result: record<status: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.meta_data.unset.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity_id": $entity_id, "entity": $entity, "store_id": $store_id, "key": $key, "id": $id} | compact), body: null}
}

# Get list of cart methods
#
# GET /cart.methods.json
# operationId: CartMethods
export def "cart-methods-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<method: list<string>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cart.methods.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of installed plugins
#
# GET /cart.plugin.list.json
# operationId: CartPluginList
export def "cart-plugin-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-key: string # Set this parameter if bridge is already uploaded to store
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
]: nothing -> record<result: record<all_plugins: int, plugins: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_key" $store_key "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.plugin.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_key": $store_key, "store_id": $store_id, "start": $start, "count": $count} | compact), body: null}
}

# Add new script to the storefront
#
# POST /cart.script.add.json
# operationId: CartScriptAdd
export def "cart-script-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The user-friendly script name
  --description: string # The user-friendly description
  --html: string # An html string containing exactly one `script` tag.
  --src: string # The URL of the remote script
  --load-method: string # The load method to use for the script
  --scope: string # The page or pages on the online store where the script should be included (default: storefront)
  --store-id: string # Store Id
]: nothing -> record<result: record<script_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "html" $html "scalar") (serialize-qp "src" $src "scalar") (serialize-qp "load_method" $load_method "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.script.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "description": $description, "html": $html, "src": $src, "load_method": $load_method, "scope": $scope, "store_id": $store_id} | compact), body: null}
}

# Remove script from the storefront
#
# DELETE /cart.script.delete.json
# operationId: CartScriptDelete
export def "cart-script-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --store-id: string # Store Id
]: nothing -> record<result: record<deleted: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.script.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "store_id": $store_id} | compact), body: null}
}

# Get scripts installed to the storefront
#
# GET /cart.script.list.json
# operationId: CartScriptList
export def "cart-script-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --script-ids: string # Retrieves only scripts with specific ids
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, scripts: list<record>, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "script_ids" $script_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.script.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "script_ids": $script_ids, "store_id": $store_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Get list of shipping zones
#
# GET /cart.shipping_zones.list.json
# operationId: CartShippingZonesList
export def "cart-shipping-zones-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,enabled)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<result: record<additional_fields: record, code: string, country: string, country_iso2_codes: list<string>, custom_fields: record, id: string, name: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.shipping_zones.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "start": $start, "count": $count, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Check store availability, bridge connection for the downloadable carts, identify DB prefix, validate API accesses for API carts.
#
# GET /cart.validate.json
# operationId: CartValidate
export def "cart-validate-json validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate-version: oneof<nothing, bool> # Specify if api2cart should validate cart version (default: false)
]: nothing -> record<result: record<status: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_version" $validate_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cart.validate.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"validate_version": $validate_version} | compact), body: null}
}

# Add new category in store
#
# POST /category.add.json
# operationId: CategoryAdd
export def "category-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Defines category's name that has to be added
  --parent-id: string # Adds categories specified by parent id
  --stores-ids: string # Create category in the stores that is specified by comma-separated stores' id (default: 0)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
  --sort-order: int # Sort number in the list (default: 0)
  --created-time: string # Entity's date creation
  --modified-time: string # Entity's date modification
  --description: string # Defines category's description
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --seo-url: string # Defines unique category's URL for SEO
]: nothing -> record<result: record<category_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "stores_ids" $stores_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "avail" $avail "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "created_time" $created_time "scalar") (serialize-qp "modified_time" $modified_time "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "meta_title" $meta_title "scalar") (serialize-qp "meta_description" $meta_description "scalar") (serialize-qp "meta_keywords" $meta_keywords "scalar") (serialize-qp "seo_url" $seo_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "parent_id": $parent_id, "stores_ids": $stores_ids, "store_id": $store_id, "lang_id": $lang_id, "avail": $avail, "sort_order": $sort_order, "created_time": $created_time, "modified_time": $modified_time, "description": $description, "meta_title": $meta_title, "meta_description": $meta_description, "meta_keywords": $meta_keywords, "seo_url": $seo_url} | compact), body: null}
}

# Assign category to product
#
# POST /category.assign.json
# operationId: CategoryAssign
export def "category-assign-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines category assign to the product, specified by product id
  --category-id: string # Defines category assign, specified by category id
  --store-id: string # Store Id
]: nothing -> record<result: record, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.assign.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "category_id": $category_id, "store_id": $store_id} | compact), body: null}
}

# Count categories in store.
#
# GET /category.count.json
# operationId: CategoryCount
export def "category-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-id: string # Counts categories specified by parent id
  --store-id: string # Counts category specified by store id
  --lang-id: string # Counts category specified by language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> record<result: record<categories_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"parent_id": $parent_id, "store_id": $store_id, "lang_id": $lang_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "avail": $avail} | compact), body: null}
}

# Delete category in store
#
# DELETE /category.delete.json
# operationId: CategoryDelete
export def "category-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines category removal, specified by category id
]: nothing -> record<result: record<deleted: bool>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Search category in store. "Laptop" is specified here by default.
#
# GET /category.find.json
# operationId: CategoryFind
export def "category-find-json find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
  --lang-id: string # Language id
]: nothing -> record<result: record<category: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "find_value" $find_value "scalar") (serialize-qp "find_where" $find_where "scalar") (serialize-qp "find_params" $find_params "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.find.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"find_value": $find_value, "find_where": $find_where, "find_params": $find_params, "store_id": $store_id, "lang_id": $lang_id} | compact), body: null}
}

# Add image to category
#
# POST /category.image.add.json
# operationId: CategoryImageAdd
export def "category-image-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category id where the image should be added
  --image-name: string # Defines image's name
  --url: string # Defines URL of the image that has to be added
  --label: string # Defines alternative text that has to be attached to the picture
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --type: string@type-completer-1 # Defines image's types that are specified by comma-separated list
  --position: int # Defines image’s position in the list (default: 0)
  --store-id: string # Store Id
]: nothing -> record<result: record<image_path: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "image_name" $image_name "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "mime" $mime "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.image.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category_id": $category_id, "image_name": $image_name, "url": $url, "label": $label, "mime": $mime, "type": $type, "position": $position, "store_id": $store_id} | compact), body: null}
}

# Delete image
#
# DELETE /category.image.delete.json
# operationId: CategoryImageDelete
export def "category-image-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category id where the image should be deleted
  --image-id: string # Define image id
  --store-id: string # Store Id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "image_id" $image_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.image.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category_id": $category_id, "image_id": $image_id, "store_id": $store_id} | compact), body: null}
}

# Get category info about category ID*** or specify other category ID.
#
# GET /category.info.json
# operationId: CategoryInfo
export def "category-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves category's info specified by category id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,parent_id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves category info specified by store id
  --lang-id: string # Retrieves category info specified by language id
]: nothing -> record<result: record<additional_fields: record, avail: bool, created_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, id: string, images: list<record>, keywords: string, meta_description: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, parent_id: string, path: string, seo_url: string, short_description: string, sort_order: int, stores_ids: list<string>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id, "lang_id": $lang_id} | compact), body: null}
}

# Get list of categories from store.
#
# GET /category.list.json
# operationId: CategoryList
export def "category-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --parent-id: string # Retrieves categories specified by parent id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,parent_id,name,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves categories specified by store id
  --lang-id: string # Retrieves categorys specified by language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, categories_count: int, category: list<record>, custom_fields: record>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "page_cursor": $page_cursor, "parent_id": $parent_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id, "lang_id": $lang_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "avail": $avail} | compact), body: null}
}

# Unassign category to product
#
# POST /category.unassign.json
# operationId: CategoryUnassign
export def "category-unassign-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Defines category unassign, specified by category id
  --product-id: string # Defines category unassign to the product, specified by product id
  --store-id: string # Store Id
]: nothing -> record<result: record, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.unassign.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category_id": $category_id, "product_id": $product_id, "store_id": $store_id} | compact), body: null}
}

# Update category in store
#
# PUT /category.update.json
# operationId: CategoryUpdate
export def "category-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines category update specified by category id
  --name: string # Defines new category’s name
  --parent-id: string # Defines new parent category id
  --stores-ids: string # Update category in the stores that is specified by comma-separated stores' id (default: 0)
  --avail: oneof<nothing, bool> # Defines category's visibility status
  --sort-order: int # Sort number in the list
  --modified-time: string # Entity's date modification
  --description: string # Defines new category's description
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --seo-url: string # Defines unique category's URL for SEO
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "stores_ids" $stores_ids "scalar") (serialize-qp "avail" $avail "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "modified_time" $modified_time "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "meta_title" $meta_title "scalar") (serialize-qp "meta_description" $meta_description "scalar") (serialize-qp "meta_keywords" $meta_keywords "scalar") (serialize-qp "seo_url" $seo_url "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/category.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name, "parent_id": $parent_id, "stores_ids": $stores_ids, "avail": $avail, "sort_order": $sort_order, "modified_time": $modified_time, "description": $description, "meta_title": $meta_title, "meta_description": $meta_description, "meta_keywords": $meta_keywords, "seo_url": $seo_url, "lang_id": $lang_id, "store_id": $store_id} | compact), body: null}
}

# Add customer into store.
#
# POST /customer.add.json
# operationId: CustomerAdd
# --address item shape: {address_book_address1?: string, address_book_address2?: string, address_book_city?: string, address_book_company?: string, address_book_country?: string, address_book_default?: bool, address_book_fax?: string, address_book_first_name?: string, address_book_gender?: string, address_book_last_name?: string, address_book_phone?: string, address_book_postcode?: string, address_book_region?: string, address_book_state?: string, address_book_type?: string, address_book_website?: string}
export def "customer-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: list # item shape: {address_book_address1?: string, address_book_address2?: string, address_book_city?: string, address_book_company?: string, address_book_country?: string, address_book_default?: bool, address_book_fax?: string, address_book_first_name?: string, address_book_gender?: string, address_book_last_name?: string, address_book_phone?: string, address_book_postcode?: string, address_book_region?: string, address_book_state?: string, address_book_type?: string, address_book_website?: string}
  --birth-day: string # Defines customer's birthday
  --company: string # Defines customer's company
  --created-time: string # Entity's date creation
  email: string # Defines customer's email
  --fax: string # Defines customer's fax
  first_name: string # Defines customer's first name
  --gender: string # Defines customer's gender
  --group: string # Defines the group where the customer
  --last-login: string # Defines customer's last login time
  last_name: string # Defines customer's last name
  --login: string # Specifies customer's login name
  --modified-time: string # Entity's date modification
  --news-letter-subscription: oneof<nothing, bool> # Defines whether the newsletter subscription is available for the user (default: false)
  --password: string # Defines customer's unique password
  --phone: string # Defines customer's phone number
  --status: string # Defines customer's status (default: enabled)
  --store-id: string # Store Id
  --website: string # Link to customer website
]: any -> record<result: record<customer_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer.add.json")
  let req_body = {"address": $address, "birth_day": $birth_day, "company": $company, "created_time": $created_time, "email": $email, "fax": $fax, "first_name": $first_name, "gender": $gender, "group": $group, "last_login": $last_login, "last_name": $last_name, "login": $login, "modified_time": $modified_time, "news_letter_subscription": $news_letter_subscription, "password": $password, "phone": $phone, "status": $status, "store_id": $store_id, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get attributes for specific customer
#
# GET /customer.attribute.list.json
# operationId: CustomerAttributeList
export def "customer-attribute-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --customer-id: string # Retrieves orders specified by customer id
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, items: list<record>, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.attribute.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "page_cursor": $page_cursor, "customer_id": $customer_id, "store_id": $store_id, "lang_id": $lang_id, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Get number of customers from store.
#
# GET /customer.count.json
# operationId: CustomerCount
export def "customer-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # Customer group_id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --store-id: string # Counts customer specified by store id
  --customer-list-id: string # The numeric ID of the customer list in Demandware.
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> record<result: record<customers_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "customer_list_id" $customer_list_id "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"group_id": $group_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "store_id": $store_id, "customer_list_id": $customer_list_id, "avail": $avail} | compact), body: null}
}

# Find customers in store.
#
# GET /customer.find.json
# operationId: CustomerFind
export def "customer-find-json find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: email)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
]: nothing -> record<result: record<email: string, first_name: string, id: string, last_name: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "find_value" $find_value "scalar") (serialize-qp "find_where" $find_where "scalar") (serialize-qp "find_params" $find_params "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.find.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"find_value": $find_value, "find_where": $find_where, "find_params": $find_params, "store_id": $store_id} | compact), body: null}
}

# Create customer group.
#
# POST /customer.group.add.json
# operationId: CustomerGroupAdd
export def "customer-group-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Customer group name
  --store-id: string # Store Id
  --stores-ids: string # Assign customer group to the stores that is specified by comma-separated stores' id
]: nothing -> record<result: record, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "stores_ids" $stores_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.group.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "store_id": $store_id, "stores_ids": $stores_ids} | compact), body: null}
}

# Get list of customers groups.
#
# GET /customer.group.list.json
# operationId: CustomerGroupList
export def "customer-group-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --store-id: string # Store Id
  --lang-id: string # Language id
  --group-ids: string # Groups that will be assigned to a customer
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,additional_fields)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, group: list<record>, group_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.group.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "store_id": $store_id, "lang_id": $lang_id, "group_ids": $group_ids, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Get customers' details from store.
#
# GET /customer.info.json
# operationId: CustomerInfo
export def "customer-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves customer's info specified by customer id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,email,first_name,last_name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves customer info specified by store id
]: nothing -> record<result: record<additional_fields: record, address_book: list<record>, birth_day: record<additional_fields: record, custom_fields: record, format: string, value: string>, company: string, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, email: string, fax: string, first_name: string, gender: string, group: list<record>, id: string, ip_address: string, last_login: record<additional_fields: record, custom_fields: record, format: string, value: string>, last_name: string, last_order_id: string, login: string, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, news_letter_subscription: bool, orders_count: int, phone: string, status: string, stores_ids: list<string>, website: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id} | compact), body: null}
}

# Get list of customers from store.
#
# GET /customer.list.json
# operationId: CustomerList
export def "customer-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,email,first_name,last_name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --group-id: string # Customer group_id
  --store-id: string # Retrieves customers specified by store id
  --customer-list-id: string # The numeric ID of the customer list in Demandware.
  --avail: oneof<nothing, bool> # Defines category's visibility status (default: true)
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, customer: list<record>, customers_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "customer_list_id" $customer_list_id "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "group_id": $group_id, "store_id": $store_id, "customer_list_id": $customer_list_id, "avail": $avail} | compact), body: null}
}

# Update information of customer in store.
#
# PUT /customer.update.json
# operationId: CustomerUpdate
export def "customer-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --group-id: string # Customer group_id
  --group-ids: string # Groups that will be assigned to a customer
  --first-name: string # Defines customer's first name
  --last-name: string # Defines customer's last name
  --news-letter-subscription: oneof<nothing, bool> # Defines whether the newsletter subscription is available for the user
  --tags: string # Customer tags
  --address-book-id-x: string # The ID of the address.
  --address-book-first-name-x: string # Specifies customer's first name in the address book
  --address-book-last-name-x: string # Specifies customer's last name in the address book
  --address-book-company-x: string # Specifies customer's company name in the address book
  --address-book-phone-x: string # Specifies customer's phone number in the address book
  --address-book-address1-x: string # Specifies customer's first address in the address book
  --address-book-address2-x: string # Specifies customer's second address in the address book
  --address-book-city-x: string # Specifies customer's city in the address book
  --address-book-country-x: string # ISO code or name of country
  --address-book-state-x: string # ISO code or name of state.
  --address-book-postcode-x: string # Specifies customer's postcode
]: nothing -> record<result: record<updated: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "news_letter_subscription" $news_letter_subscription "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "address_book_id_{x}" $address_book_id_x "scalar") (serialize-qp "address_book_first_name_{x}" $address_book_first_name_x "scalar") (serialize-qp "address_book_last_name_{x}" $address_book_last_name_x "scalar") (serialize-qp "address_book_company_{x}" $address_book_company_x "scalar") (serialize-qp "address_book_phone_{x}" $address_book_phone_x "scalar") (serialize-qp "address_book_address1_{x}" $address_book_address1_x "scalar") (serialize-qp "address_book_address2_{x}" $address_book_address2_x "scalar") (serialize-qp "address_book_city_{x}" $address_book_city_x "scalar") (serialize-qp "address_book_country_{x}" $address_book_country_x "scalar") (serialize-qp "address_book_state_{x}" $address_book_state_x "scalar") (serialize-qp "address_book_postcode_{x}" $address_book_postcode_x "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "group_id": $group_id, "group_ids": $group_ids, "first_name": $first_name, "last_name": $last_name, "news_letter_subscription": $news_letter_subscription, "tags": $tags, "address_book_id_{x}": $address_book_id_x, "address_book_first_name_{x}": $address_book_first_name_x, "address_book_last_name_{x}": $address_book_last_name_x, "address_book_company_{x}": $address_book_company_x, "address_book_phone_{x}": $address_book_phone_x, "address_book_address1_{x}": $address_book_address1_x, "address_book_address2_{x}": $address_book_address2_x, "address_book_city_{x}": $address_book_city_x, "address_book_country_{x}": $address_book_country_x, "address_book_state_{x}": $address_book_state_x, "address_book_postcode_{x}": $address_book_postcode_x} | compact), body: null}
}

# Get list of orders that were left by customers before completing the order.
#
# GET /order.abandoned.list.json
# operationId: OrderAbandonedList
export def "order-abandoned-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --skip-empty-email: oneof<nothing, bool> # Filter empty emails (default: false)
  --store-id: string # Store Id
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: customer,totals,items)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "customer_email" $customer_email "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "skip_empty_email" $skip_empty_email "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.abandoned.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customer_id": $customer_id, "customer_email": $customer_email, "created_to": $created_to, "created_from": $created_from, "modified_to": $modified_to, "modified_from": $modified_from, "skip_empty_email": $skip_empty_email, "store_id": $store_id, "page_cursor": $page_cursor, "count": $count, "start": $start, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Add a new order to the cart.
#
# POST /order.add.json
# operationId: OrderAdd
# --note_attributes item shape: {name?: string, value?: string}
# --order_item item shape: {order_item_allow_refund_items_separately?: bool, order_item_allow_ship_items_separately?: bool, order_item_id: string, order_item_model?: string, order_item_name: string, order_item_option?: list, order_item_parent?: int, order_item_parent_option_name?: string, order_item_price: float, order_item_price_includes_tax?: bool, order_item_property?: list, order_item_quantity: int, order_item_tax?: float, order_item_variant_id?: string, order_item_weight?: float}
export def "order-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-comment: string # Specifies admin's order comment
  --admin-private-comment: string # Specifies private admin's order comment
  bill_address_1: string # Specifies first billing address
  --bill-address-2: string # Specifies second billing address
  bill_city: string # Specifies billing city
  --bill-company: string # Specifies billing company
  bill_country: string # Specifies billing country code
  --bill-fax: string # Specifies billing fax
  bill_first_name: string # Specifies billing first name
  bill_last_name: string # Specifies billing last name
  --bill-phone: string # Specifies billing phone
  bill_postcode: string # Specifies billing postcode
  bill_state: string # Specifies billing state code
  --channel-id: string # Channel ID
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --comment: string # Specifies order comment
  --coupon-discount: float # Specifies order's coupon discount
  --coupons: list<string> # Coupons that will be applied to order
  --create-invoice: oneof<nothing, bool> # Defines whether the invoice is created automatically along with the order (default: false)
  --currency: string # Currency code of order
  --customer-birthday: string # Specifies customer’s birthday
  customer_email: string # Defines the customer specified by email for whom order has to be created
  --customer-fax: string # Specifies customer’s fax
  --customer-first-name: string # Specifies customer's first name
  --customer-last-name: string # Specifies customer’s last name
  --customer-phone: string # Specifies customer’s phone
  --date: string # Specifies an order creation date in format Y-m-d H:i:s
  --date-finished: string # Specifies order's finished date
  --date-modified: string # Specifies order's modification date
  --discount: float # Specifies order's discount
  --external-source: string # Identifying the system used to generate the order
  --financial-status: string # Create order with financial status
  --fulfillment-status: string # Create order with fulfillment status
  --gift-certificate-discount: float # Discounts for order with gift certificates
  --id: string # Defines order's id
  --inventory-behaviour: string # The behaviour to use when updating inventory.Values description:bypass = Do not claim inventory decrement_ignoring_policy = Ignore the product's inventory policy and claim amountsdecrement_obeying_policy = Obey the product's inventory policy. (default: bypass)
  --note-attributes: list # Defines note attributes — item shape: {name?: string, value?: string}
  --order-id: string # Defines the order id if it is supported by the cart
  order_item: list # item shape: {order_item_allow_refund_items_separately?: bool, order_item_allow_ship_items_separately?: bool, order_item_id: string, order_item_model?: string, order_item_name: string, order_item_option?: list, order_item_parent?: int, order_item_parent_option_name?: string, order_item_price: float, order_item_price_includes_tax?: bool, order_item_property?: list, order_item_quantity: int, order_item_tax?: float, order_item_variant_id?: string, order_item_weight?: float}
  --order-payment-method: string # Defines order payment method.Setting order_payment_method on Shopify will also change financial_status field value to 'paid'
  --order-shipping-method: string # Defines order shipping method
  order_status: string # Defines order status.
  --prices-inc-tax: oneof<nothing, bool> # Indicates whether prices and subtotal includes tax. (default: false)
  --send-admin-notifications: oneof<nothing, bool> # Notify admin when new order was created. (default: false)
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after order was created (default: false)
  --shipp-address-1: string # Specifies first shipping address
  --shipp-address-2: string # Specifies second address line of a shipping street address
  --shipp-city: string # Specifies shipping city
  --shipp-company: string # Specifies shipping company
  --shipp-country: string # Specifies shipping country code
  --shipp-fax: string # Specifies shipping fax
  --shipp-first-name: string # Specifies shipping first name
  --shipp-last-name: string # Specifies shipping last name
  --shipp-phone: string # Specifies shipping phone
  --shipp-postcode: string # Specifies shipping postcode
  --shipp-state: string # Specifies shipping state code
  --shipping-price: float # Specifies order's shipping price (default: 0)
  --shipping-tax: float # Specifies order's shipping price tax
  --store-id: string # Defines store id where the order should be assigned
  --subtotal-price: float # Total price of all ordered products multiplied by their number, excluding tax, shipping price and discounts
  --tags: string # Order tags
  --tax-price: float # The value of tax cost for order (default: 0)
  --total-paid: float # Defines total paid amount for the order
  --total-price: float # Defines order's total price
  --total-weight: int # Defines the sum of all line item weights in grams for the order
  --transaction-id: string # Payment transaction id
]: any -> record<result: record<order_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.add.json")
  let req_body = {"admin_comment": $admin_comment, "admin_private_comment": $admin_private_comment, "bill_address_1": $bill_address_1, "bill_address_2": $bill_address_2, "bill_city": $bill_city, "bill_company": $bill_company, "bill_country": $bill_country, "bill_fax": $bill_fax, "bill_first_name": $bill_first_name, "bill_last_name": $bill_last_name, "bill_phone": $bill_phone, "bill_postcode": $bill_postcode, "bill_state": $bill_state, "channel_id": $channel_id, "clear_cache": $clear_cache, "comment": $comment, "coupon_discount": $coupon_discount, "coupons": $coupons, "create_invoice": $create_invoice, "currency": $currency, "customer_birthday": $customer_birthday, "customer_email": $customer_email, "customer_fax": $customer_fax, "customer_first_name": $customer_first_name, "customer_last_name": $customer_last_name, "customer_phone": $customer_phone, "date": $date, "date_finished": $date_finished, "date_modified": $date_modified, "discount": $discount, "external_source": $external_source, "financial_status": $financial_status, "fulfillment_status": $fulfillment_status, "gift_certificate_discount": $gift_certificate_discount, "id": $id, "inventory_behaviour": $inventory_behaviour, "note_attributes": $note_attributes, "order_id": $order_id, "order_item": $order_item, "order_payment_method": $order_payment_method, "order_shipping_method": $order_shipping_method, "order_status": $order_status, "prices_inc_tax": $prices_inc_tax, "send_admin_notifications": $send_admin_notifications, "send_notifications": $send_notifications, "shipp_address_1": $shipp_address_1, "shipp_address_2": $shipp_address_2, "shipp_city": $shipp_city, "shipp_company": $shipp_company, "shipp_country": $shipp_country, "shipp_fax": $shipp_fax, "shipp_first_name": $shipp_first_name, "shipp_last_name": $shipp_last_name, "shipp_phone": $shipp_phone, "shipp_postcode": $shipp_postcode, "shipp_state": $shipp_state, "shipping_price": $shipping_price, "shipping_tax": $shipping_tax, "store_id": $store_id, "subtotal_price": $subtotal_price, "tags": $tags, "tax_price": $tax_price, "total_paid": $total_paid, "total_price": $total_price, "total_weight": $total_weight, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Count orders in store
#
# GET /order.count.json
# operationId: OrderCount
export def "order-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Counts orders quantity specified by customer id
  --customer-email: string # Counts orders quantity specified by customer email
  --order-status: string # Counts orders quantity specified by order status
  --order-status-ids: list<string> # Retrieves orders specified by order statuses
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --store-id: string # Counts orders quantity specified by store id
  --ids: string # Counts orders specified by ids
  --order-ids: string # Counts orders specified by order ids
  --ebay-order-status: string # Counts orders quantity specified by order status
  --financial-status: string # Counts orders quantity specified by financial status
  --fulfillment-status: string # Create order with fulfillment status
  --shipping-method: string # Retrieve entities according to shipping method
  --delivery-method: string # Retrieves order with delivery method
  --ship-node-type: string # Retrieves order with ship node type
]: nothing -> record<result: record<orders_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "customer_email" $customer_email "scalar") (serialize-qp "order_status" $order_status "scalar") (serialize-qp "order_status_ids" $order_status_ids "csv") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "order_ids" $order_ids "scalar") (serialize-qp "ebay_order_status" $ebay_order_status "scalar") (serialize-qp "financial_status" $financial_status "scalar") (serialize-qp "fulfillment_status" $fulfillment_status "scalar") (serialize-qp "shipping_method" $shipping_method "scalar") (serialize-qp "delivery_method" $delivery_method "scalar") (serialize-qp "ship_node_type" $ship_node_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customer_id": $customer_id, "customer_email": $customer_email, "order_status": $order_status, "order_status_ids": $order_status_ids, "created_to": $created_to, "created_from": $created_from, "modified_to": $modified_to, "modified_from": $modified_from, "store_id": $store_id, "ids": $ids, "order_ids": $order_ids, "ebay_order_status": $ebay_order_status, "financial_status": $financial_status, "fulfillment_status": $fulfillment_status, "shipping_method": $shipping_method, "delivery_method": $delivery_method, "ship_node_type": $ship_node_type} | compact), body: null}
}

# Retrieve list of financial statuses
#
# GET /order.financial_status.list.json
# operationId: OrderFinancialStatusList
export def "order-financial-status-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<order_financial_statuses: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.financial_status.list.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method is deprecated and won't be supported in the future. Please use "order.list" instead.
#
# GET /order.find.json
# DEPRECATED
# operationId: OrderFind
@deprecated
export def "order-find-json find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --order-status: string # Retrieves orders specified by order status
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --financial-status: string # Retrieves orders specified by financial status
]: nothing -> record<result: record<order: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "customer_email" $customer_email "scalar") (serialize-qp "order_status" $order_status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "financial_status" $financial_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.find.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customer_id": $customer_id, "customer_email": $customer_email, "order_status": $order_status, "start": $start, "count": $count, "params": $params, "exclude": $exclude, "created_to": $created_to, "created_from": $created_from, "modified_to": $modified_to, "modified_from": $modified_from, "financial_status": $financial_status} | compact), body: null}
}

# Retrieve list of fulfillment statuses
#
# GET /order.fulfillment_status.list.json
# operationId: OrderFulfillmentStatusList
export def "order-fulfillment-status-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<order_fulfillment_statuses: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.fulfillment_status.list.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Info about a specific order by ID
#
# GET /order.info.json
# operationId: OrderInfo
export def "order-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Retrieves order’s info specified by order id
  --id: string # Retrieves order info specified by id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Defines store id where the order should be found
  --enable-cache: oneof<nothing, bool> # If the value is 'true' and order exist in our cache, we will return order.info response from cache (default: false)
]: nothing -> record<result: record<additional_fields: record, basket_id: string, billing_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, bundles: list<record>, channel_id: string, comment: string, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, currency: record<additional_fields: record, avail: bool, custom_fields: record, default: bool, id: string, iso3: string, name: string, rate: float, symbol_left: string, symbol_right: string>, custom_fields: record, customer: record<additional_fields: record, custom_fields: record, email: string, first_name: string, id: string, last_name: string, phone: string>, discounts: list<record>, finished_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, gift_message: string, id: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, order_details_url: string, order_id: string, order_products: list<record>, payment_method: record<additional_fields: record, custom_fields: record, name: string>, refunds: list<record>, shipping_address: record<additional_fields: record, address1: string, address2: string, city: string, company: string, country: record, custom_fields: record, default: bool, fax: string, first_name: string, gender: string, id: string, last_name: string, phone: string, postcode: string, region: string, state: record, type: string, website: string>, shipping_method: record<additional_fields: record, custom_fields: record, name: string>, shipping_methods: list<record>, status: record<additional_fields: record, custom_fields: record, history: list, id: string, name: string, refund_info: record>, store_id: string, total: record<additional_fields: record, custom_fields: record, shipping_ex_tax: float, subtotal_ex_tax: float, total: float, total_discount: float, total_paid: float, total_tax: float, wrapping_ex_tax: float>, totals: record<additional_fields: record, custom_fields: record, discount: float, shipping: float, subtotal: float, tax: float, total: float>, warehouses_ids: list<string>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_id" $order_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "enable_cache" $enable_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"order_id": $order_id, "id": $id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id, "enable_cache": $enable_cache} | compact), body: null}
}

# Get list of orders from store.
#
# GET /order.list.json
# operationId: OrderList
export def "order-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: string # Retrieves orders specified by customer id
  --customer-email: string # Retrieves orders specified by customer email
  --phone: string # Filter orders by customer's phone number
  --order-status: string # Retrieves orders specified by order status
  --order-status-ids: list<string> # Retrieves orders specified by order statuses
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --page-cursor: string # Used to retrieve orders via cursor-based pagination (it can't be used with any other filtering parameter)
  --sort-by: string # Set field to sort by (default: order_id)
  --sort-direction: string # Set sorting direction (default: asc)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: order_id,customer,totals,address,items,bundles,status)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-to: string # Retrieve entities to their creation date
  --created-from: string # Retrieve entities from their creation date
  --modified-to: string # Retrieve entities to their modification date
  --modified-from: string # Retrieve entities from their modification date
  --store-id: string # Store Id
  --ids: string # Retrieves orders specified by ids
  --order-ids: string # Retrieves orders specified by order ids
  --ebay-order-status: string # Retrieves orders specified by order status
  --basket-id: string # Retrieves order’s info specified by basket id.
  --financial-status: string # Retrieves orders specified by financial status
  --fulfillment-status: string # Create order with fulfillment status
  --shipping-method: string # Retrieve entities according to shipping method
  --skip-order-ids: string # Skipped orders by ids
  --since-id: int # Retrieve entities starting from the specified id.
  --is-deleted: oneof<nothing, bool> # Filter deleted orders
  --shipping-country-iso3: string # Retrieve entities according to shipping country
  --enable-cache: oneof<nothing, bool> # If the value is 'true', we will cache orders for a 15 minutes in order to increase speed and reduce requests throttling for some methods and shoping platforms (for example order.shipment.add) (default: false)
  --delivery-method: string # Retrieves order with delivery method
  --ship-node-type: string # Retrieves order with ship node type
  --currency-id: string # Currency Id
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, order: list<record>, orders_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "customer_email" $customer_email "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "order_status" $order_status "scalar") (serialize-qp "order_status_ids" $order_status_ids "csv") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "order_ids" $order_ids "scalar") (serialize-qp "ebay_order_status" $ebay_order_status "scalar") (serialize-qp "basket_id" $basket_id "scalar") (serialize-qp "financial_status" $financial_status "scalar") (serialize-qp "fulfillment_status" $fulfillment_status "scalar") (serialize-qp "shipping_method" $shipping_method "scalar") (serialize-qp "skip_order_ids" $skip_order_ids "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "is_deleted" $is_deleted "scalar") (serialize-qp "shipping_country_iso3" $shipping_country_iso3 "scalar") (serialize-qp "enable_cache" $enable_cache "scalar") (serialize-qp "delivery_method" $delivery_method "scalar") (serialize-qp "ship_node_type" $ship_node_type "scalar") (serialize-qp "currency_id" $currency_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customer_id": $customer_id, "customer_email": $customer_email, "phone": $phone, "order_status": $order_status, "order_status_ids": $order_status_ids, "start": $start, "count": $count, "page_cursor": $page_cursor, "sort_by": $sort_by, "sort_direction": $sort_direction, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "created_to": $created_to, "created_from": $created_from, "modified_to": $modified_to, "modified_from": $modified_from, "store_id": $store_id, "ids": $ids, "order_ids": $order_ids, "ebay_order_status": $ebay_order_status, "basket_id": $basket_id, "financial_status": $financial_status, "fulfillment_status": $fulfillment_status, "shipping_method": $shipping_method, "skip_order_ids": $skip_order_ids, "since_id": $since_id, "is_deleted": $is_deleted, "shipping_country_iso3": $shipping_country_iso3, "enable_cache": $enable_cache, "delivery_method": $delivery_method, "ship_node_type": $ship_node_type, "currency_id": $currency_id} | compact), body: null}
}

# Retrieve list of order preestimated shipping methods
#
# POST /order.preestimate_shipping.list.json
# operationId: OrderPreestimateShippingList
# --order_item item shape: {order_item_id: string, order_item_model?: string, order_item_option?: list, order_item_quantity: int, order_item_variant_id?: string, order_item_weight?: float}
export def "order-preestimate-shipping-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-email: string # Retrieves orders specified by customer email
  --customer-id: string # Retrieves orders specified by customer id
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  order_item: list # item shape: {order_item_id: string, order_item_model?: string, order_item_option?: list, order_item_quantity: int, order_item_variant_id?: string, order_item_weight?: float}
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --shipp-address-1: string # Specifies first shipping address
  --shipp-city: string # Specifies shipping city
  shipp_country: string # Specifies shipping country code
  --shipp-postcode: string # Specifies shipping postcode
  --shipp-state: string # Specifies shipping state code
  --store-id: string # Store Id
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
]: any -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, preestimate_shippings: list<record>, preestimate_shippings_count: int>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.preestimate_shipping.list.json")
  let req_body = {"customer_email": $customer_email, "customer_id": $customer_id, "exclude": $exclude, "order_item": $order_item, "params": $params, "shipp_address_1": $shipp_address_1, "shipp_city": $shipp_city, "shipp_country": $shipp_country, "shipp_postcode": $shipp_postcode, "shipp_state": $shipp_state, "store_id": $store_id, "warehouse_id": $warehouse_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add a refund to the order.
#
# POST /order.refund.add.json
# operationId: OrderRefundAdd
# --items item shape: {order_product_id?: string, price?: float, quantity?: int}
export def "order-refund-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Specifies an order creation date in format Y-m-d H:i:s
  --fee-price: float # Specifies refund's fee price
  --is-online: oneof<nothing, bool> # Indicates whether refund type is online (default: false)
  --item-restock: oneof<nothing, bool> # Boolean, whether or not to add the line items back to the store inventory. (default: false)
  --items: list # Defines items in the order that will be refunded — item shape: {order_product_id?: string, price?: float, quantity?: int}
  --message: string # Refund reason, or some else message which assigned to refund.
  --order-id: string # Defines the order for which the refund will be created.
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after refund was created (default: false)
  --shipping-price: float # Defines refund shipping amount.
  --total-price: float # Defines order refund amount.
]: any -> record<result: record<refund_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.refund.add.json")
  let req_body = {"date": $date, "fee_price": $fee_price, "is_online": $is_online, "item_restock": $item_restock, "items": $items, "message": $message, "order_id": $order_id, "send_notifications": $send_notifications, "shipping_price": $shipping_price, "total_price": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add a shipment to the order.
#
# POST /order.shipment.add.json
# operationId: OrderShipmentAdd
# --items item shape: {order_product_id?: string, quantity?: float}
# --tracking_numbers item shape: {carrier_id?: string, tracking_number?: string}
export def "order-shipment-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adjust-stock: oneof<nothing, bool> # This parameter is used for adjust stock. (default: false)
  --enable-cache: oneof<nothing, bool> # If the value is 'true' and order exist in our cache, we will use order.info from cache to prepare shipment items. (default: false)
  --is-shipped: oneof<nothing, bool> # Defines shipment's status (default: true)
  --items: list # Defines items in the order that will be shipped — item shape: {order_product_id?: string, quantity?: float}
  --order-id: string # Defines the order for which the shipment will be created
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after shipment was created (default: false)
  --shipment-provider: string # Defines company name that provide tracking of shipment
  --shipping-method: string # Define shipping method
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  --tracking-numbers: list # Defines shipment's tracking numbers that have to be added How set tracking numbers to appropriate carrier:tracking_numbers[]=a2c.demo1,a2c.demo2 - set default carriertracking_numbers[carrier_id]=a2c.demo - set appropriate carrierTo get the list of carriers IDs that are available in your store, use the cart.info method — item shape: {carrier_id?: string, tracking_number?: string}
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
]: any -> record<result: record<shipment_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.shipment.add.json")
  let req_body = {"adjust_stock": $adjust_stock, "enable_cache": $enable_cache, "is_shipped": $is_shipped, "items": $items, "order_id": $order_id, "send_notifications": $send_notifications, "shipment_provider": $shipment_provider, "shipping_method": $shipping_method, "store_id": $store_id, "tracking_link": $tracking_link, "tracking_numbers": $tracking_numbers, "warehouse_id": $warehouse_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete order's shipment.
#
# DELETE /order.shipment.delete.json
# operationId: OrderShipmentDelete
export def "order-shipment-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment-id: string # Shipment id indicates the number of delivery
  --order-id: string # Defines the order for which the shipment will be deleted
  --store-id: string # Store Id
]: nothing -> record<result: record<status: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipment_id" $shipment_id "scalar") (serialize-qp "order_id" $order_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.shipment.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipment_id": $shipment_id, "order_id": $order_id, "store_id": $store_id} | compact), body: null}
}

# Get information of shipment.
#
# GET /order.shipment.info.json
# operationId: OrderShipmentInfo
export def "order-shipment-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Entity id
  --order-id: string # Defines the order id
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,items,tracking_numbers)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "order_id" $order_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.shipment.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "order_id": $order_id, "start": $start, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id} | compact), body: null}
}

# Get list of shipments by orders.
#
# GET /order.shipment.list.json
# operationId: OrderShipmentList
export def "order-shipment-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Retrieves shipments specified by order id
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,items,tracking_numbers)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --store-id: string # Store Id
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, shipment: list<record>, shipment_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_id" $order_id "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.shipment.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"order_id": $order_id, "page_cursor": $page_cursor, "start": $start, "count": $count, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "store_id": $store_id} | compact), body: null}
}

# Add order shipment's tracking info.
#
# POST /order.shipment.tracking.add.json
# operationId: OrderShipmentTrackingAdd
export def "order-shipment-tracking-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # Defines tracking carrier id
  --order-id: string # Defines the order id
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after tracking was created (default: false)
  shipment_id: string # Shipment id indicates the number of delivery
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  tracking_number: string # Defines tracking number
  --tracking-provider: string # Defines name of the company which provides shipment tracking
]: any -> record<result: record<tracking_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.shipment.tracking.add.json")
  let req_body = {"carrier_id": $carrier_id, "order_id": $order_id, "send_notifications": $send_notifications, "shipment_id": $shipment_id, "store_id": $store_id, "tracking_link": $tracking_link, "tracking_number": $tracking_number, "tracking_provider": $tracking_provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update order's shipment information.
#
# PUT /order.shipment.update.json
# operationId: OrderShipmentUpdate
# --tracking_numbers item shape: {carrier_id?: string, tracking_number?: string}
export def "order-shipment-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-shipped: oneof<nothing, bool> # Defines shipment's status (default: true)
  --order-id: string # Defines the order that will be updated
  --replace: oneof<nothing, bool> # Allows rewrite tracking numbers (default: true)
  shipment_id: string # Shipment id indicates the number of delivery
  --store-id: string # Store Id
  --tracking-link: string # Defines custom tracking link
  --tracking-numbers: list # Defines shipment's tracking numbers that have to be added How set tracking numbers to appropriate carrier:tracking_numbers[]=a2c.demo1,a2c.demo2 - set default carriertracking_numbers[carrier_id]=a2c.demo - set appropriate carrierTo get the list of carriers IDs that are available in your store, use the cart.info method — item shape: {carrier_id?: string, tracking_number?: string}
]: any -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order.shipment.update.json")
  let req_body = {"is_shipped": $is_shipped, "order_id": $order_id, "replace": $replace, "shipment_id": $shipment_id, "store_id": $store_id, "tracking_link": $tracking_link, "tracking_numbers": $tracking_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve list of statuses
#
# GET /order.status.list.json
# operationId: OrderStatusList
export def "order-status-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Store Id
]: nothing -> record<result: record<cart_order_statuses: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.status.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id} | compact), body: null}
}

# Retrieve list of order transaction
#
# GET /order.transaction.list.json
# operationId: OrderTransactionList
export def "order-transaction-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --order-ids: string # Retrieves order transactions specified by order ids
  --store-id: string # Store Id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,order_id,amount,description)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, transactions: list<record>, transactions_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "order_ids" $order_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "page_cursor" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.transaction.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "order_ids": $order_ids, "store_id": $store_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "page_cursor": $page_cursor} | compact), body: null}
}

# Update existing order.
#
# PUT /order.update.json
# operationId: OrderUpdate
export def "order-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Defines the orders specified by order id
  --store-id: string # Defines store id where the order should be found
  --order-status: string # Defines new order's status
  --comment: string # Specifies order comment
  --admin-comment: string # Specifies admin's order comment
  --admin-private-comment: string # Specifies private admin's order comment
  --date-modified: string # Specifies order's modification date
  --date-finished: string # Specifies order's finished date
  --financial-status: string # Update order financial status to specified
  --fulfillment-status: string # Create order with fulfillment status
  --order-payment-method: string # Defines order payment method.Setting order_payment_method on Shopify will also change financial_status field value to 'paid'
  --send-notifications: oneof<nothing, bool> # Send notifications to customer after order was created (default: false)
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_id" $order_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "order_status" $order_status "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "admin_comment" $admin_comment "scalar") (serialize-qp "admin_private_comment" $admin_private_comment "scalar") (serialize-qp "date_modified" $date_modified "scalar") (serialize-qp "date_finished" $date_finished "scalar") (serialize-qp "financial_status" $financial_status "scalar") (serialize-qp "fulfillment_status" $fulfillment_status "scalar") (serialize-qp "order_payment_method" $order_payment_method "scalar") (serialize-qp "send_notifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"order_id": $order_id, "store_id": $store_id, "order_status": $order_status, "comment": $comment, "admin_comment": $admin_comment, "admin_private_comment": $admin_private_comment, "date_modified": $date_modified, "date_finished": $date_finished, "financial_status": $financial_status, "fulfillment_status": $fulfillment_status, "order_payment_method": $order_payment_method, "send_notifications": $send_notifications} | compact), body: null}
}

# Add new product to store.
#
# POST /product.add.json
# operationId: ProductAdd
# --files item shape: {name: string, url: string}
# --group_prices item shape: {group_id?: string, price?: float}
# --seller_profiles shape: {payment_profile_id?: string, return_profile_id?: string, shipping_profile_id?: string}
# --shipping_details item shape: {shipping_cost?: float, shipping_service?: string, shipping_type?: string}
# --tier_prices item shape: {price?: float, quantity?: float}
export def "product-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-name: string # Defines product’s attribute name separated with a comma in Magento
  --attribute-set-name: string # Defines product’s attribute set name in Magento (default: Default)
  --avail-from: string # Allows to schedule a time in the future that the item becomes available. The value should be greater than the current date and time.
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible products for sale (default: true)
  --available-for-view: oneof<nothing, bool> # Specifies the set of visible/invisible products for users (default: true)
  --backorder-status: string # Set backorder status
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --best-offer: list<string> # The price at which Best Offers are automatically accepted.Param structure:best_offer[minimum_offer_price] = decimalbest_offer[auto_accept_price] = decimal
  --brand-name: string # Retrieves brands specified by brand name
  --categories-ids: string # Defines product add that is specified by comma-separated categories id
  --category-id: string # Defines product add that is specified by category id
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --condition: string # The human-readable label for the condition (e.g., "New").
  --cost-price: float # Defines new product's cost price
  --country-of-origin: string # The country where the inventory item was made
  --created-at: string # Defines the date of entity creation
  description: string # Defines product's description that has to be added
  --downloadable: oneof<nothing, bool> # Defines whether the product is downloadable (default: false)
  --ean: string # European Article Number. An EAN is a unique 8 or 13-digit identifier that many industries (such as book publishers) use to identify products.
  --files: list # File Url — item shape: {name: string, url: string}
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, price?: float}
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --height: float # Defines product's height
  --image-name: string # Defines image's name
  --image-url: string # Image Url
  --isbn: string # International Standard Book Number. An ISBN is a unique identifier for books.
  --lang-id: string # Language id
  --length: float # Defines product's length
  --listing-duration: string # Describes the number of days the seller wants the listing to be active. Look at cart.info method response for allowed values.
  --listing-type: string # Indicates the selling format of the marketplace listing. (default: FixedPrice)
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product
  --manufacturer: string # Defines product's manufacturer
  --marketplace-item-properties: string # String containing the JSON representation of the supplied data (default: false)
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-title: string # Defines unique meta title for each entity
  model: string # Defines product's model that has to be added
  --mpn: string # Manufacturer Part Number. A MPN is an identifier of a particular part design or material used.
  name: string # Defines product's name that has to be added
  --old-price: float # Defines product's old price
  --ordered-count: int # Defines how many times the product was ordered (default: 0)
  --package-details: list<string> # If the seller is subscribed to "Business Policies", use the seller_profiles instead of the shipping_details, payment_methods and return_accepted params.Param structure:package_details[measure_unit] = string Allowed measure_unit values: [English or Metric] Default: Metricpackage_details[weigh_unit] = string Allowed weigh_unit values: [kg, g, lbs, oz]package_details[package_depth] = decimalpackage_details[package_length] = decimalpackage_details[package_width] = decimalpackage_details[weight_major] = decimalpackage_details[weight_minor] = decimalpackage_details[shipping_package] = string See cart.info method, param `eBay_shipping_package_details`
  --payment-methods: list<string> # Identifies the payment method (such as PayPal) that the seller will accept when the buyer pays for the item. Look at cart.info method response for allowed values.Param structure:payment_methods[0] = stringpayment_methods[1] = string
  --paypal-email: string # Valid PayPal email address for the PayPal account that the seller will use if they offer PayPal as a payment method for the listing.
  price: float # Defines product's price that has to be added
  --product-class: string # A categorization for the product
  --quantity: float # Defines product's quantity that has to be added (default: 0)
  --return-accepted: oneof<nothing, bool> # Indicates whether the seller allows the buyer to return the item.
  --sales-tax: list<string> # Percent of an item's price to be charged as the sales tax for the order. Look at cart.info method response for allowed values.Param structure:sales_tax[tax_percent] = decimal (##.###)sales_tax[tax_state] = stringsales_tax[shipping_inc_in_tax] = bool
  --search-keywords: string # Defines unique search keywords
  --seller-profiles: record # If the seller is subscribed to "Business Policies", use the seller_profiles instead of the shipping_details, payment_methods and return_accepted params.Param structure:seller_profiles[shipping_profile_id] = integerseller_profiles[payment_profile_id] = integerseller_profiles[return_profile_id] = integer — shape: {payment_profile_id?: string, return_profile_id?: string, shipping_profile_id?: string}
  --seo-url: string # Defines unique URL for SEO
  --shipping-details: list # The shipping details, including flat and calculated shipping costs and shipping insurance costs. Look at cart.info method response for allowed values.Param structure:shipping_details[0][shipping_type] = string shipping_details[0][shipping_service] = stringshipping_details[0][shipping_cost] = decimalshipping_details[1][shipping_type] = string shipping_details[1][shipping_service] = stringshipping_details[1][shipping_cost] = decimal — item shape: {shipping_cost?: float, shipping_service?: string, shipping_type?: string}
  --shipping-template-id: int # The numeric ID of the shipping template associated with the products in Etsy. (default: 0)
  --short-description: string # Defines short description
  --sku: string # Defines product's sku that has to be added
  --special-price: float # Defines product's model that has to be added
  --specifics: list<string> # An array of Item Specific Name/Value pairs used by the seller to provide descriptive details of an item in a structured manner. Param structure: specifics[int][name] = string specifics[int][value] = string
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --sprice-modified: string # Defines the date of special price modification
  --status: string # Defines product's status
  --store-id: string # Store Id
  --stores-ids: string # Assign product to the stores that is specified by comma-separated stores' id (default: 0)
  --tags: string # Product tags
  --tax-class-id: int # Defines tax classes where entity has to be added
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --tier-prices: list # Defines product's tier prices — item shape: {price?: float, quantity?: float}
  --type: string # Defines product's type (default: simple)
  --upc: string # Universal Product Code. A UPC (UPC-A) is a commonly used identifer for many different products.
  --url: string # Defines unique product's URL
  --viewed-count: int # Specifies the number of product's reviews (default: 0)
  --visible: string # Set visibility status
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --weight: float # Weight (default: 0)
  --weight-unit: string # Weight Unit
  --wholesale-price: float # Defines product's sale price
  --width: float # Defines product's width
]: any -> record<result: record<product_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.add.json")
  let req_body = {"attribute_name": $attribute_name, "attribute_set_name": $attribute_set_name, "avail_from": $avail_from, "available_for_sale": $available_for_sale, "available_for_view": $available_for_view, "backorder_status": $backorder_status, "barcode": $barcode, "best_offer": $best_offer, "brand_name": $brand_name, "categories_ids": $categories_ids, "category_id": $category_id, "clear_cache": $clear_cache, "condition": $condition, "cost_price": $cost_price, "country_of_origin": $country_of_origin, "created_at": $created_at, "description": $description, "downloadable": $downloadable, "ean": $ean, "files": $files, "group_prices": $group_prices, "gtin": $gtin, "harmonized_system_code": $harmonized_system_code, "height": $height, "image_name": $image_name, "image_url": $image_url, "isbn": $isbn, "lang_id": $lang_id, "length": $length, "listing_duration": $listing_duration, "listing_type": $listing_type, "manage_stock": $manage_stock, "manufacturer": $manufacturer, "marketplace_item_properties": $marketplace_item_properties, "meta_description": $meta_description, "meta_keywords": $meta_keywords, "meta_title": $meta_title, "model": $model, "mpn": $mpn, "name": $name, "old_price": $old_price, "ordered_count": $ordered_count, "package_details": $package_details, "payment_methods": $payment_methods, "paypal_email": $paypal_email, "price": $price, "product_class": $product_class, "quantity": $quantity, "return_accepted": $return_accepted, "sales_tax": $sales_tax, "search_keywords": $search_keywords, "seller_profiles": $seller_profiles, "seo_url": $seo_url, "shipping_details": $shipping_details, "shipping_template_id": $shipping_template_id, "short_description": $short_description, "sku": $sku, "special_price": $special_price, "specifics": $specifics, "sprice_create": $sprice_create, "sprice_expire": $sprice_expire, "sprice_modified": $sprice_modified, "status": $status, "store_id": $store_id, "stores_ids": $stores_ids, "tags": $tags, "tax_class_id": $tax_class_id, "taxable": $taxable, "tier_prices": $tier_prices, "type": $type, "upc": $upc, "url": $url, "viewed_count": $viewed_count, "visible": $visible, "warehouse_id": $warehouse_id, "weight": $weight, "weight_unit": $weight_unit, "wholesale_price": $wholesale_price, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of attributes and values.
#
# GET /product.attribute.list.json
# operationId: ProductAttributeList
export def "product-attribute-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Retrieves attributes specified by product id
  --attribute-id: string # Retrieves info for specified attribute_id
  --variant-id: string # Defines product's variants specified by variant id
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --attribute-group-id: string # Filter by attribute_group_id
  --set-name: string # Retrieves attributes specified by set_name in Magento
  --lang-id: string # Retrieves attributes specified by language id
  --store-id: string # Retrieves attributes specified by store id
  --sort-by: string # Set field to sort by (default: attribute_id)
  --sort-direction: string # Set sorting direction (default: asc)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: attribute_id,name)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, attribute: list<record>, custom_fields: record>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "variant_id" $variant_id "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "attribute_group_id" $attribute_group_id "scalar") (serialize-qp "set_name" $set_name "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.attribute.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "attribute_id": $attribute_id, "variant_id": $variant_id, "page_cursor": $page_cursor, "start": $start, "count": $count, "attribute_group_id": $attribute_group_id, "set_name": $set_name, "lang_id": $lang_id, "store_id": $store_id, "sort_by": $sort_by, "sort_direction": $sort_direction, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Set attribute value to product.
#
# POST /product.attribute.value.set.json
# operationId: ProductAttributeValueSet
export def "product-attribute-value-set-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the attribute should be added
  --attribute-id: string # Filter by attribute_id
  --attribute-group-id: string # Filter by attribute_group_id
  --attribute-name: string # Define attribute name
  --value: string # Define attribute value
  --value-id: int # Define attribute value id
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> record<result: record<attribute_id: string, product_id: string, value_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_group_id" $attribute_group_id "scalar") (serialize-qp "attribute_name" $attribute_name "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "value_id" $value_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.attribute.value.set.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "attribute_id": $attribute_id, "attribute_group_id": $attribute_group_id, "attribute_name": $attribute_name, "value": $value, "value_id": $value_id, "lang_id": $lang_id, "store_id": $store_id} | compact), body: null}
}

# Removes attribute value for a product.
#
# POST /product.attribute.value.unset.json
# operationId: ProductAttributeValueUnset
export def "product-attribute-value-unset-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Product id
  --attribute-id: string # Attribute Id
  --store-id: string # Store Id
  --include-default: oneof<nothing, bool> # Boolean, whether or not to unset default value of the attribute, if applicable (default: false)
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<success: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "include_default" $include_default "scalar") (serialize-qp "reindex" $reindex "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.attribute.value.unset.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "attribute_id": $attribute_id, "store_id": $store_id, "include_default": $include_default, "reindex": $reindex, "clear_cache": $clear_cache} | compact), body: null}
}

# Get list of brands from your store.
#
# GET /product.brand.list.json
# operationId: ProductBrandList
export def "product-brand-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,short_description,active,url)
  --brand-ids: string # Retrieves brands specified by brand ids
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Store Id
  --lang-id: string # Language id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: record<product: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "brand_ids" $brand_ids "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.brand.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "params": $params, "brand_ids": $brand_ids, "exclude": $exclude, "store_id": $store_id, "lang_id": $lang_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "response_fields": $response_fields} | compact), body: null}
}

# Search product child item (bundled item or configurable product variant) in store catalog.
#
# GET /product.child_item.find.json
# operationId: ProductChildItemFind
export def "product-child-item-find-json find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --store-id: string # Store Id
]: nothing -> record<result: record<children: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "find_value" $find_value "scalar") (serialize-qp "find_where" $find_where "scalar") (serialize-qp "find_params" $find_params "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.child_item.find.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"find_value": $find_value, "find_where": $find_where, "find_params": $find_params, "store_id": $store_id} | compact), body: null}
}

# Get child for specific product.
#
# GET /product.child_item.info.json
# operationId: ProductChildItemInfo
export def "product-child-item-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --product-id: string # Filter by parent product id
  --id: string # Entity id
  --store-id: string # Store Id
  --lang-id: string # Language id
  --currency-id: string # Currency Id
]: nothing -> record<result: record<additional_fields: record, advanced_price: list<record>, allow_backorders: bool, avail_for_sale: bool, combination: list<record>, cost_price: float, created_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, default_price: float, default_qty_in_pack: float, dimensions_unit: string, ean: string, full_description: string, gtin: string, height: float, id: string, images: list<record>, in_stock: bool, inventory: list<record>, inventory_level: float, is_qty_in_pack_fixed: bool, isbn: string, length: float, list_price: float, manage_stock: bool, meta_description: string, meta_keywords: string, meta_title: string, min_quantity: float, modified_time: record<additional_fields: record, custom_fields: record, format: string, value: string>, mpn: string, name: string, parent_id: string, short_description: string, sku: string, sort_order: int, tax_class_id: string, upc: string, weight: float, weight_unit: string, wholesale_price: float, width: float>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "currency_id" $currency_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.child_item.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "response_fields": $response_fields, "exclude": $exclude, "product_id": $product_id, "id": $id, "store_id": $store_id, "lang_id": $lang_id, "currency_id": $currency_id} | compact), body: null}
}

# Get child items list of specific product(s).
#
# GET /product.child_item.list.json
# operationId: ProductChildItemList
export def "product-child-item-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve products child items via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --product-id: string # Filter by parent product id
  --product-ids: string # Filter by parent product ids
  --store-id: string # Store Id
  --lang-id: string # Language id
  --currency-id: string # Currency Id
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, children: list<record>, custom_fields: record, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "product_ids" $product_ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "currency_id" $currency_id "scalar") (serialize-qp "avail_sale" $avail_sale "scalar") (serialize-qp "report_request_id" $report_request_id "scalar") (serialize-qp "disable_report_cache" $disable_report_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.child_item.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "product_id": $product_id, "product_ids": $product_ids, "store_id": $store_id, "lang_id": $lang_id, "currency_id": $currency_id, "avail_sale": $avail_sale, "report_request_id": $report_request_id, "disable_report_cache": $disable_report_cache} | compact), body: null}
}

# Count products in store.
#
# GET /product.count.json
# operationId: ProductCount
export def "product-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: string # Counts products specified by category id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail-view: oneof<nothing, bool> # Specifies the set of visible/invisible products
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --store-id: string # Counts products specified by store id
  --lang-id: string # Counts products specified by language id
  --product-ids: string # Counts products specified by product ids
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --brand-name: string # Retrieves brands specified by brand name
  --product-attributes: list<string> # Defines product attributes
  --status: string # Defines product's status
  --type: string # Defines products's type
]: nothing -> record<result: record<products_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "avail_view" $avail_view "scalar") (serialize-qp "avail_sale" $avail_sale "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "product_ids" $product_ids "scalar") (serialize-qp "report_request_id" $report_request_id "scalar") (serialize-qp "disable_report_cache" $disable_report_cache "scalar") (serialize-qp "brand_name" $brand_name "scalar") (serialize-qp "product_attributes" $product_attributes "csv") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category_id": $category_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "avail_view": $avail_view, "avail_sale": $avail_sale, "store_id": $store_id, "lang_id": $lang_id, "product_ids": $product_ids, "report_request_id": $report_request_id, "disable_report_cache": $disable_report_cache, "brand_name": $brand_name, "product_attributes": $product_attributes, "status": $status, "type": $type} | compact), body: null}
}

# Add currency and/or set default in store
#
# POST /product.currency.add.json
# operationId: ProductCurrencyAdd
export def "product-currency-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iso3: string # Specifies standardized currency code
  --rate: float # Defines the numerical identifier against to the major currency
  --name: string # Defines currency's name
  --avail: oneof<nothing, bool> # Specifies whether the currency is available (default: true)
  --symbol-left: string # Defines the symbol that is located before the currency
  --symbol-right: string # Defines the symbol that is located after the currency
  --default: oneof<nothing, bool> # Specifies currency's default meaning (default: false)
]: nothing -> record<result: record<currency_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iso3" $iso3 "scalar") (serialize-qp "rate" $rate "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "avail" $avail "scalar") (serialize-qp "symbol_left" $symbol_left "scalar") (serialize-qp "symbol_right" $symbol_right "scalar") (serialize-qp "default" $default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.currency.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"iso3": $iso3, "rate": $rate, "name": $name, "avail": $avail, "symbol_left": $symbol_left, "symbol_right": $symbol_right, "default": $default} | compact), body: null}
}

# Get list of currencies
#
# GET /product.currency.list.json
# operationId: ProductCurrencyList
export def "product-currency-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: name,iso3,default,avail)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --default: oneof<nothing, bool> # Specifies the set of default/not default currencies
  --avail: oneof<nothing, bool> # Specifies the set of available/not available currencies
]: nothing -> record<result: record<currency: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "default" $default "scalar") (serialize-qp "avail" $avail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.currency.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "params": $params, "page_cursor": $page_cursor, "exclude": $exclude, "response_fields": $response_fields, "default": $default, "avail": $avail} | compact), body: null}
}

# Product delete
#
# DELETE /product.delete.json
# operationId: ProductDelete
export def "product-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Product id that will be removed
]: nothing -> record<result: record<delete_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Retrieve all available fields for product item in store.
#
# GET /product.fields.json
# operationId: ProductFields
export def "product-fields-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.fields.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search product in store catalog. "Apple" is specified here by default.
#
# GET /product.find.json
# operationId: ProductFind
export def "product-find-json find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --find-value: string # Entity search that is specified by some value
  --find-where: string # Entity search that is specified by the comma-separated unique fields (default: name)
  --find-params: string # Entity search that is specified by comma-separated parameters (default: whole_words)
  --find-what: string # Parameter's value specifies the entity that has to be found (default: product)
  --lang-id: string # Search products specified by language id
  --store-id: string # Store Id
]: nothing -> record<result: record<product: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "find_value" $find_value "scalar") (serialize-qp "find_where" $find_where "scalar") (serialize-qp "find_params" $find_params "scalar") (serialize-qp "find_what" $find_what "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.find.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"find_value": $find_value, "find_where": $find_where, "find_params": $find_params, "find_what": $find_what, "lang_id": $lang_id, "store_id": $store_id} | compact), body: null}
}

# Add image to product
#
# POST /product.image.add.json
# operationId: ProductImageAdd
export def "product-image-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Content(body) encoded in base64 of image file
  image_name: string # Defines image's name
  --label: string # Defines alternative text that has to be attached to the picture
  --lang-id: string # Add product image on specified language id
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --position: int # Defines image’s position in the list (default: 0)
  --product-id: string # Defines product id where the image should be added
  --product-variant-id: int # Defines product's variants specified by variant id
  --store-id: string # Store Id
  type: string@type-completer-2 # Defines image's types that are specified by comma-separated list
  --url: string # Defines URL of the image that has to be added
  --variant-ids: string # Defines product's variants ids
]: any -> record<result: record<id: string, image_path: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.image.add.json")
  let req_body = {"content": $content, "image_name": $image_name, "label": $label, "lang_id": $lang_id, "mime": $mime, "position": $position, "product_id": $product_id, "product_variant_id": $product_variant_id, "store_id": $store_id, "type": $type, "url": $url, "variant_ids": $variant_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete image
#
# DELETE /product.image.delete.json
# operationId: ProductImageDelete
export def "product-image-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the image should be deleted
  --id: string # Entity id
  --store-id: string # Store Id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.image.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "id": $id, "store_id": $store_id} | compact), body: null}
}

# Update details of image
#
# PUT /product.image.update.json
# operationId: ProductImageUpdate
export def "product-image-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the image should be updated
  --image-name: string # Defines image's name
  --type: string # Defines image's types that are specified by comma-separated list (default: additional)
  --label: string # Defines alternative text that has to be attached to the picture
  --position: int # Defines image’s position in the list
  --id: string # Defines image update specified by image id
  --store-id: string # Store Id
  --lang-id: string # Language id
  --hidden: oneof<nothing, bool> # Define is hide image
]: nothing -> record<result: record<updated: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "image_name" $image_name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "hidden" $hidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.image.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "image_name": $image_name, "type": $type, "label": $label, "position": $position, "id": $id, "store_id": $store_id, "lang_id": $lang_id, "hidden": $hidden} | compact), body: null}
}

# Get product info about product ID *** or specify other product ID.
#
# GET /product.info.json
# operationId: ProductInfo
export def "product-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Retrieves product's info specified by product id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price,categories_ids)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --store-id: string # Retrieves product info specified by store id
  --lang-id: string # Retrieves product info specified by language id
  --currency-id: string # Currency Id
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
]: nothing -> record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "currency_id" $currency_id "scalar") (serialize-qp "report_request_id" $report_request_id "scalar") (serialize-qp "disable_report_cache" $disable_report_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "store_id": $store_id, "lang_id": $lang_id, "currency_id": $currency_id, "report_request_id": $report_request_id, "disable_report_cache": $disable_report_cache} | compact), body: null}
}

# Get list of products from your store. Returns 10 products by default.
#
# GET /product.list.json
# operationId: ProductList
export def "product-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-cursor: string # Used to retrieve products via cursor-based pagination (it can't be used with any other filtering parameter)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price,categories_ids)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --category-id: string # Retrieves products specified by category id
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --avail-view: oneof<nothing, bool> # Specifies the set of visible/invisible products
  --avail-sale: oneof<nothing, bool> # Specifies the set of available/not available products for sale
  --store-id: string # Retrieves products specified by store id
  --lang-id: string # Retrieves products specified by language id
  --currency-id: string # Currency Id
  --product-ids: string # Retrieves products specified by product ids
  --since-id: int # Retrieve entities starting from the specified id.
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --sort-by: string # Set field to sort by (default: id)
  --sort-direction: string # Set sorting direction (default: asc)
  --sku: string # Filter by product's sku
  --disable-cache: oneof<nothing, bool> # Disable cache for current request (default: false)
  --brand-name: string # Retrieves brands specified by brand name
  --product-attributes: list<string> # Defines product attributes
  --status: string # Defines product's status
  --type: string # Defines products's type
]: nothing -> record<additional_fields: record, custom_fields: record, pagination: record<additional_fields: record, custom_fields: record, next: string, previous: string>, result: record<additional_fields: record, custom_fields: record, product: list<record>, products_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "avail_view" $avail_view "scalar") (serialize-qp "avail_sale" $avail_sale "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "currency_id" $currency_id "scalar") (serialize-qp "product_ids" $product_ids "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "report_request_id" $report_request_id "scalar") (serialize-qp "disable_report_cache" $disable_report_cache "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sku" $sku "scalar") (serialize-qp "disable_cache" $disable_cache "scalar") (serialize-qp "brand_name" $brand_name "scalar") (serialize-qp "product_attributes" $product_attributes "csv") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_cursor": $page_cursor, "start": $start, "count": $count, "params": $params, "response_fields": $response_fields, "exclude": $exclude, "category_id": $category_id, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "avail_view": $avail_view, "avail_sale": $avail_sale, "store_id": $store_id, "lang_id": $lang_id, "currency_id": $currency_id, "product_ids": $product_ids, "since_id": $since_id, "report_request_id": $report_request_id, "disable_report_cache": $disable_report_cache, "sort_by": $sort_by, "sort_direction": $sort_direction, "sku": $sku, "disable_cache": $disable_cache, "brand_name": $brand_name, "product_attributes": $product_attributes, "status": $status, "type": $type} | compact), body: null}
}

# Add manufacturer to store and assign to product
#
# POST /product.manufacturer.add.json
# operationId: ProductManufacturerAdd
export def "product-manufacturer-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines products specified by product id
  --manufacturer: string # Defines product’s manufacturer's name
]: nothing -> record<result: record<manufacturer_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "manufacturer" $manufacturer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.manufacturer.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "manufacturer": $manufacturer} | compact), body: null}
}

# Add product option from store.
#
# POST /product.option.add.json
# operationId: ProductOptionAdd
export def "product-option-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Defines option's name
  --type: string@type-completer-3 # Defines option's type that has to be added
  --product-id: string # Defines product id where the option should be added
  --default-option-value: string # Defines default option value that has to be added
  --option-values: string # Defines option values that has to be added
  --description: string # Defines option's description
  --avail: oneof<nothing, bool> # Defines whether the option is available (default: true)
  --sort-order: int # Sort number in the list (default: 0)
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<option_id: string, product_option_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "default_option_value" $default_option_value "scalar") (serialize-qp "option_values" $option_values "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "avail" $avail "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "type": $type, "product_id": $product_id, "default_option_value": $default_option_value, "option_values": $option_values, "description": $description, "avail": $avail, "sort_order": $sort_order, "required": $required, "clear_cache": $clear_cache} | compact), body: null}
}

# Assign option from product.
#
# POST /product.option.assign.json
# operationId: ProductOptionAssign
export def "product-option-assign-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option should be assigned
  --option-id: string # Defines option id which has to be assigned
  --required: oneof<nothing, bool> # Defines if the option is required (default: false)
  --sort-order: int # Sort number in the list (default: 0)
  --option-values: string # Defines option values that has to be assigned
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<product_option_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "option_id" $option_id "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "option_values" $option_values "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.assign.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "option_id": $option_id, "required": $required, "sort_order": $sort_order, "option_values": $option_values, "clear_cache": $clear_cache} | compact), body: null}
}

# Get list of options.
#
# GET /product.option.list.json
# operationId: ProductOptionList
export def "product-option-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --product-id: string # Retrieves products' options specified by product id
  --lang-id: string # Language id
  --store-id: string # Store Id
]: nothing -> record<result: record<option: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "params": $params, "exclude": $exclude, "response_fields": $response_fields, "product_id": $product_id, "lang_id": $lang_id, "store_id": $store_id} | compact), body: null}
}

# Add product option item from option.
#
# POST /product.option.value.add.json
# operationId: ProductOptionValueAdd
export def "product-option-value-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option value should be added
  --option-id: string # Defines option id where the value has to be added
  --option-value: string # Defines option value that has to be added
  --sort-order: int # Sort number in the list (default: 0)
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<option_value_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "option_id" $option_id "scalar") (serialize-qp "option_value" $option_value "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.value.add.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "option_id": $option_id, "option_value": $option_value, "sort_order": $sort_order, "clear_cache": $clear_cache} | compact), body: null}
}

# Assign product option item from product.
#
# POST /product.option.value.assign.json
# operationId: ProductOptionValueAssign
export def "product-option-value-assign-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-option-id: int # Defines product's option id where the value has to be assigned
  --option-value-id: int # Defines value id that has to be assigned
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<product_option_value_id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_option_id" $product_option_id "scalar") (serialize-qp "option_value_id" $option_value_id "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.value.assign.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_option_id": $product_option_id, "option_value_id": $option_value_id, "clear_cache": $clear_cache} | compact), body: null}
}

# Update product option item from option.
#
# PUT /product.option.value.update.json
# operationId: ProductOptionValueUpdate
export def "product-option-value-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the option value should be updated
  --option-id: string # Defines option id where the value has to be updated
  --option-value-id: int # Defines value id that has to be assigned
  --option-value: string # Defines option value that has to be added
  --price: float # Defines new product option price
  --quantity: float # Defines new products' options quantity
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "option_id" $option_id "scalar") (serialize-qp "option_value_id" $option_value_id "scalar") (serialize-qp "option_value" $option_value "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "clear_cache" $clear_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.option.value.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "option_id": $option_id, "option_value_id": $option_value_id, "option_value": $option_value, "price": $price, "quantity": $quantity, "clear_cache": $clear_cache} | compact), body: null}
}

# Add some prices to the product.
#
# POST /product.price.add.json
# operationId: ProductPriceAdd
# --group_prices item shape: {group_id?: string, price?: float}
export def "product-price-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, price?: float}
  --product-id: string # Defines the product to which the price has to be added
]: any -> record<result: record<status: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.price.add.json")
  let req_body = {"group_prices": $group_prices, "product_id": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete some prices of the product
#
# DELETE /product.price.delete.json
# operationId: ProductPriceDelete
export def "product-price-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines the product where the price has to be deleted
  --group-prices: string # Defines product's group prices
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "group_prices" $group_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.price.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "group_prices": $group_prices} | compact), body: null}
}

# Update some prices of the product.
#
# PUT /product.price.update.json
# operationId: ProductPriceUpdate
# --group_prices item shape: {group_id?: string, id?: int, price?: float}
export def "product-price-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines product's group prices — item shape: {group_id?: string, id?: int, price?: float}
  --product-id: string # Defines the product where the price has to be updated
]: any -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.price.update.json")
  let req_body = {"group_prices": $group_prices, "product_id": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get reviews of a specific product.
#
# GET /product.review.list.json
# operationId: ProductReviewList
export def "product-review-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --product-id: string # Product id
  --ids: string # Retrieves reviews specified by ids
  --store-id: string # Store Id
  --status: string # Defines status
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,customer_id,email,message,status,product_id,nick_name,summary,rating,ratings,status,created_time)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: record<reviews: list<record>, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.review.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "page_cursor": $page_cursor, "count": $count, "product_id": $product_id, "ids": $ids, "store_id": $store_id, "status": $status, "params": $params, "exclude": $exclude, "response_fields": $response_fields} | compact), body: null}
}

# Assign product to store
#
# POST /product.store.assign.json
# operationId: ProductStoreAssign
export def "product-store-assign-json assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines id of the product which should be assigned to a store
  --store-id: string # Defines id of the store product should be assigned to
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.store.assign.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "store_id": $store_id} | compact), body: null}
}

# Add tax class and tax rate to store and assign to product.
#
# POST /product.tax.add.json
# operationId: ProductTaxAdd
# --tax_rates item shape: {name?: string, type?: string, value?: float}
export def "product-tax-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Defines tax class name where tax has to be added
  --product-id: string # Defines products specified by product id
  tax_rates: list # Defines tax rates of specified tax classes — item shape: {name?: string, type?: string, value?: float}
]: any -> record<result: record<tax_class_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.tax.add.json")
  let req_body = {"name": $name, "product_id": $product_id, "tax_rates": $tax_rates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update price and quantity for a specific product
#
# PUT /product.update.json
# operationId: ProductUpdate
export def "product-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines product id that has to be updated
  --model: string # Defines product model that has to be updated
  --old-price: float # Defines product's old price
  --price: float # Defines new product's price
  --special-price: float # Defines new product's special price
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --cost-price: float # Defines new product's cost price
  --retail-price: float # Defines new product's retail price
  --quantity: float # Defines new product's quantity
  --weight: float # Weight
  --increase-quantity: float # Defines the incremental changes in product quantity
  --reduce-quantity: float # Defines the decrement changes in product quantity
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --reserve-quantity: float # This parameter allows to reserve/unreserve product quantity.
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product
  --backorder-status: string # Set backorder status
  --name: string # Defines product's name that has to be updated
  --sku: string # Defines new product's sku
  --visible: string # Set visibility status
  --manufacturer: string # Defines product's manufacturer
  --manufacturer-id: string # Defines product's manufacturer by manufacturer_id
  --categories-ids: string # Defines product add that is specified by comma-separated categories id
  --description: string # Defines new product's description
  --short-description: string # Defines short description
  --meta-title: string # Defines unique meta title for each entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-description: string # Defines unique meta description of a entity
  --store-id: string # Defines store id where the product should be found
  --lang-id: string # Language id
  --in-stock: oneof<nothing, bool> # Set stock status
  --status: string # Defines product's status
  --seo-url: string # Defines unique URL for SEO
  --report-request-id: string # Report request id
  --disable-report-cache: oneof<nothing, bool> # Disable report cache for current request (default: false)
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --tags: string # Product tags
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --product-class: string # A categorization for the product
  --height: float # Defines product's height
  --length: float # Defines product's length
  --width: float # Defines product's width
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --country-of-origin: string # The country where the inventory item was made
  --search-keywords: string # Defines unique search keywords
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "old_price" $old_price "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "special_price" $special_price "scalar") (serialize-qp "sprice_create" $sprice_create "scalar") (serialize-qp "sprice_expire" $sprice_expire "scalar") (serialize-qp "cost_price" $cost_price "scalar") (serialize-qp "retail_price" $retail_price "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "weight" $weight "scalar") (serialize-qp "increase_quantity" $increase_quantity "scalar") (serialize-qp "reduce_quantity" $reduce_quantity "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "reserve_quantity" $reserve_quantity "scalar") (serialize-qp "manage_stock" $manage_stock "scalar") (serialize-qp "backorder_status" $backorder_status "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sku" $sku "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "manufacturer_id" $manufacturer_id "scalar") (serialize-qp "categories_ids" $categories_ids "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "short_description" $short_description "scalar") (serialize-qp "meta_title" $meta_title "scalar") (serialize-qp "meta_keywords" $meta_keywords "scalar") (serialize-qp "meta_description" $meta_description "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "in_stock" $in_stock "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "seo_url" $seo_url "scalar") (serialize-qp "report_request_id" $report_request_id "scalar") (serialize-qp "disable_report_cache" $disable_report_cache "scalar") (serialize-qp "reindex" $reindex "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "clear_cache" $clear_cache "scalar") (serialize-qp "gtin" $gtin "scalar") (serialize-qp "taxable" $taxable "scalar") (serialize-qp "product_class" $product_class "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "harmonized_system_code" $harmonized_system_code "scalar") (serialize-qp "country_of_origin" $country_of_origin "scalar") (serialize-qp "search_keywords" $search_keywords "scalar") (serialize-qp "barcode" $barcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "model": $model, "old_price": $old_price, "price": $price, "special_price": $special_price, "sprice_create": $sprice_create, "sprice_expire": $sprice_expire, "cost_price": $cost_price, "retail_price": $retail_price, "quantity": $quantity, "weight": $weight, "increase_quantity": $increase_quantity, "reduce_quantity": $reduce_quantity, "warehouse_id": $warehouse_id, "reserve_quantity": $reserve_quantity, "manage_stock": $manage_stock, "backorder_status": $backorder_status, "name": $name, "sku": $sku, "visible": $visible, "manufacturer": $manufacturer, "manufacturer_id": $manufacturer_id, "categories_ids": $categories_ids, "description": $description, "short_description": $short_description, "meta_title": $meta_title, "meta_keywords": $meta_keywords, "meta_description": $meta_description, "store_id": $store_id, "lang_id": $lang_id, "in_stock": $in_stock, "status": $status, "seo_url": $seo_url, "report_request_id": $report_request_id, "disable_report_cache": $disable_report_cache, "reindex": $reindex, "tags": $tags, "clear_cache": $clear_cache, "gtin": $gtin, "taxable": $taxable, "product_class": $product_class, "height": $height, "length": $length, "width": $width, "harmonized_system_code": $harmonized_system_code, "country_of_origin": $country_of_origin, "search_keywords": $search_keywords, "barcode": $barcode} | compact), body: null}
}

# Add variant to product.
#
# POST /product.variant.add.json
# operationId: ProductVariantAdd
# --attributes item shape: {attribute_name?: string, attribute_price?: float, attribute_value?: string}
export def "product-variant-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Defines variant's attributes list — item shape: {attribute_name?: string, attribute_price?: float, attribute_value?: string}
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for sale (default: true)
  --available-for-view: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for users (default: true)
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --cost-price: float # Defines new product's cost price
  --country-of-origin: string # The country where the inventory item was made
  --created-at: string # Defines the date of entity creation
  --description: string # Specifies variant's description
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --height: float # Defines product's height
  --lang-id: string # Language id
  --length: float # Defines product's length
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product variant
  --manufacturer: string # Specifies the product variant's manufacturer
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --meta-title: string # Defines unique meta title for each entity
  model: string # Specifies variant's model that has to be added
  --name: string # Defines variant's name that has to be added
  --price: float # Defines new product's variant price
  --product-id: string # Defines product's id where the variant has to be added
  --quantity: float # Defines product variant's quantity that has to be added (default: 0)
  --short-description: string # Defines short description
  --sku: string # Defines variant's sku that has to be added
  --special-price: float # Specifies variant's model that has to be added
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --sprice-modified: string # Defines the date of special price modification
  --store-id: string # Add variants specified by store id
  --tax-class-id: int # Defines tax classes where entity has to be added
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --url: string # Defines unique product variant's URL
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --weight: float # Weight (default: 0)
  --weight-unit: string # Weight Unit
  --width: float # Defines product's width
]: any -> record<result: record<product_variant_id: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.variant.add.json")
  let req_body = {"attributes": $attributes, "available_for_sale": $available_for_sale, "available_for_view": $available_for_view, "barcode": $barcode, "clear_cache": $clear_cache, "cost_price": $cost_price, "country_of_origin": $country_of_origin, "created_at": $created_at, "description": $description, "harmonized_system_code": $harmonized_system_code, "height": $height, "lang_id": $lang_id, "length": $length, "manage_stock": $manage_stock, "manufacturer": $manufacturer, "meta_description": $meta_description, "meta_keywords": $meta_keywords, "meta_title": $meta_title, "model": $model, "name": $name, "price": $price, "product_id": $product_id, "quantity": $quantity, "short_description": $short_description, "sku": $sku, "special_price": $special_price, "sprice_create": $sprice_create, "sprice_expire": $sprice_expire, "sprice_modified": $sprice_modified, "store_id": $store_id, "tax_class_id": $tax_class_id, "taxable": $taxable, "url": $url, "warehouse_id": $warehouse_id, "weight": $weight, "weight_unit": $weight_unit, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get count variants.
#
# GET /product.variant.count.json
# operationId: ProductVariantCount
export def "product-variant-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --category-id: string # Counts products’ variants specified by category id
  --product-id: string # Retrieves products' variants specified by product id
  --store-id: string # Retrieves variants specified by store id
]: nothing -> record<result: record<variants_count: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "category_id": $category_id, "product_id": $product_id, "store_id": $store_id} | compact), body: null}
}

# Delete variant.
#
# DELETE /product.variant.delete.json
# operationId: ProductVariantDelete
export def "product-variant-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines variant removal, specified by variant id
  --product-id: string # Defines product's id where the variant has to be deleted
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "product_id" $product_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "product_id": $product_id} | compact), body: null}
}

# Add image to product
#
# POST /product.variant.image.add.json
# operationId: ProductVariantImageAdd
export def "product-variant-image-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Content(body) encoded in base64 of image file
  image_name: string # Defines image's name
  --label: string # Defines alternative text that has to be attached to the picture
  --mime: string # Mime type of image http://en.wikipedia.org/wiki/Internet_media_type.
  --option-id: string # Defines option id of the product variant for which the image will be added
  --position: int # Defines image’s position in the list (default: 0)
  --product-id: string # Defines product id where the variant image has to be added
  product_variant_id: int # Defines product's variants specified by variant id
  --store-id: string # Store Id
  type: string@type-completer-2 # Defines image's types that are specified by comma-separated list (default: base)
  --url: string # Defines URL of the image that has to be added
]: any -> record<result: record<id: string, image_path: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.variant.image.add.json")
  let req_body = {"content": $content, "image_name": $image_name, "label": $label, "mime": $mime, "option_id": $option_id, "position": $position, "product_id": $product_id, "product_variant_id": $product_variant_id, "store_id": $store_id, "type": $type, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete image to product
#
# DELETE /product.variant.image.delete.json
# operationId: ProductVariantImageDelete
export def "product-variant-image-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Defines product id where the variant image should be deleted
  --product-variant-id: int # Defines product's variants specified by variant id
  --id: string # Entity id
  --store-id: string # Store Id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "product_variant_id" $product_variant_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.image.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_id": $product_id, "product_variant_id": $product_variant_id, "id": $id, "store_id": $store_id} | compact), body: null}
}

# Get variant info.
#
# GET /product.variant.info.json
# operationId: ProductVariantInfo
export def "product-variant-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --id: string # Retrieves variant's info specified by variant id
  --store-id: string # Retrieves variant info specified by store id
]: nothing -> record<result: record<additional_fields: record, advanced_price: list<record>, avail_sale: bool, avail_view: bool, backorders: string, categories_ids: list<string>, cost_price: float, create_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, custom_fields: record, description: string, dimensions_unit: string, group_items: list<record>, group_price: list<record>, height: float, id: string, images: list<record>, inventory: list<record>, is_downloadable: bool, is_stock_managed: bool, is_virtual: bool, length: float, manage_stock: string, meta_description: string, meta_keywords: string, meta_title: string, modified_at: record<additional_fields: record, custom_fields: record, format: string, value: string>, name: string, price: float, product_options: list<record>, quantity: float, related_products_ids: list<string>, seo_url: string, short_description: string, sort_order: int, special_price: record<additional_fields: record, avail: bool, created_at: record, custom_fields: record, expired_at: record, modified_at: record, value: float>, stores_ids: list<string>, tax_class_id: string, tier_price: list<record>, type: string, u_brand: string, u_brand_id: string, u_model: string, u_mpn: string, u_sku: string, u_upc: string, url: string, weight: float, weight_unit: string, width: float>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "exclude": $exclude, "id": $id, "store_id": $store_id} | compact), body: null}
}

# Get list variants.
#
# GET /product.variant.list.json
# operationId: ProductVariantList
export def "product-variant-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,name,description,price)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --category-id: string # Retrieves products’ variants specified by category id
  --product-id: string # Retrieves products' variants specified by product id
  --store-id: string # Retrieves variants specified by store id
]: nothing -> record<result: record<variant: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "params": $params, "exclude": $exclude, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "category_id": $category_id, "product_id": $product_id, "store_id": $store_id} | compact), body: null}
}

# Add some prices to the product variant.
#
# POST /product.variant.price.add.json
# operationId: ProductVariantPriceAdd
# --group_prices item shape: {group_id?: string, price?: float}
export def "product-variant-price-add-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines variants's group prices — item shape: {group_id?: string, price?: float}
  --id: string # Defines the variant to which the price has to be added
]: any -> record<result: record<status: string>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.variant.price.add.json")
  let req_body = {"group_prices": $group_prices, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete some prices of the product variant.
#
# DELETE /product.variant.price.delete.json
# operationId: ProductVariantPriceDelete
export def "product-variant-price-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Defines the variant where the price has to be deleted
  --group-prices: string # Defines variants's group prices
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "group_prices" $group_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.price.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "group_prices": $group_prices} | compact), body: null}
}

# Update some prices of the product variant.
#
# PUT /product.variant.price.update.json
# operationId: ProductVariantPriceUpdate
# --group_prices item shape: {group_id?: string, id?: int, price?: float}
export def "product-variant-price-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-prices: list # Defines variants's group prices — item shape: {group_id?: string, id?: int, price?: float}
  --id: string # Defines the variant where the price has to be updated
]: any -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product.variant.price.update.json")
  let req_body = {"group_prices": $group_prices, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update variant.
#
# PUT /product.variant.update.json
# operationId: ProductVariantUpdate
export def "product-variant-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # Defines store id where the variant should be found
  --id: string # Defines variant update specified by variant id
  --product-id: string # Defines product's id where the variant has to be updated
  --warehouse-id: string # This parameter is used for selecting a warehouse where you need to set/modify a product quantity.
  --reserve-quantity: float # This parameter allows to reserve/unreserve product variants quantity.
  --quantity: float # Defines new products' variants quantity
  --increase-quantity: float # Defines the incremental changes in product quantity (default: 0)
  --reduce-quantity: float # Defines the decrement changes in product quantity (default: 0)
  --price: float # Defines new product's variant price
  --special-price: float # Defines new product's variant special price
  --retail-price: float # Defines new product's retail price
  --old-price: float # Defines product's old price
  --cost-price: float # Defines new product's cost price
  --sprice-create: string # Defines the date of special price creation
  --sprice-expire: string # Defines the term of special price offer duration
  --manage-stock: oneof<nothing, bool> # Defines inventory tracking for product variant
  --in-stock: oneof<nothing, bool> # Set stock status
  --name: string # Defines variant's name that has to be updated
  --description: string # Specifies variant's description
  --sku: string # Defines new product's variant sku
  --meta-title: string # Defines unique meta title for each entity
  --meta-description: string # Defines unique meta description of a entity
  --meta-keywords: string # Defines unique meta keywords for each entity
  --short-description: string # Defines short description
  --visible: string # Set visibility status
  --status: string # Defines product variant's status
  --backorder-status: string # Set backorder status
  --weight: float # Weight (default: 0)
  --barcode: string # A barcode is a unique code composed of numbers used as a product identifier.
  --reindex: oneof<nothing, bool> # Is reindex required (default: true)
  --taxable: oneof<nothing, bool> # Specifies whether a tax is charged (default: true)
  --options: list<string> # Defines variant's options list
  --harmonized-system-code: string # Harmonized System Code. An HSC is a 6-digit identifier that allows participating countries to classify traded goods on a common basis for customs purposes
  --country-of-origin: string # The country where the inventory item was made
  --width: float # Defines product's width
  --height: float # Defines product's height
  --length: float # Defines product's length
  --gtin: string # Global Trade Item Number. An GTIN is an identifier for trade items.
  --clear-cache: oneof<nothing, bool> # Is cache clear required (default: true)
  --lang-id: string # Language id
  --model: string # Specifies variant's model that has to be added
  --available-for-sale: oneof<nothing, bool> # Specifies the set of visible/invisible product's variants for sale (default: true)
]: nothing -> record<result: record<updated_items: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "store_id" $store_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "reserve_quantity" $reserve_quantity "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "increase_quantity" $increase_quantity "scalar") (serialize-qp "reduce_quantity" $reduce_quantity "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "special_price" $special_price "scalar") (serialize-qp "retail_price" $retail_price "scalar") (serialize-qp "old_price" $old_price "scalar") (serialize-qp "cost_price" $cost_price "scalar") (serialize-qp "sprice_create" $sprice_create "scalar") (serialize-qp "sprice_expire" $sprice_expire "scalar") (serialize-qp "manage_stock" $manage_stock "scalar") (serialize-qp "in_stock" $in_stock "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "sku" $sku "scalar") (serialize-qp "meta_title" $meta_title "scalar") (serialize-qp "meta_description" $meta_description "scalar") (serialize-qp "meta_keywords" $meta_keywords "scalar") (serialize-qp "short_description" $short_description "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "backorder_status" $backorder_status "scalar") (serialize-qp "weight" $weight "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "reindex" $reindex "scalar") (serialize-qp "taxable" $taxable "scalar") (serialize-qp "options" $options "csv") (serialize-qp "harmonized_system_code" $harmonized_system_code "scalar") (serialize-qp "country_of_origin" $country_of_origin "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "gtin" $gtin "scalar") (serialize-qp "clear_cache" $clear_cache "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "available_for_sale" $available_for_sale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product.variant.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"store_id": $store_id, "id": $id, "product_id": $product_id, "warehouse_id": $warehouse_id, "reserve_quantity": $reserve_quantity, "quantity": $quantity, "increase_quantity": $increase_quantity, "reduce_quantity": $reduce_quantity, "price": $price, "special_price": $special_price, "retail_price": $retail_price, "old_price": $old_price, "cost_price": $cost_price, "sprice_create": $sprice_create, "sprice_expire": $sprice_expire, "manage_stock": $manage_stock, "in_stock": $in_stock, "name": $name, "description": $description, "sku": $sku, "meta_title": $meta_title, "meta_description": $meta_description, "meta_keywords": $meta_keywords, "short_description": $short_description, "visible": $visible, "status": $status, "backorder_status": $backorder_status, "weight": $weight, "barcode": $barcode, "reindex": $reindex, "taxable": $taxable, "options": $options, "harmonized_system_code": $harmonized_system_code, "country_of_origin": $country_of_origin, "width": $width, "height": $height, "length": $length, "gtin": $gtin, "clear_cache": $clear_cache, "lang_id": $lang_id, "model": $model, "available_for_sale": $available_for_sale} | compact), body: null}
}

# Get subscribers list
#
# GET /subscriber.list.json
# operationId: SubscriberList
export def "subscriber-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --subscribed: oneof<nothing, bool> # Filter by subscription status
  --store-id: string # Store Id
  --email: string # Filter subscribers by email
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: force_all)
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
  --created-from: string # Retrieve entities from their creation date
  --created-to: string # Retrieve entities to their creation date
  --modified-from: string # Retrieve entities from their modification date
  --modified-to: string # Retrieve entities to their modification date
  --page-cursor: string # Used to retrieve entities via cursor-based pagination (it can't be used with any other filtering parameter)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
]: nothing -> record<result: record<subscribers: list<record>, total_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "subscribed" $subscribed "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "response_fields" $response_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriber.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "subscribed": $subscribed, "store_id": $store_id, "email": $email, "params": $params, "exclude": $exclude, "created_from": $created_from, "created_to": $created_to, "modified_from": $modified_from, "modified_to": $modified_to, "page_cursor": $page_cursor, "response_fields": $response_fields} | compact), body: null}
}

# Get info about tax
#
# GET /tax.class.info.json
# operationId: TaxClassInfo
export def "tax-class-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tax-class-id: string # Retrieves taxes specified by class id
  --store-id: string # Store Id
  --lang-id: string # Language id
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: tax_class_id,name,avail)
  --response-fields: string # Set this parameter in order to choose which entity fields you want to retrieve
  --exclude: string # Set this parameter in order to choose which entity fields you want to ignore. Works only if parameter `params` equal force_all
]: nothing -> record<result: record<additional_fields: record, avail: bool, custom_fields: record, id: string, name: string, tax: float, tax_rates: list<record>, tax_type: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tax_class_id" $tax_class_id "scalar") (serialize-qp "store_id" $store_id "scalar") (serialize-qp "lang_id" $lang_id "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tax.class.info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tax_class_id": $tax_class_id, "store_id": $store_id, "lang_id": $lang_id, "params": $params, "response_fields": $response_fields, "exclude": $exclude} | compact), body: null}
}

# Count registered webhooks on the store.
#
# GET /webhook.count.json
# operationId: WebhookCount
export def "webhook-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string # The entity you want to filter webhooks by (e.g. order or product)
  --action: string # The action you want to filter webhooks by (e.g. order or product)
  --active: oneof<nothing, bool> # The webhook status you want to filter webhooks by
]: nothing -> record<result: record<webhook_count: int>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook.count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity": $entity, "action": $action, "active": $active} | compact), body: null}
}

# Create webhook on the store and subscribe to it.
#
# POST /webhook.create.json
# operationId: WebhookCreate
export def "webhook-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string # Specify the entity that you want to enable webhooks for (e.g product, order, customer, category)
  --action: string # Specify what action (event) will trigger the webhook (e.g add, delete, or update)
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data.
  --label: string # The name you give to the webhook
  --fields: string # Fields the webhook should send (default: force_all)
  --active: oneof<nothing, bool> # Webhook status (default: true)
  --store-id: string # Defines store id where the webhook should be assigned
]: nothing -> record<result: record<id: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "store_id" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook.create.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entity": $entity, "action": $action, "callback": $callback, "label": $label, "fields": $fields, "active": $active, "store_id": $store_id} | compact), body: null}
}

# Delete registered webhook on the store.
#
# DELETE /webhook.delete.json
# operationId: WebhookDelete
export def "webhook-delete-json delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Webhook id
]: nothing -> record<result: record<deleted: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook.delete.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# List all Webhooks that are available on this store.
#
# GET /webhook.events.json
# operationId: WebhookEvents
export def "webhook-events-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<events: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook.events.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List registered webhook on the store.
#
# GET /webhook.list.json
# operationId: WebhookList
export def "webhook-list-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Set this parameter in order to choose which entity fields you want to retrieve (default: id,entity,action,callback)
  --start: int # This parameter sets the number from which you want to get entities (default: 0)
  --count: int # This parameter sets the entity amount that has to be retrieved. Max allowed count=250 (default: 10)
  --entity: string # The entity you want to filter webhooks by (e.g. order or product)
  --action: string # The action you want to filter webhooks by (e.g. add, update, or delete)
  --active: oneof<nothing, bool> # The webhook status you want to filter webhooks by
  --ids: string # List of сomma-separated webhook ids
]: nothing -> record<result: record<webhook: list<record>>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook.list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"params": $params, "start": $start, "count": $count, "entity": $entity, "action": $action, "active": $active, "ids": $ids} | compact), body: null}
}

# Update Webhooks parameters.
#
# PUT /webhook.update.json
# operationId: WebhookUpdate
export def "webhook-update-json update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Webhook id
  --callback: string # Callback url that returns shipping rates. It should be able to accept POST requests with json data.
  --label: string # The name you give to the webhook
  --fields: string # Fields the webhook should send
  --active: oneof<nothing, bool> # Webhook status
]: nothing -> record<result: record<updated: string>, return_code: int, return_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook.update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "callback": $callback, "label": $label, "fields": $fields, "active": $active} | compact), body: null}
}
