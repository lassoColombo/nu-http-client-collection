# Auto-generated client for Cloud Private Catalog Producer vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/cloudprivatecatalogproducer/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN

const BASE_URL = "https://cloudprivatecatalogproducer.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_PRIVATE_CATALOG_PRODUCER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://cloudprivatecatalogproducer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json" "media" "proto"] }
def xgafv-completer [] { ["1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1-catalogs list" } } | get name | first)
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
export def "v1beta1-catalogs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of catalogs to return.
  --page-token: string # A pagination token returned from a previous call to ListCatalogs that indicates where this listing should continue from. This field is optional.
  --parent: string # The resource name of the parent resource.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/catalogs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "pageSize": $page_size, "pageToken": $page_token, "parent": $parent} | compact), body: null}
}

# Creates a new Catalog resource.
#
# POST /v1beta1/catalogs
# operationId: cloudprivatecatalogproducer.catalogs.create
export def "v1beta1-catalogs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --create-time: string # Output only. The time when the catalog was created. (format: google-datetime)
  --description: string # Required. The user-supplied description of the catalog. Maximum of 512 characters.
  --display-name: string # Required. The user-supplied descriptive name of the catalog as it appears in UIs. Maximum 256 characters in length.
  --name: string # Output only. The resource name of the catalog, in the format `catalogs/{catalog_id}'. A unique identifier for the catalog, which is generated by catalog service.
  --parent: string # Required. The parent resource name of the catalog, which can't be changed after a catalog is created. It can only be an organization. Values are of the form `//cloudresourcemanager.googleapis.com/organizations/`. Maximum 256 characters in length.
  --update-time: string # Output only. The time when the catalog was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/catalogs" $qp)
  let req_body = {"createTime": $create_time, "description": $description, "displayName": $display_name, "name": $name, "parent": $parent, "updateTime": $update_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`. NOTE: the `name` binding allows API services to override the binding to use different resource name schemes, such as `users/*/operations`. To override the binding, API services can add a binding such as `"/v1/{name=users/*}/operations"` to their service configuration. For backwards compatibility, the default name includes the operations collection id, however overriding users must ensure the name binding is the parent resource, without the operations collection id.
#
# GET /v1beta1/operations
# operationId: cloudprivatecatalogproducer.operations.list
export def "v1beta1-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # The standard list filter.
  --name: string # The name of the operation's parent resource.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/operations" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "filter": $filter, "name": $name, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Hard deletes a Version.
#
# DELETE /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.delete
export def "v1beta1 delete" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --force: oneof<nothing, bool> # Forces deletion of the `Catalog` and its `Association` resources. If the `Catalog` is still associated with other resources and force is not set to true, then the operation fails.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "force": $force} | compact), body: null}
}

# Returns the requested Version resource.
#
# GET /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.get
export def "v1beta1 get" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: null}
}

# Updates a specific Version resource.
#
# PATCH /v1beta1/{name}
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.patch
export def "v1beta1 update" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --update-mask: string # Field mask that controls which fields of the version should be updated.
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --create-time: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --body-name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'. A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length.
  --original-asset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as: ``` type: object properties: mainTemplate: type: string description: The file name of the main template and name prefix of schema file. The content of the main template should be set in the imports list. The schema file name is expected to be .schema in the imports list. required: true imports: type: array description: Import template and schema file contents. Required to have both and .schema files. required: true minItems: 2 items: type: object properties: name: type: string content: type: string ```
  --update-time: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let req_body = {"asset": $asset, "createTime": $create_time, "description": $description, "name": $body_name, "originalAsset": $original_asset, "updateTime": $update_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "updateMask": $update_mask} | compact), body: $req_body}
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1beta1/{name}:cancel
# operationId: cloudprivatecatalogproducer.operations.cancel
export def "v1beta1 cancel" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:cancel") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Copies a Product under another Catalog.
#
# POST /v1beta1/{name}:copy
# operationId: cloudprivatecatalogproducer.catalogs.products.copy
export def "v1beta1 copy" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --destination-product-name: string # The resource name of the destination product that is copied to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:copy") $qp)
  let req_body = {"destinationProductName": $destination_product_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Undeletes a deleted Catalog and all resources under it.
#
# POST /v1beta1/{name}:undelete
# operationId: cloudprivatecatalogproducer.catalogs.undelete
export def "v1beta1 create-undelete" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:undelete") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Lists all Association resources under a catalog.
#
# GET /v1beta1/{parent}/associations
# operationId: cloudprivatecatalogproducer.catalogs.associations.list
export def "v1beta1-associations list" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of catalog associations to return.
  --page-token: string # A pagination token returned from the previous call to `ListAssociations`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/associations") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates an Association instance under a given Catalog.
#
# POST /v1beta1/{parent}/associations
# operationId: cloudprivatecatalogproducer.catalogs.associations.create
# --association shape: {createTime?: string, name?: string, resource?: string}
export def "v1beta1-associations create" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --association: record # An association tuple that pairs a `Catalog` to a resource that can use the `Catalog`. After association, a google.cloud.privatecatalog.v1beta1.Catalog becomes available to consumers under specified Association.resource and all of its child nodes. Users who have the `cloudprivatecatalog.targets.get` permission on any of the resource nodes can access the catalog and child products under the node. For example, suppose the cloud resource hierarchy is as follows: * organizations/example.com * folders/team * projects/test After creating an association with `organizations/example.com`, the catalog `catalogs/1` is accessible from the following paths: * organizations/example.com * folders/team * projects/test Users can access them by google.cloud.v1beta1.PrivateCatalog.SearchCatalogs action. — shape: {createTime?: string, name?: string, resource?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/associations") $qp)
  let req_body = {"association": $association} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Lists Product resources that the producer has access to, within the scope of the parent catalog.
#
# GET /v1beta1/{parent}/products
# operationId: cloudprivatecatalogproducer.catalogs.products.list
export def "v1beta1-products list" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --filter: string # A filter expression used to restrict the returned results based upon properties of the product.
  --page-size: int # The maximum number of products to return.
  --page-token: string # A pagination token returned from a previous call to ListProducts that indicates where this listing should continue from. This field is optional.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/products") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates a Product instance under a given Catalog.
#
# POST /v1beta1/{parent}/products
# operationId: cloudprivatecatalogproducer.catalogs.products.create
export def "v1beta1-products create" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --asset-type: string # Required. The type of the product asset, which cannot be changed after the product is created. It supports the values `google.deploymentmanager.Template` and `google.cloudprivatecatalog.ListingOnly`. Other values will be rejected by the server. Read only after creation. The following fields or resource types have different validation rules under each `asset_type` values: * Product.display_metadata has different validation schema for each asset type value. See its comment for details. * Version resource isn't allowed to be added under the `google.cloudprivatecatalog.ListingOnly` type.
  --create-time: string # Output only. The time when the product was created. (format: google-datetime)
  --display-metadata: record # The user-supplied display metadata to describe the product. The JSON schema of the metadata differs by Product.asset_type. When the type is `google.deploymentmanager.Template`, the schema is as follows: ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties: name: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 tagline: type: string minLength: 1 maxLength: 100 support_info: type: string minLength: 1 maxLength: 2048 creator: type: string minLength: 1 maxLength: 100 documentation: type: array items: type: object properties: url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" title: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 required: - name - description additionalProperties: false ``` When the asset type is `google.cloudprivatecatalog.ListingOnly`, the schema is as follows: ``` "$schema": http://json-schema.org/draft-04/schema# type: object properties: name: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 tagline: type: string minLength: 1 maxLength: 100 support_info: type: string minLength: 1 maxLength: 2048 creator: type: string minLength: 1 maxLength: 100 documentation: type: array items: type: object properties: url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" title: type: string minLength: 1 maxLength: 64 description: type: string minLength: 1 maxLength: 2048 signup_url: type: string pattern: "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" required: - name - description - signup_url additionalProperties: false ```
  --icon-uri: string # Output only. The public accessible URI of the icon uploaded by PrivateCatalogProducer.UploadIcon. If no icon is uploaded, it will be the default icon's URI.
  --name: string # Required. The resource name of the product in the format `catalogs/{catalog_id}/products/a-z*[a-z0-9]'. A unique identifier for the product under a catalog, which cannot be changed after the product is created. The final segment of the name must between 1 and 256 characters in length.
  --update-time: string # Output only. The time when the product was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/products") $qp)
  let req_body = {"assetType": $asset_type, "createTime": $create_time, "displayMetadata": $display_metadata, "iconUri": $icon_uri, "name": $name, "updateTime": $update_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Lists Version resources that the producer has access to, within the scope of the parent Product.
#
# GET /v1beta1/{parent}/versions
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.list
export def "v1beta1-versions list" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --page-size: int # The maximum number of versions to return.
  --page-token: string # A pagination token returned from a previous call to ListVersions that indicates where this listing should continue from. This field is optional.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/versions") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates a Version instance under a given Product.
#
# POST /v1beta1/{parent}/versions
# operationId: cloudprivatecatalogproducer.catalogs.products.versions.create
export def "v1beta1-versions create" [
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
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --asset: record # Output only. The asset which has been validated and is ready to be provisioned. See Version.original_asset for the schema.
  --create-time: string # Output only. The time when the version was created. (format: google-datetime)
  --description: string # The user-supplied description of the version. Maximum of 256 characters.
  --name: string # Required. The resource name of the version, in the format `catalogs/{catalog_id}/products/{product_id}/versions/a-z*[a-z0-9]'. A unique identifier for the version under a product, which can't be changed after the version is created. The final segment of the name must between 1 and 63 characters in length.
  --original-asset: record # The user-supplied asset payload. The maximum size of the payload is 2MB. The JSON schema of the payload is defined as: ``` type: object properties: mainTemplate: type: string description: The file name of the main template and name prefix of schema file. The content of the main template should be set in the imports list. The schema file name is expected to be .schema in the imports list. required: true imports: type: array description: Import template and schema file contents. Required to have both and .schema files. required: true minItems: 2 items: type: object properties: name: type: string content: type: string ```
  --update-time: string # Output only. The time when the version was last updated. (format: google-datetime)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/versions") $qp)
  let req_body = {"asset": $asset, "createTime": $create_time, "description": $description, "name": $name, "originalAsset": $original_asset, "updateTime": $update_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Creates an Icon instance under a given Product. If Product only has a default icon, a new Icon instance is created and associated with the given Product. If Product already has a non-default icon, the action creates a new Icon instance, associates the newly created Icon with the given Product and deletes the old icon.
#
# POST /v1beta1/{product}/icons:upload
# operationId: cloudprivatecatalogproducer.catalogs.products.icons.upload
export def "v1beta1-icons-upload upload" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --icon: string # The raw icon bytes user-supplied to be uploaded to the product. The format of the icon can only be PNG or JPEG. The minimum allowed dimensions are 130x130 pixels and the maximum dimensions are 10000x10000 pixels. Required. (format: byte)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product | is-empty) { error make --unspanned { msg: "path parameter 'product' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product: (encode-path-segment $product)} | format pattern "/v1beta1/{product}/icons:upload") $qp)
  let req_body = {"icon": $icon} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Gets IAM policy for the specified Catalog.
#
# GET /v1beta1/{resource}:getIamPolicy
# operationId: cloudprivatecatalogproducer.catalogs.getIamPolicy
export def "v1beta1 get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --options-requested-policy-version: int # Optional. The policy format version to be returned. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "options.requestedPolicyVersion" $options_requested_policy_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:getIamPolicy") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "options.requestedPolicyVersion": $options_requested_policy_version} | compact), body: null}
}

# Sets the IAM policy for the specified Catalog.
#
# POST /v1beta1/{resource}:setIamPolicy
# operationId: cloudprivatecatalogproducer.catalogs.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "v1beta1 update-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": ["user:eve@example.com"], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= - version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: paths: "bindings, etag" This field is only used by Cloud IAM. (format: google-fieldmask)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:setIamPolicy") $qp)
  let req_body = {"policy": $policy, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}

# Tests the IAM permissions for the specified Catalog.
#
# POST /v1beta1/{resource}:testIamPermissions
# operationId: cloudprivatecatalogproducer.catalogs.testIamPermissions
export def "v1beta1 test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:testIamPermissions") $qp)
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback} | compact), body: $req_body}
}
