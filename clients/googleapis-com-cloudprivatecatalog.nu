# Auto-generated client for Cloud Private Catalog vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/cloudprivatecatalog/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_PRIVATE_CATALOG_TOKEN

const BASE_URL = "https://cloudprivatecatalog.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CLOUD_PRIVATE_CATALOG_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://cloudprivatecatalog.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1-catalogs-search list" } } | get name | first)
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

# Search Catalog resources that consumers have access to, within the scope of the consumer cloud resource hierarchy context.
#
# GET /v1beta1/{resource}/catalogs:search
# operationId: cloudprivatecatalog.organizations.catalogs.search
export def "v1beta1-catalogs-search list" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of entries that are requested.
  --page-token: string # A pagination token returned from a previous call to SearchCatalogs that indicates where this listing should continue from. This field is optional.
  --query: string # The query to filter the catalogs. The supported queries are: * Get a single catalog: `name=catalogs/{catalog_id}`
]: nothing -> record<catalogs: table<createTime: string, description: string, displayName: string, name: string, updateTime: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}/catalogs:search") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search Product resources that consumers have access to, within the scope of the consumer cloud resource hierarchy context.
#
# GET /v1beta1/{resource}/products:search
# operationId: cloudprivatecatalog.organizations.products.search
export def "v1beta1-products-search list" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of entries that are requested.
  --page-token: string # A pagination token returned from a previous call to SearchProducts that indicates where this listing should continue from. This field is optional.
  --query: string # The query to filter the products. The supported queries are: * List products of all catalogs: empty * List products under a catalog: `parent=catalogs/{catalog_id}` * Get a product by name: `name=catalogs/{catalog_id}/products/{product_id}`
]: nothing -> record<nextPageToken: string, products: table<assetType: string, createTime: string, displayMetadata: record, iconUri: string, name: string, updateTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}/products:search") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search Version resources that consumers have access to, within the scope of the consumer cloud resource hierarchy context.
#
# GET /v1beta1/{resource}/versions:search
# operationId: cloudprivatecatalog.organizations.versions.search
export def "v1beta1-versions-search list" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --callback: string # JSONP
  --alt: string@alt-completer # Data format for response. (default: json)
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --access-token: string # OAuth access token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of entries that are requested.
  --page-token: string # A pagination token returned from a previous call to SearchVersions that indicates where this listing should continue from. This field is optional.
  --query: string # The query to filter the versions. Required. The supported queries are: * List versions under a product: `parent=catalogs/{catalog_id}/products/{product_id}` * Get a version by name: `name=catalogs/{catalog_id}/products/{product_id}/versions/{version_id}`
]: nothing -> record<nextPageToken: string, versions: table<asset: record, createTime: string, description: string, name: string, updateTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_PRIVATE_CATALOG_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}/versions:search") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "oauth_token": $oauth_token, "callback": $callback, "alt": $alt, "key": $key, "access_token": $access_token, "upload_protocol": $upload_protocol, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "fields": $fields, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
