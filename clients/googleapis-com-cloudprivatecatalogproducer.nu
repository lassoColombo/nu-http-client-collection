# Auto-generated client for Cloud Private Catalog Producer vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/cloudprivatecatalogproducer/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN

const BASE_URL = "https://cloudprivatecatalogproducer.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN | default "" }
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

def base-url-completer [] { ["https://cloudprivatecatalogproducer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json" "media" "proto"] }
def xgafv-completer [] { ["1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1-catalogs cloudprivatecatalogproducercatalogslist" } } | get name | first)
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

# Lists Catalog resources that the producer has access to, within the scope of the parent resource.
#
# GET /v1beta1/catalogs
# operationId: cloudprivatecatalogproducer.catalogs.list
export def "v1beta1-catalogs cloudprivatecatalogproducercatalogslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --pageSize: int # The maximum number of catalogs to return.
  --pageToken: string # A pagination token returned from a previous call to ListCatalogs that indicates where this listing should continue from. This field is optional.
  --parent: string # The resource name of the parent resource.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/catalogs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Catalog resource.
#
# POST /v1beta1/catalogs
# operationId: cloudprivatecatalogproducer.catalogs.create
export def "v1beta1-catalogs cloudprivatecatalogproducercatalogscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --createTime: string # Output only. The time when the catalog was created. (format: google-datetime)
  --description: string # Required. The user-supplied description of the catalog. Maximum of 512 characters.
  --displayName: string # Required. The user-supplied descriptive name of the catalog as it appears in UIs. Maximum 256 characters in length.
  --name: string # Output only. The resource name of the catalog, in the format `catalogs/{catalog_id}'.  A unique identifier for the catalog, which is generated by catalog service.
  --parent: string # Required. The parent resource name of the catalog, which can't be changed after a catalog is created. It can only be an organization. Values are of the form `//cloudresourcemanager.googleapis.com/organizations/<id>`. Maximum 256 characters in length.
  --updateTime: string # Output only. The time when the catalog was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/catalogs" $qp)
  let body = {createTime: $createTime, description: $description, displayName: $displayName, name: $name, parent: $parent, updateTime: $updateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.  NOTE: the `name` binding allows API services to override the binding to use different resource name schemes, such as `users/*/operations`. To override the binding, API services can add a binding such as `"/v1/{name=users/*}/operations"` to their service configuration. For backwards compatibility, the default name includes the operations collection id, however overriding users must ensure the name binding is the parent resource, without the operations collection id.
#
# GET /v1beta1/operations
# operationId: cloudprivatecatalogproducer.operations.list
export def "v1beta1-operations cloudprivatecatalogproduceroperationslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # The standard list filter.
  --name: string # The name of the operation's parent resource.
  --pageSize: int # The standard list page size.
  --pageToken: string # The standard list page token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/operations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Hard deletes a Version.
#
# DELETE /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.delete
export def "v1beta1 cloudprivatecatalogproducercatalogsproductsversionsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --force: oneof<nothing, bool> # Forces deletion of the `Catalog` and its `Association` resources. If the `Catalog` is still associated with other resources and force is not set to true, then the operation fails.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the requested Version resource.
#
# GET /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.get
export def "v1beta1 cloudprivatecatalogproducercatalogsproductsversionsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific Version resource.
#
# PATCH /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.patch
export def "v1beta1 cloudprivatecatalogproducercatalogsproductsversionspatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --updateMask: string # Field mask that controls which fields of the version should be updated.
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --createTime: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --body-name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'.  A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length.
  --originalAsset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as:  ``` type: object properties:   mainTemplate:     type: string     description: The file name of the main template and name prefix of     schema file. The content of the main template should be set in the     imports list. The schema file name is expected to be     <mainTemplate>.schema in the imports list. required: true   imports:     type: array     description: Import template and schema file contents. Required to have     both <mainTemplate> and <mainTemplate>.schema files. required: true     minItems: 2     items:       type: object       properties:         name:           type: string         content:           type: string ```
  --updateTime: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let body = {asset: $asset, createTime: $createTime, description: $description, name: $body_name, originalAsset: $originalAsset, updateTime: $updateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts asynchronous cancellation on a long-running operation.  The server makes a best effort to cancel the operation, but success is not guaranteed.  If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.  Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1beta1/{name}:cancel
# operationId: cloudprivatecatalogproducer.operations.cancel
export def "v1beta1 cloudprivatecatalogproduceroperationscancel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name):cancel" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copies a Product under another Catalog.
#
# POST /v1beta1/{name}:copy
# operationId: cloudprivatecatalogproducer.catalogs.products.copy
export def "v1beta1 cloudprivatecatalogproducercatalogsproductscopy" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --destinationProductName: string # The resource name of the destination product that is copied to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name):copy" $qp)
  let body = {destinationProductName: $destinationProductName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Undeletes a deleted Catalog and all resources under it.
#
# POST /v1beta1/{name}:undelete
# operationId: cloudprivatecatalogproducer.catalogs.undelete
export def "v1beta1 cloudprivatecatalogproducercatalogsundelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name):undelete" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Association resources under a catalog.
#
# GET /v1beta1/{parent}/associations
# operationId: cloudprivatecatalogproducer.catalogs.associations.list
export def "v1beta1-associations cloudprivatecatalogproducercatalogsassociationslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --pageSize: int # The maximum number of catalog associations to return.
  --pageToken: string # A pagination token returned from the previous call to `ListAssociations`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/associations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an Association instance under a given Catalog.
#
# POST /v1beta1/{parent}/associations
# operationId: cloudprivatecatalogproducer.catalogs.associations.create
# --association shape: {createTime?: string, name?: string, resource?: string}
export def "v1beta1-associations cloudprivatecatalogproducercatalogsassociationscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --association: record # An association tuple that pairs a `Catalog` to a resource that can use the `Catalog`. After association, a google.cloud.privatecatalog.v1beta1.Catalog becomes available to consumers under specified Association.resource and all of its child nodes. Users who have the `cloudprivatecatalog.targets.get` permission on any of the resource nodes can access the catalog and child products under the node.  For example, suppose the cloud resource hierarchy is as follows:  * organizations/example.com   * folders/team     * projects/test  After creating an association with `organizations/example.com`, the catalog `catalogs/1`  is accessible from the following paths:  * organizations/example.com * folders/team * projects/test  Users can access them by google.cloud.v1beta1.PrivateCatalog.SearchCatalogs action. — shape: {createTime?: string, name?: string, resource?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/associations" $qp)
  let body = {association: $association} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Product resources that the producer has access to, within the scope of the parent catalog.
#
# GET /v1beta1/{parent}/products
# operationId: cloudprivatecatalogproducer.catalogs.products.list
export def "v1beta1-products cloudprivatecatalogproducercatalogsproductslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # A filter expression used to restrict the returned results based upon properties of the product.
  --pageSize: int # The maximum number of products to return.
  --pageToken: string # A pagination token returned from a previous call to ListProducts that indicates where this listing should continue from. This field is optional.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/products" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Product instance under a given Catalog.
#
# POST /v1beta1/{parent}/products
# operationId: cloudprivatecatalogproducer.catalogs.products.create
export def "v1beta1-products cloudprivatecatalogproducercatalogsproductscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --assetType: string # Required. The type of the product asset, which cannot be changed after the product is created. It supports the values `google.deploymentmanager.Template` and `google.cloudprivatecatalog.ListingOnly`. Other values will be rejected by the server. Read only after creation.  The following fields or resource types have different validation rules under each `asset_type` values:  * Product.display_metadata has different validation schema for each asset type value. See its comment for details. * Version resource isn't allowed to be added under the `google.cloudprivatecatalog.ListingOnly` type.
  --createTime: string # Output only. The time when the product was created. (format: google-datetime)
  --displayMetadata: record # The user-supplied display metadata to describe the product. The JSON schema of the metadata differs by Product.asset_type. When the type is `google.deploymentmanager.Template`, the schema is as follows:  ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties:   name:     type: string     minLength: 1     maxLength: 64   description:     type: string     minLength: 1     maxLength: 2048   tagline:     type: string     minLength: 1     maxLength: 100   support_info:     type: string     minLength: 1     maxLength: 2048   creator:     type: string     minLength: 1     maxLength: 100   documentation:     type: array     items:       type: object       properties:         url:           type: string           pattern:           "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]"         title:           type: string           minLength: 1           maxLength: 64         description:           type: string           minLength: 1           maxLength: 2048 required: - name - description additionalProperties: false  ```  When the asset type is `google.cloudprivatecatalog.ListingOnly`, the schema is as follows:  ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties:   name:     type: string     minLength: 1     maxLength: 64   description:     type: string     minLength: 1     maxLength: 2048   tagline:     type: string     minLength: 1     maxLength: 100   support_info:     type: string     minLength: 1     maxLength: 2048   creator:     type: string     minLength: 1     maxLength: 100   documentation:     type: array     items:       type: object       properties:         url:           type: string           pattern:           "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]"         title:           type: string           minLength: 1           maxLength: 64         description:           type: string           minLength: 1           maxLength: 2048   signup_url:     type: string     pattern:     "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" required: - name - description - signup_url additionalProperties: false ```
  --iconUri: string # Output only. The public accessible URI of the icon uploaded by PrivateCatalogProducer.UploadIcon.  If no icon is uploaded, it will be the default icon's URI.
  --name: string # Required. The resource name of the product in the format `catalogs/{catalog_id}/products/a-z*[a-z0-9]'.  A unique identifier for the product under a catalog, which cannot be changed after the product is created. The final segment of the name must between 1 and 256 characters in length.
  --updateTime: string # Output only. The time when the product was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/products" $qp)
  let body = {assetType: $assetType, createTime: $createTime, displayMetadata: $displayMetadata, iconUri: $iconUri, name: $name, updateTime: $updateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Version resources that the producer has access to, within the scope of the parent Product.
#
# GET /v1beta1/{parent}/versions
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.list
export def "v1beta1-versions cloudprivatecatalogproducercatalogsproductsversionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --pageSize: int # The maximum number of versions to return.
  --pageToken: string # A pagination token returned from a previous call to ListVersions that indicates where this listing should continue from. This field is optional.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/versions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Version instance under a given Product.
#
# POST /v1beta1/{parent}/versions
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.create
export def "v1beta1-versions cloudprivatecatalogproducercatalogsproductsversionscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --createTime: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'.  A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length.
  --originalAsset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as:  ``` type: object properties:   mainTemplate:     type: string     description: The file name of the main template and name prefix of     schema file. The content of the main template should be set in the     imports list. The schema file name is expected to be     <mainTemplate>.schema in the imports list. required: true   imports:     type: array     description: Import template and schema file contents. Required to have     both <mainTemplate> and <mainTemplate>.schema files. required: true     minItems: 2     items:       type: object       properties:         name:           type: string         content:           type: string ```
  --updateTime: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/versions" $qp)
  let body = {asset: $asset, createTime: $createTime, description: $description, name: $name, originalAsset: $originalAsset, updateTime: $updateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Icon instance under a given Product. If Product only has a default icon, a new Icon instance is created and associated with the given Product. If Product already has a non-default icon, the action creates a new Icon instance, associates the newly created Icon with the given Product and deletes the old icon.
#
# POST /v1beta1/{product}/icons:upload
# operationId: cloudprivatecatalogproducer.catalogs.products.icons.upload
export def "v1beta1-icons-upload cloudprivatecatalogproducercatalogsproductsiconsupload" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --icon: string # The raw icon bytes user-supplied to be uploaded to the product. The format of the icon can only be PNG or JPEG. The minimum allowed dimensions are 130x130 pixels and the maximum dimensions are 10000x10000 pixels. Required. (format: byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($product)/icons:upload" $qp)
  let body = {icon: $icon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets IAM policy for the specified Catalog.
#
# GET /v1beta1/{resource}:getIamPolicy
# operationId: cloudprivatecatalogproducer.catalogs.getIamPolicy
export def "v1beta1 cloudprivatecatalogproducercatalogsgetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --optionsrequestedPolicyVersion: int # Optional. The policy format version to be returned.  Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected.  Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "options.requestedPolicyVersion" $optionsrequestedPolicyVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):getIamPolicy" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the IAM policy for the specified Catalog.
#
# POST /v1beta1/{resource}:setIamPolicy
# operationId: cloudprivatecatalogproducer.catalogs.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "v1beta1 cloudprivatecatalogproducercatalogssetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources.   A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role.  Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both.  **JSON example:**      {       "bindings": [         {           "role": "roles/resourcemanager.organizationAdmin",           "members": [             "user:mike@example.com",             "group:admins@example.com",             "domain:google.com",             "serviceAccount:my-project-id@appspot.gserviceaccount.com"           ]         },         {           "role": "roles/resourcemanager.organizationViewer",           "members": ["user:eve@example.com"],           "condition": {             "title": "expirable access",             "description": "Does not grant access after Sep 2020",             "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')",           }         }       ],       "etag": "BwWWja0YfJA=",       "version": 3     }  **YAML example:**      bindings:     - members:       - user:mike@example.com       - group:admins@example.com       - domain:google.com       - serviceAccount:my-project-id@appspot.gserviceaccount.com       role: roles/resourcemanager.organizationAdmin     - members:       - user:eve@example.com       role: roles/resourcemanager.organizationViewer       condition:         title: expirable access         description: Does not grant access after Sep 2020         expression: request.time < timestamp('2020-10-01T00:00:00.000Z')     - etag: BwWWja0YfJA=     - version: 3  For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --updateMask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: paths: "bindings, etag" This field is only used by Cloud IAM. (format: google-fieldmask)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):setIamPolicy" $qp)
  let body = {policy: $policy, updateMask: $updateMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tests the IAM permissions for the specified Catalog.
#
# POST /v1beta1/{resource}:testIamPermissions
# operationId: cloudprivatecatalogproducer.catalogs.testIamPermissions
export def "v1beta1 cloudprivatecatalogproducercatalogstestIamPermissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --permissions: list # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):testIamPermissions" $qp)
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
