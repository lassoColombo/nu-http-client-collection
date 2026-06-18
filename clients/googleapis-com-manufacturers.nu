# Auto-generated client for Manufacturer Center API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/manufacturers/v1/openapi.json
# Auth: --token flag or $env.MANUFACTURER_CENTER_API_TOKEN

const BASE_URL = "https://manufacturers.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANUFACTURER_CENTER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://manufacturers.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts delete" } } | get name | first)
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

# Deletes a product certification by its name. This method can only be called by certification bodies.
#
# DELETE /v1/{name}
# operationId: manufacturers.accounts.languages.productCertifications.delete
export def "accounts delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a product certification by its name. This method can only be called by certification bodies.
#
# GET /v1/{name}
# operationId: manufacturers.accounts.languages.productCertifications.get
export def "accounts get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<brand: string, certification: table<authority: string, link: string, logo: string, name: string, validUntil: string, value: string>, countryCode: list<string>, destinationStatuses: table<destination: string, status: string>, issues: table<attribute: string, description: string, destination: string, resolution: string, severity: string, timestamp: string, title: string, type: string>, mpn: list<string>, name: string, productCode: list<string>, productType: list<string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates (or creates if allow_missing = true) a product certification which links certifications with products. This method can only be called by certification bodies.
#
# PATCH /v1/{name}
# operationId: manufacturers.accounts.languages.productCertifications.patch
# --certification item shape: {authority?: string, link?: string, logo?: string, name?: string, validUntil?: string, value?: string}
# --destinationStatuses item shape: {destination?: string, status?: "UNKNOWN"|"ACTIVE"|"PENDING"|"DISAPPROVED"}
# --issues item shape: {attribute?: string, description?: string, destination?: string, resolution?: "RESOLUTION_UNSPECIFIED"|"USER_ACTION"|"PENDING_PROCESSING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", timestamp?: string, title?: string, type?: string}
export def "accounts update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Optional. The list of fields to update according to aip.dev/134. However, only full update is supported as of right now. Therefore, it can be either ignored or set to "*". Setting any other values will returns UNIMPLEMENTED error.
  --brand: string # Required. This is the product's brand name. The brand is used to help identify your product.
  --certification: list # Required. A list of certifications to link to the described product. — item shape: {authority?: string, link?: string, logo?: string, name?: string, validUntil?: string, value?: string}
  --country-code: list<string> # Optional. A 2-letter country code (ISO 3166-1 Alpha 2).
  --mpn: list<string> # Optional. These are the Manufacturer Part Numbers (MPN). MPNs are used to uniquely identify a specific product among all products from the same manufacturer
  --body-name: string # Required. The unique name identifier of a product certification Format: accounts/{account}/languages/{language_code}/productCertifications/{id} Where `id` is a some unique identifier and `language_code` is a 2-letter ISO 639-1 code of a Shopping supported language according to https://support.google.com/merchants/answer/160637.
  --product-code: list<string> # Optional. Another name for GTIN.
  --product-type: list<string> # Optional. These are your own product categorization system in your product data.
  --title: string # Required. This is to clearly identify the product you are certifying.
]: any -> record<brand: string, certification: table<authority: string, link: string, logo: string, name: string, validUntil: string, value: string>, countryCode: list<string>, destinationStatuses: table<destination: string, status: string>, issues: table<attribute: string, description: string, destination: string, resolution: string, severity: string, timestamp: string, title: string, type: string>, mpn: list<string>, name: string, productCode: list<string>, productType: list<string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1/{name}") $qp)
  let req_body = {"brand": $brand, "certification": $certification, "countryCode": $country_code, "mpn": $mpn, "name": $body_name, "productCode": $product_code, "productType": $product_type, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists product certifications from a specified certification body. This method can only be called by certification bodies.
#
# GET /v1/{parent}/productCertifications
# operationId: manufacturers.accounts.languages.productCertifications.list
export def "product-certifications list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Optional. The maximum number of product certifications to return. The service may return fewer than this value. If unspecified, at most 50 product certifications will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. A page token, received from a previous `ListProductCertifications` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListProductCertifications` must match the call that provided the page token. Required if requesting the second or higher page.
]: nothing -> record<nextPageToken: string, productCertifications: table<brand: string, certification: list, countryCode: list, destinationStatuses: list, issues: list, mpn: list, name: string, productCode: list, productType: list, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1/{parent}/productCertifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the products in a Manufacturer Center account.
#
# GET /v1/{parent}/products
# operationId: manufacturers.accounts.products.list
export def "products list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --include: list<string> # The information to be included in the response. Only sections listed here will be returned.
  --page-size: int # Maximum number of product statuses to return in the response, used for paging.
  --page-token: string # The token returned by the previous request.
]: nothing -> record<nextPageToken: string, products: table<attributes: record, contentLanguage: string, destinationStatuses: list, issues: list, name: string, parent: string, productId: string, targetCountry: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "include" $include "multi") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1/{parent}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes the product from a Manufacturer Center account.
#
# DELETE /v1/{parent}/products/{name}
# operationId: manufacturers.accounts.products.delete
export def "products delete" [
  parent: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent), name: (encode-path-segment $name)} | format pattern "/v1/{parent}/products/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the product from a Manufacturer Center account, including product issues. A recently updated product takes around 15 minutes to process. Changes are only visible after it has been processed. While some issues may be available once the product has been processed, other issues may take days to appear.
#
# GET /v1/{parent}/products/{name}
# operationId: manufacturers.accounts.products.get
export def "products get" [
  parent: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --include: list<string> # The information to be included in the response. Only sections listed here will be returned.
]: nothing -> record<attributes: record<additionalImageLink: list<record>, ageGroup: string, brand: string, capacity: record<unit: string, value: string>, color: string, count: record<unit: string, value: string>, description: string, disclosureDate: string, excludedDestination: list<string>, featureDescription: list<record>, flavor: string, format: string, gender: string, grocery: record<activeIngredients: string, alcoholByVolume: float, allergens: string, derivedNutritionClaim: list, directions: string, indications: string, ingredients: string, nutritionClaim: list, storageInstructions: string>, gtin: list<string>, imageLink: record<imageUrl: string, status: string, type: string>, includedDestination: list<string>, itemGroupId: string, material: string, mpn: string, nutrition: record<addedSugars: record, addedSugarsDailyPercentage: float, calcium: record, calciumDailyPercentage: float, cholesterol: record, cholesterolDailyPercentage: float, dietaryFiber: record, dietaryFiberDailyPercentage: float, energy: record, energyFromFat: record, folateDailyPercentage: float, folateFolicAcid: record, folateMcgDfe: float, iron: record, ironDailyPercentage: float, monounsaturatedFat: record, nutritionFactMeasure: string, polyols: record, polyunsaturatedFat: record, potassium: record, potassiumDailyPercentage: float, preparedSizeDescription: string, protein: record, proteinDailyPercentage: float, saturatedFat: record, saturatedFatDailyPercentage: float, servingSizeDescription: string, servingSizeMeasure: record, servingsPerContainer: string, sodium: record, sodiumDailyPercentage: float, starch: record, totalCarbohydrate: record, totalCarbohydrateDailyPercentage: float, totalFat: record, totalFatDailyPercentage: float, totalSugars: record, totalSugarsDailyPercentage: float, transFat: record, transFatDailyPercentage: float, vitaminD: record, vitaminDDailyPercentage: float, voluntaryNutritionFact: list>, pattern: string, productDetail: list<record>, productHighlight: list<string>, productLine: string, productName: string, productPageUrl: string, productType: list<string>, releaseDate: string, richProductContent: list<string>, scent: string, size: string, sizeSystem: string, sizeType: list<string>, suggestedRetailPrice: record<amount: string, currency: string>, targetClientId: string, theme: string, title: string, videoLink: list<string>>, contentLanguage: string, destinationStatuses: table<destination: string, status: string>, issues: table<attribute: string, description: string, destination: string, resolution: string, severity: string, timestamp: string, title: string, type: string>, name: string, parent: string, productId: string, targetCountry: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent), name: (encode-path-segment $name)} | format pattern "/v1/{parent}/products/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Inserts or updates the attributes of the product in a Manufacturer Center account. Creates a product with the provided attributes. If the product already exists, then all attributes are replaced with the new ones. The checks at upload time are minimal. All required attributes need to be present for a product to be valid. Issues may show up later after the API has accepted a new upload for a product and it is possible to overwrite an existing valid product with an invalid product. To detect this, you should retrieve the product and check it for issues once the new version is available. Uploaded attributes first need to be processed before they can be retrieved. Until then, new products will be unavailable, and retrieval of previously uploaded products will return the original state of the product.
#
# PUT /v1/{parent}/products/{name}
# operationId: manufacturers.accounts.products.update
# --additionalImageLink item shape: {imageUrl?: string, status?: "STATUS_UNSPECIFIED"|"PENDING_PROCESSING"|"PENDING_CRAWL"|"OK"|"ROBOTED"|"XROBOTED"|"CRAWL_ERROR"|"PROCESSING_ERROR"|"DECODING_ERROR"|"TOO_BIG"|"CRAWL_SKIPPED"|"HOSTLOADED"|"HTTP_404", type?: "TYPE_UNSPECIFIED"|"CRAWLED"|"UPLOADED"}
# --capacity shape: {unit?: string, value?: string}
# --count shape: {unit?: string, value?: string}
# --featureDescription item shape: {headline?: string, image?: record, text?: string}
# --grocery shape: {activeIngredients?: string, alcoholByVolume?: float, allergens?: string, derivedNutritionClaim?: list<string>, directions?: string, indications?: string, ingredients?: string, nutritionClaim?: list<string>, storageInstructions?: string}
# --imageLink shape: {imageUrl?: string, status?: "STATUS_UNSPECIFIED"|"PENDING_PROCESSING"|"PENDING_CRAWL"|"OK"|"ROBOTED"|"XROBOTED"|"CRAWL_ERROR"|"PROCESSING_ERROR"|"DECODING_ERROR"|"TOO_BIG"|"CRAWL_SKIPPED"|"HOSTLOADED"|"HTTP_404", type?: "TYPE_UNSPECIFIED"|"CRAWLED"|"UPLOADED"}
# --nutrition shape: {addedSugars?: record, addedSugarsDailyPercentage?: float, calcium?: record, calciumDailyPercentage?: float, cholesterol?: record, cholesterolDailyPercentage?: float, dietaryFiber?: record, dietaryFiberDailyPercentage?: float, energy?: record, energyFromFat?: record, folateDailyPercentage?: float, folateFolicAcid?: record, folateMcgDfe?: float, iron?: record, ironDailyPercentage?: float, monounsaturatedFat?: record, nutritionFactMeasure?: string, polyols?: record, polyunsaturatedFat?: record, ... (24 more fields)}
# --productDetail item shape: {attributeName?: string, attributeValue?: string, sectionName?: string}
# --suggestedRetailPrice shape: {amount?: string, currency?: string}
export def "products update" [
  parent: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --additional-image-link: list # The additional images of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#addlimage. — item shape: {imageUrl?: string, status?: "STATUS_UNSPECIFIED"|"PENDING_PROCESSING"|"PENDING_CRAWL"|"OK"|"ROBOTED"|"XROBOTED"|"CRAWL_ERROR"|"PROCESSING_ERROR"|"DECODING_ERROR"|"TOO_BIG"|"CRAWL_SKIPPED"|"HOSTLOADED"|"HTTP_404", type?: "TYPE_UNSPECIFIED"|"CRAWLED"|"UPLOADED"}
  --age-group: string # The target age group of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#agegroup.
  --brand: string # The brand name of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#brand.
  --capacity: record # The capacity of a product. For more information, see https://support.google.com/manufacturers/answer/6124116#capacity. — shape: {unit?: string, value?: string}
  --color: string # The color of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#color.
  --count: record # The number of products in a single package. For more information, see https://support.google.com/manufacturers/answer/6124116#count. — shape: {unit?: string, value?: string}
  --description: string # The description of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#description.
  --disclosure-date: string # The disclosure date of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#disclosure.
  --excluded-destination: list<string> # A list of excluded destinations such as "ClientExport", "ClientShoppingCatalog" or "PartnerShoppingCatalog". For more information, see https://support.google.com/manufacturers/answer/7443550
  --feature-description: list # The rich format description of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#featuredesc. — item shape: {headline?: string, image?: record, text?: string}
  --flavor: string # The flavor of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#flavor.
  --format: string # The format of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#format.
  --gender: string # The target gender of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#gender.
  --grocery: record # shape: {activeIngredients?: string, alcoholByVolume?: float, allergens?: string, derivedNutritionClaim?: list<string>, directions?: string, indications?: string, ingredients?: string, nutritionClaim?: list<string>, storageInstructions?: string}
  --gtin: list<string> # The Global Trade Item Number (GTIN) of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#gtin.
  --image-link: record # An image. — shape: {imageUrl?: string, status?: "STATUS_UNSPECIFIED"|"PENDING_PROCESSING"|"PENDING_CRAWL"|"OK"|"ROBOTED"|"XROBOTED"|"CRAWL_ERROR"|"PROCESSING_ERROR"|"DECODING_ERROR"|"TOO_BIG"|"CRAWL_SKIPPED"|"HOSTLOADED"|"HTTP_404", type?: "TYPE_UNSPECIFIED"|"CRAWLED"|"UPLOADED"}
  --included-destination: list<string> # A list of included destinations such as "ClientExport", "ClientShoppingCatalog" or "PartnerShoppingCatalog". For more information, see https://support.google.com/manufacturers/answer/7443550
  --item-group-id: string # The item group id of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#itemgroupid.
  --material: string # The material of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#material.
  --mpn: string # The Manufacturer Part Number (MPN) of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#mpn.
  --nutrition: record # shape: {addedSugars?: record, addedSugarsDailyPercentage?: float, calcium?: record, calciumDailyPercentage?: float, cholesterol?: record, cholesterolDailyPercentage?: float, dietaryFiber?: record, dietaryFiberDailyPercentage?: float, energy?: record, energyFromFat?: record, folateDailyPercentage?: float, folateFolicAcid?: record, folateMcgDfe?: float, iron?: record, ironDailyPercentage?: float, monounsaturatedFat?: record, nutritionFactMeasure?: string, polyols?: record, polyunsaturatedFat?: record, ... (24 more fields)}
  --pattern: string # The pattern of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#pattern.
  --product-detail: list # The details of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#productdetail. — item shape: {attributeName?: string, attributeValue?: string, sectionName?: string}
  --product-highlight: list<string> # The product highlights. For more information, see https://support.google.com/manufacturers/answer/10066942
  --product-line: string # The name of the group of products related to the product. For more information, see https://support.google.com/manufacturers/answer/6124116#productline.
  --product-name: string # The canonical name of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#productname.
  --product-page-url: string # The URL of the detail page of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#productpage.
  --product-type: list<string> # The type or category of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#producttype.
  --release-date: string # The release date of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#release.
  --rich-product-content: list<string> # Rich product content. For more information, see https://support.google.com/manufacturers/answer/9389865
  --scent: string # The scent of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#scent.
  --size: string # The size of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#size.
  --size-system: string # The size system of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#sizesystem.
  --size-type: list<string> # The size type of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#sizetype.
  --suggested-retail-price: record # A price. — shape: {amount?: string, currency?: string}
  --target-client-id: string # The target client id. Should only be used in the accounts of the data partners. For more information, see https://support.google.com/manufacturers/answer/10857344
  --theme: string # The theme of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#theme.
  --title: string # The title of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#title.
  --video-link: list<string> # The videos of the product. For more information, see https://support.google.com/manufacturers/answer/6124116#video.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent), name: (encode-path-segment $name)} | format pattern "/v1/{parent}/products/{name}") $qp)
  let req_body = {"additionalImageLink": $additional_image_link, "ageGroup": $age_group, "brand": $brand, "capacity": $capacity, "color": $color, "count": $count, "description": $description, "disclosureDate": $disclosure_date, "excludedDestination": $excluded_destination, "featureDescription": $feature_description, "flavor": $flavor, "format": $format, "gender": $gender, "grocery": $grocery, "gtin": $gtin, "imageLink": $image_link, "includedDestination": $included_destination, "itemGroupId": $item_group_id, "material": $material, "mpn": $mpn, "nutrition": $nutrition, "pattern": $pattern, "productDetail": $product_detail, "productHighlight": $product_highlight, "productLine": $product_line, "productName": $product_name, "productPageUrl": $product_page_url, "productType": $product_type, "releaseDate": $release_date, "richProductContent": $rich_product_content, "scent": $scent, "size": $size, "sizeSystem": $size_system, "sizeType": $size_type, "suggestedRetailPrice": $suggested_retail_price, "targetClientId": $target_client_id, "theme": $theme, "title": $title, "videoLink": $video_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
