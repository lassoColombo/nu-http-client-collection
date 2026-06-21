# Auto-generated client for App Engine Admin API vv1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/appengine/v1beta/openapi.json
# Auth: --token flag or $env.APP_ENGINE_ADMIN_API_TOKEN

const BASE_URL = "https://appengine.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APP_ENGINE_ADMIN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://appengine.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def database-type-completer [] { ["CLOUD_DATASTORE" "CLOUD_DATASTORE_COMPATIBILITY" "CLOUD_FIRESTORE" "DATABASE_TYPE_UNSPECIFIED"] }
def serving-status-completer [] { ["SERVING" "SYSTEM_DISABLED" "UNSPECIFIED" "USER_DISABLED"] }
def view-completer [] { ["BASIC_CERTIFICATE" "FULL_CERTIFICATE"] }
def override-strategy-completer [] { ["OVERRIDE" "STRICT" "UNSPECIFIED_DOMAIN_OVERRIDE_STRATEGY"] }
def action-completer [] { ["ALLOW" "DENY" "UNSPECIFIED_ACTION"] }
def view-completer-1 [] { ["BASIC" "FULL"] }
def serving-status-completer-1 [] { ["SERVING" "SERVING_STATUS_UNSPECIFIED" "STOPPED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta-apps create" } } | get name | first)
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

# Creates an App Engine application for a Google Cloud Platform project. Required fields: id - The ID of the target Cloud Platform project. location - The region (https://cloud.google.com/appengine/docs/locations) where you want the App Engine application located.For more information about App Engine applications, see Managing Projects, Applications, and Billing (https://cloud.google.com/appengine/docs/standard/python/console/).
#
# POST /v1beta/apps
# operationId: appengine.apps.create
# --dispatchRules item shape: {domain?: string, path?: string, service?: string}
# --featureSettings shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
# --iap shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
export def "v1beta-apps create" [
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
  --parent: string # The project and location in which the application should be created, specified in the format projects/*/locations/*
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta/apps" $qp)
  let req_body = {"authDomain": $auth_domain, "databaseType": $database_type, "defaultCookieExpiration": $default_cookie_expiration, "dispatchRules": $dispatch_rules, "featureSettings": $feature_settings, "iap": $iap, "id": $id, "locationId": $location_id, "serviceAccount": $service_account, "servingStatus": $serving_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "parent": $parent} | compact), body: $req_body}
}

# Gets information about an application.
#
# GET /v1beta/apps/{appsId}
# operationId: appengine.apps.get
export def "v1beta-apps get" [
  apps_id: string
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
]: nothing -> record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates the specified Application resource. You can update the following fields: auth_domain - Google authentication domain for controlling user access to the application. default_cookie_expiration - Cookie expiration policy for the application. iap - Identity-Aware Proxy properties for the application.
#
# PATCH /v1beta/apps/{appsId}
# operationId: appengine.apps.patch
# --dispatchRules item shape: {domain?: string, path?: string, service?: string}
# --featureSettings shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
# --iap shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
export def "v1beta-apps update" [
  apps_id: string
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
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}") $qp)
  let req_body = {"authDomain": $auth_domain, "databaseType": $database_type, "defaultCookieExpiration": $default_cookie_expiration, "dispatchRules": $dispatch_rules, "featureSettings": $feature_settings, "iap": $iap, "id": $id, "locationId": $location_id, "serviceAccount": $service_account, "servingStatus": $serving_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists all SSL certificates the user is authorized to administer.
#
# GET /v1beta/apps/{appsId}/authorizedCertificates
# operationId: appengine.apps.authorizedCertificates.list
export def "v1beta-apps-authorized-certificates list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
  --view: string@view-completer # Controls the set of fields returned in the LIST response.
]: nothing -> record<certificates: table<certificateRawData: record, displayName: string, domainMappingsCount: int, domainNames: list, expireTime: string, id: string, managedCertificate: record, name: string, visibleDomainMappings: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedCertificates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact), body: null}
}

# Uploads the specified SSL certificate.
#
# POST /v1beta/apps/{appsId}/authorizedCertificates
# operationId: appengine.apps.authorizedCertificates.create
# --certificateRawData shape: {privateKey?: string, publicCertificate?: string}
# --managedCertificate shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
export def "v1beta-apps-authorized-certificates create" [
  apps_id: string
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
  --certificate-raw-data: record # An SSL certificate obtained from a certificate authority. — shape: {privateKey?: string, publicCertificate?: string}
  --display-name: string # The user-specified display name of the certificate. This is not guaranteed to be unique. Example: My Certificate.
  --domain-mappings-count: int # Aggregate count of the domain mappings with this certificate mapped. This count includes domain mappings on applications for which the user does not have VIEWER permissions.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly (format: int32)
  --domain-names: list<string> # Topmost applicable domains of this certificate. This certificate applies to these domains and their subdomains. Example: example.com.@OutputOnly
  --expire-time: string # The time when this certificate expires. To update the renewal time on this certificate, upload an SSL certificate with a different expiration time using AuthorizedCertificates.UpdateAuthorizedCertificate.@OutputOnly (format: google-datetime)
  --id: string # Relative name of the certificate. This is a unique value autogenerated on AuthorizedCertificate resource creation. Example: 12345.@OutputOnly
  --managed-certificate: record # A certificate managed by App Engine. — shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
  --name: string # Full path to the AuthorizedCertificate resource in the API. Example: apps/myapp/authorizedCertificates/12345.@OutputOnly
  --visible-domain-mappings: list<string> # The full paths to user visible Domain Mapping resources that have this certificate mapped. Example: apps/myapp/domainMappings/example.com.This may not represent the full list of mapped domain mappings if the user does not have VIEWER permissions on all of the applications that have this certificate mapped. See domain_mappings_count for a complete count.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly
]: any -> record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedCertificates") $qp)
  let req_body = {"certificateRawData": $certificate_raw_data, "displayName": $display_name, "domainMappingsCount": $domain_mappings_count, "domainNames": $domain_names, "expireTime": $expire_time, "id": $id, "managedCertificate": $managed_certificate, "name": $name, "visibleDomainMappings": $visible_domain_mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes the specified SSL certificate.
#
# DELETE /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# operationId: appengine.apps.authorizedCertificates.delete
export def "v1beta-apps-authorized-certificates delete" [
  apps_id: string
  authorized_certificates_id: string
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
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($authorized_certificates_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizedCertificatesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), authorized_certificates_id: (encode-path-segment $authorized_certificates_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedCertificates/{authorized_certificates_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the specified SSL certificate.
#
# GET /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# operationId: appengine.apps.authorizedCertificates.get
export def "v1beta-apps-authorized-certificates get" [
  apps_id: string
  authorized_certificates_id: string
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
  --view: string@view-completer # Controls the set of fields returned in the GET response.
]: nothing -> record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($authorized_certificates_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizedCertificatesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), authorized_certificates_id: (encode-path-segment $authorized_certificates_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedCertificates/{authorized_certificates_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "view": $view} | compact), body: null}
}

# Updates the specified SSL certificate. To renew a certificate and maintain its existing domain mappings, update certificate_data with a new certificate. The new certificate must be applicable to the same domains as the original certificate. The certificate display_name may also be updated.
#
# PATCH /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# operationId: appengine.apps.authorizedCertificates.patch
# --certificateRawData shape: {privateKey?: string, publicCertificate?: string}
# --managedCertificate shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
export def "v1beta-apps-authorized-certificates update" [
  apps_id: string
  authorized_certificates_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated. Updates are only supported on the certificate_raw_data and display_name fields.
  --certificate-raw-data: record # An SSL certificate obtained from a certificate authority. — shape: {privateKey?: string, publicCertificate?: string}
  --display-name: string # The user-specified display name of the certificate. This is not guaranteed to be unique. Example: My Certificate.
  --domain-mappings-count: int # Aggregate count of the domain mappings with this certificate mapped. This count includes domain mappings on applications for which the user does not have VIEWER permissions.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly (format: int32)
  --domain-names: list<string> # Topmost applicable domains of this certificate. This certificate applies to these domains and their subdomains. Example: example.com.@OutputOnly
  --expire-time: string # The time when this certificate expires. To update the renewal time on this certificate, upload an SSL certificate with a different expiration time using AuthorizedCertificates.UpdateAuthorizedCertificate.@OutputOnly (format: google-datetime)
  --id: string # Relative name of the certificate. This is a unique value autogenerated on AuthorizedCertificate resource creation. Example: 12345.@OutputOnly
  --managed-certificate: record # A certificate managed by App Engine. — shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
  --name: string # Full path to the AuthorizedCertificate resource in the API. Example: apps/myapp/authorizedCertificates/12345.@OutputOnly
  --visible-domain-mappings: list<string> # The full paths to user visible Domain Mapping resources that have this certificate mapped. Example: apps/myapp/domainMappings/example.com.This may not represent the full list of mapped domain mappings if the user does not have VIEWER permissions on all of the applications that have this certificate mapped. See domain_mappings_count for a complete count.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly
]: any -> record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($authorized_certificates_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizedCertificatesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), authorized_certificates_id: (encode-path-segment $authorized_certificates_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedCertificates/{authorized_certificates_id}") $qp)
  let req_body = {"certificateRawData": $certificate_raw_data, "displayName": $display_name, "domainMappingsCount": $domain_mappings_count, "domainNames": $domain_names, "expireTime": $expire_time, "id": $id, "managedCertificate": $managed_certificate, "name": $name, "visibleDomainMappings": $visible_domain_mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists all domains the user is authorized to administer.
#
# GET /v1beta/apps/{appsId}/authorizedDomains
# operationId: appengine.apps.authorizedDomains.list
export def "v1beta-apps-authorized-domains list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<domains: table<id: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/authorizedDomains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Lists the domain mappings on an application.
#
# GET /v1beta/apps/{appsId}/domainMappings
# operationId: appengine.apps.domainMappings.list
export def "v1beta-apps-domain-mappings list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<domainMappings: table<id: string, name: string, resourceRecords: list, sslSettings: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/domainMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Maps a domain to an application. A user must be authorized to administer a domain in order to map it to an application. For a list of available authorized domains, see AuthorizedDomains.ListAuthorizedDomains.
#
# POST /v1beta/apps/{appsId}/domainMappings
# operationId: appengine.apps.domainMappings.create
# --resourceRecords item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
# --sslSettings shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
export def "v1beta-apps-domain-mappings create" [
  apps_id: string
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
  --override-strategy: string@override-strategy-completer # Whether the domain creation should override any existing mappings for this domain. By default, overrides are rejected.
  --id: string # Relative name of the domain serving the application. Example: example.com.
  --name: string # Full path to the DomainMapping resource in the API. Example: apps/myapp/domainMapping/example.com.@OutputOnly
  --resource-records: list # The resource records required to configure this domain mapping. These records must be added to the domain's DNS configuration in order to serve the application via this domain mapping.@OutputOnly — item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
  --ssl-settings: record # SSL configuration for a DomainMapping resource. — shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "overrideStrategy" $override_strategy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/domainMappings") $qp)
  let req_body = {"id": $id, "name": $name, "resourceRecords": $resource_records, "sslSettings": $ssl_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "overrideStrategy": $override_strategy} | compact), body: $req_body}
}

# Deletes the specified domain mapping. A user must be authorized to administer the associated domain in order to delete a DomainMapping resource.
#
# DELETE /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# operationId: appengine.apps.domainMappings.delete
export def "v1beta-apps-domain-mappings delete" [
  apps_id: string
  domain_mappings_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($domain_mappings_id | is-empty) { error make --unspanned { msg: "path parameter 'domainMappingsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), domain_mappings_id: (encode-path-segment $domain_mappings_id)} | format pattern "/v1beta/apps/{apps_id}/domainMappings/{domain_mappings_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the specified domain mapping.
#
# GET /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# operationId: appengine.apps.domainMappings.get
export def "v1beta-apps-domain-mappings get" [
  apps_id: string
  domain_mappings_id: string
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
]: nothing -> record<id: string, name: string, resourceRecords: table<name: string, rrdata: string, type: string>, sslSettings: record<certificateId: string, pendingManagedCertificateId: string, sslManagementType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($domain_mappings_id | is-empty) { error make --unspanned { msg: "path parameter 'domainMappingsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), domain_mappings_id: (encode-path-segment $domain_mappings_id)} | format pattern "/v1beta/apps/{apps_id}/domainMappings/{domain_mappings_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates the specified domain mapping. To map an SSL certificate to a domain mapping, update certificate_id to point to an AuthorizedCertificate resource. A user must be authorized to administer the associated domain in order to update a DomainMapping resource.
#
# PATCH /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# operationId: appengine.apps.domainMappings.patch
# --resourceRecords item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
# --sslSettings shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
export def "v1beta-apps-domain-mappings update" [
  apps_id: string
  domain_mappings_id: string
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
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --id: string # Relative name of the domain serving the application. Example: example.com.
  --name: string # Full path to the DomainMapping resource in the API. Example: apps/myapp/domainMapping/example.com.@OutputOnly
  --resource-records: list # The resource records required to configure this domain mapping. These records must be added to the domain's DNS configuration in order to serve the application via this domain mapping.@OutputOnly — item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
  --ssl-settings: record # SSL configuration for a DomainMapping resource. — shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($domain_mappings_id | is-empty) { error make --unspanned { msg: "path parameter 'domainMappingsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), domain_mappings_id: (encode-path-segment $domain_mappings_id)} | format pattern "/v1beta/apps/{apps_id}/domainMappings/{domain_mappings_id}") $qp)
  let req_body = {"id": $id, "name": $name, "resourceRecords": $resource_records, "sslSettings": $ssl_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists the firewall rules of an application.
#
# GET /v1beta/apps/{appsId}/firewall/ingressRules
# operationId: appengine.apps.firewall.ingressRules.list
export def "v1beta-apps-firewall-ingress-rules list" [
  apps_id: string
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
  --matching-address: string # A valid IP Address. If set, only rules matching this address will be returned. The first returned rule will be the rule that fires on requests from this IP.
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "matchingAddress" $matching_address "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "matchingAddress": $matching_address, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates a firewall rule for the application.
#
# POST /v1beta/apps/{appsId}/firewall/ingressRules
# operationId: appengine.apps.firewall.ingressRules.create
export def "v1beta-apps-firewall-ingress-rules create" [
  apps_id: string
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
  --action: string@action-completer # The action to take on matched requests.
  --description: string # An optional string description of this rule. This field has a maximum length of 400 characters.
  --priority: int # A positive integer between 1, Int32.MaxValue-1 that defines the order of rule evaluation. Rules with the lowest priority are evaluated first.A default rule at priority Int32.MaxValue matches all IPv4 and IPv6 traffic when no previous rule matches. Only the action of this rule can be modified by the user. (format: int32)
  --source-range: string # IP address or range, defined using CIDR notation, of requests that this rule applies to. You can use the wildcard character "*" to match all IPs equivalent to "0/0" and "::/0" together. Examples: 192.168.1.1 or 192.168.0.0/16 or 2001:db8::/32 or 2001:0db8:0000:0042:0000:8a2e:0370:7334. Truncation will be silently performed on addresses which are not properly truncated. For example, 1.2.3.4/24 is accepted as the same address as 1.2.3.0/24. Similarly, for IPv6, 2001:db8::1/32 is accepted as the same address as 2001:db8::/32.
]: any -> record<action: string, description: string, priority: int, sourceRange: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules") $qp)
  let req_body = {"action": $action, "description": $description, "priority": $priority, "sourceRange": $source_range} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes the specified firewall rule.
#
# DELETE /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# operationId: appengine.apps.firewall.ingressRules.delete
export def "v1beta-apps-firewall-ingress-rules delete" [
  apps_id: string
  ingress_rules_id: string
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
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($ingress_rules_id | is-empty) { error make --unspanned { msg: "path parameter 'ingressRulesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), ingress_rules_id: (encode-path-segment $ingress_rules_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules/{ingress_rules_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the specified firewall rule.
#
# GET /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# operationId: appengine.apps.firewall.ingressRules.get
export def "v1beta-apps-firewall-ingress-rules get" [
  apps_id: string
  ingress_rules_id: string
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
]: nothing -> record<action: string, description: string, priority: int, sourceRange: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($ingress_rules_id | is-empty) { error make --unspanned { msg: "path parameter 'ingressRulesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), ingress_rules_id: (encode-path-segment $ingress_rules_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules/{ingress_rules_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates the specified firewall rule.
#
# PATCH /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# operationId: appengine.apps.firewall.ingressRules.patch
export def "v1beta-apps-firewall-ingress-rules update" [
  apps_id: string
  ingress_rules_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated.
  --action: string@action-completer # The action to take on matched requests.
  --description: string # An optional string description of this rule. This field has a maximum length of 400 characters.
  --priority: int # A positive integer between 1, Int32.MaxValue-1 that defines the order of rule evaluation. Rules with the lowest priority are evaluated first.A default rule at priority Int32.MaxValue matches all IPv4 and IPv6 traffic when no previous rule matches. Only the action of this rule can be modified by the user. (format: int32)
  --source-range: string # IP address or range, defined using CIDR notation, of requests that this rule applies to. You can use the wildcard character "*" to match all IPs equivalent to "0/0" and "::/0" together. Examples: 192.168.1.1 or 192.168.0.0/16 or 2001:db8::/32 or 2001:0db8:0000:0042:0000:8a2e:0370:7334. Truncation will be silently performed on addresses which are not properly truncated. For example, 1.2.3.4/24 is accepted as the same address as 1.2.3.0/24. Similarly, for IPv6, 2001:db8::1/32 is accepted as the same address as 2001:db8::/32.
]: any -> record<action: string, description: string, priority: int, sourceRange: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($ingress_rules_id | is-empty) { error make --unspanned { msg: "path parameter 'ingressRulesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), ingress_rules_id: (encode-path-segment $ingress_rules_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules/{ingress_rules_id}") $qp)
  let req_body = {"action": $action, "description": $description, "priority": $priority, "sourceRange": $source_range} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Replaces the entire firewall ruleset in one bulk operation. This overrides and replaces the rules of an existing firewall with the new rules.If the final rule does not match traffic with the '*' wildcard IP range, then an "allow all" rule is explicitly added to the end of the list.
#
# POST /v1beta/apps/{appsId}/firewall/ingressRules:batchUpdate
# operationId: appengine.apps.firewall.ingressRules.batchUpdate
# --ingressRules item shape: {action?: "UNSPECIFIED_ACTION"|"ALLOW"|"DENY", description?: string, priority?: int, sourceRange?: string}
export def "v1beta-apps-firewall-ingress-rules-batch-update update" [
  apps_id: string
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
  --ingress-rules: list # A list of FirewallRules to replace the existing set. — item shape: {action?: "UNSPECIFIED_ACTION"|"ALLOW"|"DENY", description?: string, priority?: int, sourceRange?: string}
]: any -> record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/firewall/ingressRules:batchUpdate") $qp)
  let req_body = {"ingressRules": $ingress_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists information about the supported locations for this service.
#
# GET /v1beta/apps/{appsId}/locations
# operationId: appengine.apps.locations.list
export def "v1beta-apps-locations list" [
  apps_id: string
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
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like "displayName=tokyo", and is documented in more detail in AIP-160 (https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the next_page_token field in the response. Send that page token to receive the subsequent page.
]: nothing -> record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/locations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets information about a location.
#
# GET /v1beta/apps/{appsId}/locations/{locationsId}
# operationId: appengine.apps.locations.get
export def "v1beta-apps-locations get" [
  apps_id: string
  locations_id: string
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
]: nothing -> record<displayName: string, labels: record, locationId: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), locations_id: (encode-path-segment $locations_id)} | format pattern "/v1beta/apps/{apps_id}/locations/{locations_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns UNIMPLEMENTED.
#
# GET /v1beta/apps/{appsId}/operations
# operationId: appengine.apps.operations.list
export def "v1beta-apps-operations list" [
  apps_id: string
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
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1beta/apps/{appsId}/operations/{operationsId}
# operationId: appengine.apps.operations.get
export def "v1beta-apps-operations get" [
  apps_id: string
  operations_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($operations_id | is-empty) { error make --unspanned { msg: "path parameter 'operationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), operations_id: (encode-path-segment $operations_id)} | format pattern "/v1beta/apps/{apps_id}/operations/{operations_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all the services in the application.
#
# GET /v1beta/apps/{appsId}/services
# operationId: appengine.apps.services.list
export def "v1beta-apps-services list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, services: table<id: string, labels: record, name: string, networkSettings: record, split: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}/services") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Deletes the specified service and all enclosed versions.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}
# operationId: appengine.apps.services.delete
export def "v1beta-apps-services delete" [
  apps_id: string
  services_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the current configuration of the specified service.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}
# operationId: appengine.apps.services.get
export def "v1beta-apps-services get" [
  apps_id: string
  services_id: string
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
]: nothing -> record<id: string, labels: record, name: string, networkSettings: record<ingressTrafficAllowed: string>, split: record<allocations: record, shardBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates the configuration of the specified service.
#
# PATCH /v1beta/apps/{appsId}/services/{servicesId}
# operationId: appengine.apps.services.patch
# --networkSettings shape: {ingressTrafficAllowed?: "INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED"|"INGRESS_TRAFFIC_ALLOWED_ALL"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB"}
# --split shape: {allocations?: record, shardBy?: "UNSPECIFIED"|"COOKIE"|"IP"|"RANDOM"}
export def "v1beta-apps-services update" [
  apps_id: string
  services_id: string
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
  --migrate-traffic: oneof<nothing, bool> # Set to true to gradually shift traffic to one or more versions that you specify. By default, traffic is shifted immediately. For gradual traffic migration, the target versions must be located within instances that are configured for both warmup requests (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#InboundServiceType) and automatic scaling (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#AutomaticScaling). You must specify the shardBy (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services#ShardBy) field in the Service resource. Gradual traffic migration is not supported in the App Engine flexible environment. For examples, see Migrating and Splitting Traffic (https://cloud.google.com/appengine/docs/admin-api/migrating-splitting-traffic).
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --id: string # Relative name of the service within the application. Example: default.@OutputOnly
  --labels: record # A set of labels to apply to this service. Labels are key/value pairs that describe the service and all resources that belong to it (e.g., versions). The labels can be used to search and group resources, and are propagated to the usage and billing reports, enabling fine-grain analysis of costs. An example of using labels is to tag resources belonging to different environments (e.g., "env=prod", "env=qa"). Label keys and values can be no longer than 63 characters and can only contain lowercase letters, numeric characters, underscores, dashes, and international characters. Label keys must start with a lowercase letter or an international character. Each service can have at most 32 labels.
  --name: string # Full path to the Service resource in the API. Example: apps/myapp/services/default.@OutputOnly
  --network-settings: record # A NetworkSettings resource is a container for ingress settings for a version or service. — shape: {ingressTrafficAllowed?: "INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED"|"INGRESS_TRAFFIC_ALLOWED_ALL"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB"}
  --body-split: record # Traffic routing configuration for versions within a single service. Traffic splits define how traffic directed to the service is assigned to versions. — shape: {allocations?: record, shardBy?: "UNSPECIFIED"|"COOKIE"|"IP"|"RANDOM"}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "migrateTraffic" $migrate_traffic "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}") $qp)
  let req_body = {"id": $id, "labels": $labels, "name": $name, "networkSettings": $network_settings, "split": $body_split} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "migrateTraffic": $migrate_traffic, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists the versions of a service.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions
# operationId: appengine.apps.services.versions.list
export def "v1beta-apps-services-versions list" [
  apps_id: string
  services_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
  --view: string@view-completer-1 # Controls the set of fields returned in the List response.
]: nothing -> record<nextPageToken: string, versions: table<apiConfig: record, appEngineApis: bool, automaticScaling: record, basicScaling: record, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record, diskUsageBytes: string, endpointsApiService: record, entrypoint: record, env: string, envVariables: record, errorHandlers: list, flexibleRuntimeSettings: record, handlers: list, healthCheck: record, id: string, inboundServices: list, instanceClass: string, libraries: list, livenessCheck: record, manualScaling: record, name: string, network: record, nobuildFilesRegex: string, readinessCheck: record, resources: record, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record, zones: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact), body: null}
}

# Deploys code and resource files to a new version.
#
# POST /v1beta/apps/{appsId}/services/{servicesId}/versions
# operationId: appengine.apps.services.versions.create
# --apiConfig shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
# --automaticScaling shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
# --basicScaling shape: {idleTimeout?: string, maxInstances?: int}
# --deployment shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
# --endpointsApiService shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
# --entrypoint shape: {shell?: string}
# --errorHandlers item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
# --flexibleRuntimeSettings shape: {operatingSystem?: string, runtimeVersion?: string}
# --handlers item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
# --healthCheck shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
# --libraries item shape: {name?: string, version?: string}
# --livenessCheck shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
# --manualScaling shape: {instances?: int}
# --network shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
# --readinessCheck shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
# --resources shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
# --vpcAccessConnector shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
export def "v1beta-apps-services-versions create" [
  apps_id: string
  services_id: string
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
  --api-config: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration for API handlers. — shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
  --app-engine-apis: oneof<nothing, bool> # Allows App Engine second generation runtimes to access the legacy bundled services.
  --automatic-scaling: record # Automatic scaling is based on request rate, response latencies, and other application metrics. — shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
  --basic-scaling: record # A service with basic scaling will create an instance when the application receives a request. The instance will be turned down when the app becomes idle. Basic scaling is ideal for work that is intermittent or driven by user activity. — shape: {idleTimeout?: string, maxInstances?: int}
  --beta-settings: record # Metadata settings that are supplied to this version to enable beta runtime features.
  --build-env-variables: record # Environment variables available to the build environment.Only returned in GET requests if view=FULL is set.
  --create-time: string # Time that this version was created.@OutputOnly (format: google-datetime)
  --created-by: string # Email address of the user who created this version.@OutputOnly
  --default-expiration: string # Duration that static files should be cached by web proxies and browsers. Only applicable if the corresponding StaticFilesHandler (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StaticFilesHandler) does not specify its own expiration time.Only returned in GET requests if view=FULL is set. (format: google-duration)
  --deployment: record # Code and application artifacts used to deploy a version to App Engine. — shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
  --disk-usage-bytes: string # Total size in bytes of all the files that are included in this version and currently hosted on the App Engine disk.@OutputOnly (format: int64)
  --endpoints-api-service: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration. The Endpoints API Service provides tooling for serving Open API and gRPC endpoints via an NGINX proxy. Only valid for App Engine Flexible environment deployments.The fields here refer to the name and configuration ID of a "service" resource in the Service Management API (https://cloud.google.com/service-management/overview). — shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
  --entrypoint: record # The entrypoint for the application. — shape: {shell?: string}
  --body-env: string # App Engine execution environment for this version.Defaults to standard.
  --env-variables: record # Environment variables available to the application.Only returned in GET requests if view=FULL is set.
  --error-handlers: list # Custom static error pages. Limited to 10KB per page.Only returned in GET requests if view=FULL is set. — item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
  --flexible-runtime-settings: record # Runtime settings for the App Engine flexible environment. — shape: {operatingSystem?: string, runtimeVersion?: string}
  --handlers: list # An ordered list of URL-matching patterns that should be applied to incoming requests. The first matching URL handles the request and other request handlers are not attempted.Only returned in GET requests if view=FULL is set. — item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
  --health-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. Only applicable for instances in App Engine flexible environment. — shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
  --id: string # Relative name of the version within the service. Example: v1. Version names can contain only lowercase letters, numbers, or hyphens. Reserved names: "default", "latest", and any name with the prefix "ah-".
  --inbound-services: list<string> # Before an application can receive email or XMPP messages, the application must be configured to enable the service.
  --instance-class: string # Instance class that is used to run this version. Valid values are: AutomaticScaling: F1, F2, F4, F4_1G ManualScaling or BasicScaling: B1, B2, B4, B8, B4_1GDefaults to F1 for AutomaticScaling and B1 for ManualScaling or BasicScaling.
  --libraries: list # Configuration for third-party Python runtime libraries that are required by the application.Only returned in GET requests if view=FULL is set. — item shape: {name?: string, version?: string}
  --liveness-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. — shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
  --manual-scaling: record # A service with manual scaling runs continuously, allowing you to perform complex initialization and rely on the state of its memory over time. — shape: {instances?: int}
  --name: string # Full path to the Version resource in the API. Example: apps/myapp/services/default/versions/v1.@OutputOnly
  --network: record # Extra network settings. Only applicable in the App Engine flexible environment. — shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
  --nobuild-files-regex: string # Files that match this pattern will not be built into this version. Only applicable for Go runtimes.Only returned in GET requests if view=FULL is set.
  --readiness-check: record # Readiness checking configuration for VM instances. Unhealthy instances are removed from traffic rotation. — shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
  --resources: record # Machine resources for a version. — shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
  --runtime: string # Desired runtime. Example: python27.
  --runtime-api-version: string # The version of the API in the given runtime environment. Please see the app.yaml reference for valid values at https://cloud.google.com/appengine/docs/standard//config/appref
  --runtime-channel: string # The channel of the runtime to use. Only available for some runtimes. Defaults to the default channel.
  --runtime-main-executable-path: string # The path or name of the app's main executable.
  --service-account: string # The identity that the deployed version will run as. Admin API will use the App Engine Appspot service account as default if this field is neither provided in app.yaml file nor through CLI flag.
  --serving-status: string@serving-status-completer-1 # Current serving status of this version. Only the versions with a SERVING status create instances and can be billed.SERVING_STATUS_UNSPECIFIED is an invalid value. Defaults to SERVING.
  --threadsafe: oneof<nothing, bool> # Whether multiple requests can be dispatched to this version at once.
  --version-url: string # Serving URL for this version. Example: "https://myversion-dot-myservice-dot-myapp.appspot.com"@OutputOnly
  --vm: oneof<nothing, bool> # Whether to deploy this version in a container on a virtual machine.
  --vpc-access-connector: record # VPC access connector specification. — shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
  --zones: list<string> # The Google Compute Engine zones that are supported by this version in the App Engine flexible environment. Deprecated.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions") $qp)
  let req_body = {"apiConfig": $api_config, "appEngineApis": $app_engine_apis, "automaticScaling": $automatic_scaling, "basicScaling": $basic_scaling, "betaSettings": $beta_settings, "buildEnvVariables": $build_env_variables, "createTime": $create_time, "createdBy": $created_by, "defaultExpiration": $default_expiration, "deployment": $deployment, "diskUsageBytes": $disk_usage_bytes, "endpointsApiService": $endpoints_api_service, "entrypoint": $entrypoint, "env": $body_env, "envVariables": $env_variables, "errorHandlers": $error_handlers, "flexibleRuntimeSettings": $flexible_runtime_settings, "handlers": $handlers, "healthCheck": $health_check, "id": $id, "inboundServices": $inbound_services, "instanceClass": $instance_class, "libraries": $libraries, "livenessCheck": $liveness_check, "manualScaling": $manual_scaling, "name": $name, "network": $network, "nobuildFilesRegex": $nobuild_files_regex, "readinessCheck": $readiness_check, "resources": $resources, "runtime": $runtime, "runtimeApiVersion": $runtime_api_version, "runtimeChannel": $runtime_channel, "runtimeMainExecutablePath": $runtime_main_executable_path, "serviceAccount": $service_account, "servingStatus": $serving_status, "threadsafe": $threadsafe, "versionUrl": $version_url, "vm": $vm, "vpcAccessConnector": $vpc_access_connector, "zones": $zones} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes an existing Version resource.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# operationId: appengine.apps.services.versions.delete
export def "v1beta-apps-services-versions delete" [
  apps_id: string
  services_id: string
  versions_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the specified Version resource. By default, only a BASIC_VIEW will be returned. Specify the FULL_VIEW parameter to get the full resource.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# operationId: appengine.apps.services.versions.get
export def "v1beta-apps-services-versions get" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --view: string@view-completer-1 # Controls the set of fields returned in the Get response.
]: nothing -> record<apiConfig: record<authFailAction: string, login: string, script: string, securityLevel: string, url: string>, appEngineApis: bool, automaticScaling: record<coolDownPeriod: string, cpuUtilization: record<aggregationWindowLength: string, targetUtilization: float>, customMetrics: list<record>, diskUtilization: record<targetReadBytesPerSecond: int, targetReadOpsPerSecond: int, targetWriteBytesPerSecond: int, targetWriteOpsPerSecond: int>, maxConcurrentRequests: int, maxIdleInstances: int, maxPendingLatency: string, maxTotalInstances: int, minIdleInstances: int, minPendingLatency: string, minTotalInstances: int, networkUtilization: record<targetReceivedBytesPerSecond: int, targetReceivedPacketsPerSecond: int, targetSentBytesPerSecond: int, targetSentPacketsPerSecond: int>, requestUtilization: record<targetConcurrentRequests: int, targetRequestCountPerSecond: int>, standardSchedulerSettings: record<maxInstances: int, minInstances: int, targetCpuUtilization: float, targetThroughputUtilization: float>>, basicScaling: record<idleTimeout: string, maxInstances: int>, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record<build: record<cloudBuildId: string>, cloudBuildOptions: record<appYamlPath: string, cloudBuildTimeout: string>, container: record<image: string>, files: record, zip: record<filesCount: int, sourceUrl: string>>, diskUsageBytes: string, endpointsApiService: record<configId: string, disableTraceSampling: bool, name: string, rolloutStrategy: string>, entrypoint: record<shell: string>, env: string, envVariables: record, errorHandlers: table<errorCode: string, mimeType: string, staticFile: string>, flexibleRuntimeSettings: record<operatingSystem: string, runtimeVersion: string>, handlers: table<apiEndpoint: record, authFailAction: string, login: string, redirectHttpResponseCode: string, script: record, securityLevel: string, staticFiles: record, urlRegex: string>, healthCheck: record<checkInterval: string, disableHealthCheck: bool, healthyThreshold: int, host: string, restartThreshold: int, timeout: string, unhealthyThreshold: int>, id: string, inboundServices: list<string>, instanceClass: string, libraries: table<name: string, version: string>, livenessCheck: record<checkInterval: string, failureThreshold: int, host: string, initialDelay: string, path: string, successThreshold: int, timeout: string>, manualScaling: record<instances: int>, name: string, network: record<forwardedPorts: list<string>, instanceIpMode: string, instanceTag: string, name: string, sessionAffinity: bool, subnetworkName: string>, nobuildFilesRegex: string, readinessCheck: record<appStartTimeout: string, checkInterval: string, failureThreshold: int, host: string, path: string, successThreshold: int, timeout: string>, resources: record<cpu: float, diskGb: float, kmsKeyReference: string, memoryGb: float, volumes: list<record>>, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record<egressSetting: string, name: string>, zones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "view": $view} | compact), body: null}
}

# Updates the specified Version resource. You can specify the following fields depending on the App Engine environment and type of scaling that the version resource uses:Standard environment instance_class (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.instance_class)automatic scaling in the standard environment: automatic_scaling.min_idle_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.max_idle_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automaticScaling.standard_scheduler_settings.max_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.min_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.target_cpu_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.target_throughput_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings)basic scaling or manual scaling in the standard environment: serving_status (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.serving_status) manual_scaling.instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#manualscaling)Flexible environment serving_status (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.serving_status)automatic scaling in the flexible environment: automatic_scaling.min_total_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.max_total_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.cool_down_period_sec (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.cpu_utilization.target_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling)manual scaling in the flexible environment: manual_scaling.instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#manualscaling)
#
# PATCH /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# operationId: appengine.apps.services.versions.patch
# --apiConfig shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
# --automaticScaling shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
# --basicScaling shape: {idleTimeout?: string, maxInstances?: int}
# --deployment shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
# --endpointsApiService shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
# --entrypoint shape: {shell?: string}
# --errorHandlers item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
# --flexibleRuntimeSettings shape: {operatingSystem?: string, runtimeVersion?: string}
# --handlers item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
# --healthCheck shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
# --libraries item shape: {name?: string, version?: string}
# --livenessCheck shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
# --manualScaling shape: {instances?: int}
# --network shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
# --readinessCheck shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
# --resources shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
# --vpcAccessConnector shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
export def "v1beta-apps-services-versions update" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated.
  --api-config: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration for API handlers. — shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
  --app-engine-apis: oneof<nothing, bool> # Allows App Engine second generation runtimes to access the legacy bundled services.
  --automatic-scaling: record # Automatic scaling is based on request rate, response latencies, and other application metrics. — shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
  --basic-scaling: record # A service with basic scaling will create an instance when the application receives a request. The instance will be turned down when the app becomes idle. Basic scaling is ideal for work that is intermittent or driven by user activity. — shape: {idleTimeout?: string, maxInstances?: int}
  --beta-settings: record # Metadata settings that are supplied to this version to enable beta runtime features.
  --build-env-variables: record # Environment variables available to the build environment.Only returned in GET requests if view=FULL is set.
  --create-time: string # Time that this version was created.@OutputOnly (format: google-datetime)
  --created-by: string # Email address of the user who created this version.@OutputOnly
  --default-expiration: string # Duration that static files should be cached by web proxies and browsers. Only applicable if the corresponding StaticFilesHandler (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StaticFilesHandler) does not specify its own expiration time.Only returned in GET requests if view=FULL is set. (format: google-duration)
  --deployment: record # Code and application artifacts used to deploy a version to App Engine. — shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
  --disk-usage-bytes: string # Total size in bytes of all the files that are included in this version and currently hosted on the App Engine disk.@OutputOnly (format: int64)
  --endpoints-api-service: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration. The Endpoints API Service provides tooling for serving Open API and gRPC endpoints via an NGINX proxy. Only valid for App Engine Flexible environment deployments.The fields here refer to the name and configuration ID of a "service" resource in the Service Management API (https://cloud.google.com/service-management/overview). — shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
  --entrypoint: record # The entrypoint for the application. — shape: {shell?: string}
  --body-env: string # App Engine execution environment for this version.Defaults to standard.
  --env-variables: record # Environment variables available to the application.Only returned in GET requests if view=FULL is set.
  --error-handlers: list # Custom static error pages. Limited to 10KB per page.Only returned in GET requests if view=FULL is set. — item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
  --flexible-runtime-settings: record # Runtime settings for the App Engine flexible environment. — shape: {operatingSystem?: string, runtimeVersion?: string}
  --handlers: list # An ordered list of URL-matching patterns that should be applied to incoming requests. The first matching URL handles the request and other request handlers are not attempted.Only returned in GET requests if view=FULL is set. — item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
  --health-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. Only applicable for instances in App Engine flexible environment. — shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
  --id: string # Relative name of the version within the service. Example: v1. Version names can contain only lowercase letters, numbers, or hyphens. Reserved names: "default", "latest", and any name with the prefix "ah-".
  --inbound-services: list<string> # Before an application can receive email or XMPP messages, the application must be configured to enable the service.
  --instance-class: string # Instance class that is used to run this version. Valid values are: AutomaticScaling: F1, F2, F4, F4_1G ManualScaling or BasicScaling: B1, B2, B4, B8, B4_1GDefaults to F1 for AutomaticScaling and B1 for ManualScaling or BasicScaling.
  --libraries: list # Configuration for third-party Python runtime libraries that are required by the application.Only returned in GET requests if view=FULL is set. — item shape: {name?: string, version?: string}
  --liveness-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. — shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
  --manual-scaling: record # A service with manual scaling runs continuously, allowing you to perform complex initialization and rely on the state of its memory over time. — shape: {instances?: int}
  --name: string # Full path to the Version resource in the API. Example: apps/myapp/services/default/versions/v1.@OutputOnly
  --network: record # Extra network settings. Only applicable in the App Engine flexible environment. — shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
  --nobuild-files-regex: string # Files that match this pattern will not be built into this version. Only applicable for Go runtimes.Only returned in GET requests if view=FULL is set.
  --readiness-check: record # Readiness checking configuration for VM instances. Unhealthy instances are removed from traffic rotation. — shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
  --resources: record # Machine resources for a version. — shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
  --runtime: string # Desired runtime. Example: python27.
  --runtime-api-version: string # The version of the API in the given runtime environment. Please see the app.yaml reference for valid values at https://cloud.google.com/appengine/docs/standard//config/appref
  --runtime-channel: string # The channel of the runtime to use. Only available for some runtimes. Defaults to the default channel.
  --runtime-main-executable-path: string # The path or name of the app's main executable.
  --service-account: string # The identity that the deployed version will run as. Admin API will use the App Engine Appspot service account as default if this field is neither provided in app.yaml file nor through CLI flag.
  --serving-status: string@serving-status-completer-1 # Current serving status of this version. Only the versions with a SERVING status create instances and can be billed.SERVING_STATUS_UNSPECIFIED is an invalid value. Defaults to SERVING.
  --threadsafe: oneof<nothing, bool> # Whether multiple requests can be dispatched to this version at once.
  --version-url: string # Serving URL for this version. Example: "https://myversion-dot-myservice-dot-myapp.appspot.com"@OutputOnly
  --vm: oneof<nothing, bool> # Whether to deploy this version in a container on a virtual machine.
  --vpc-access-connector: record # VPC access connector specification. — shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
  --zones: list<string> # The Google Compute Engine zones that are supported by this version in the App Engine flexible environment. Deprecated.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}") $qp)
  let req_body = {"apiConfig": $api_config, "appEngineApis": $app_engine_apis, "automaticScaling": $automatic_scaling, "basicScaling": $basic_scaling, "betaSettings": $beta_settings, "buildEnvVariables": $build_env_variables, "createTime": $create_time, "createdBy": $created_by, "defaultExpiration": $default_expiration, "deployment": $deployment, "diskUsageBytes": $disk_usage_bytes, "endpointsApiService": $endpoints_api_service, "entrypoint": $entrypoint, "env": $body_env, "envVariables": $env_variables, "errorHandlers": $error_handlers, "flexibleRuntimeSettings": $flexible_runtime_settings, "handlers": $handlers, "healthCheck": $health_check, "id": $id, "inboundServices": $inbound_services, "instanceClass": $instance_class, "libraries": $libraries, "livenessCheck": $liveness_check, "manualScaling": $manual_scaling, "name": $name, "network": $network, "nobuildFilesRegex": $nobuild_files_regex, "readinessCheck": $readiness_check, "resources": $resources, "runtime": $runtime, "runtimeApiVersion": $runtime_api_version, "runtimeChannel": $runtime_channel, "runtimeMainExecutablePath": $runtime_main_executable_path, "serviceAccount": $service_account, "servingStatus": $serving_status, "threadsafe": $threadsafe, "versionUrl": $version_url, "vm": $vm, "vpcAccessConnector": $vpc_access_connector, "zones": $zones} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists the instances of a version.Tip: To aggregate details about instances over time, see the Stackdriver Monitoring API (https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/list).
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances
# operationId: appengine.apps.services.versions.instances.list
export def "v1beta-apps-services-versions-instances list" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<instances: table<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}/instances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Stops a running instance.The instance might be automatically recreated based on the scaling settings of the version. For more information, see "How Instances are Managed" (standard environment (https://cloud.google.com/appengine/docs/standard/python/how-instances-are-managed) | flexible environment (https://cloud.google.com/appengine/docs/flexible/python/how-instances-are-managed)).To ensure that instances are not re-created and avoid getting billed, you can stop all instances within the target version by changing the serving status of the version to STOPPED with the apps.services.versions.patch (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1/apps.services.versions/patch) method.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}
# operationId: appengine.apps.services.versions.instances.delete
export def "v1beta-apps-services-versions-instances delete" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  if ($instances_id | is-empty) { error make --unspanned { msg: "path parameter 'instancesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id), instances_id: (encode-path-segment $instances_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}/instances/{instances_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets instance information.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}
# operationId: appengine.apps.services.versions.instances.get
export def "v1beta-apps-services-versions-instances get" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
]: nothing -> record<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  if ($instances_id | is-empty) { error make --unspanned { msg: "path parameter 'instancesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id), instances_id: (encode-path-segment $instances_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}/instances/{instances_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Enables debugging on a VM instance. This allows you to use the SSH command to connect to the virtual machine where the instance lives. While in "debug mode", the instance continues to serve live traffic. You should delete the instance when you are done debugging and then allow the system to take over and determine if another instance should be started.Only applicable for instances in App Engine flexible environment.
#
# POST /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}:debug
# operationId: appengine.apps.services.versions.instances.debug
export def "v1beta-apps-services-versions-instances create-debug" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
  --ssh-key: string # Public SSH key to add to the instance. Examples: [USERNAME]:ssh-rsa [KEY_VALUE] [USERNAME] [USERNAME]:ssh-rsa [KEY_VALUE] google-ssh {"userName":"[USERNAME]","expireOn":"[EXPIRE_TIME]"}For more information, see Adding and Removing SSH Keys (https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys).
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  if ($services_id | is-empty) { error make --unspanned { msg: "path parameter 'servicesId' must be non-empty" } }
  if ($versions_id | is-empty) { error make --unspanned { msg: "path parameter 'versionsId' must be non-empty" } }
  if ($instances_id | is-empty) { error make --unspanned { msg: "path parameter 'instancesId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id), services_id: (encode-path-segment $services_id), versions_id: (encode-path-segment $versions_id), instances_id: (encode-path-segment $instances_id)} | format pattern "/v1beta/apps/{apps_id}/services/{services_id}/versions/{versions_id}/instances/{instances_id}:debug") $qp)
  let req_body = {"sshKey": $ssh_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Recreates the required App Engine features for the specified App Engine application, for example a Cloud Storage bucket or App Engine service account. Use this method if you receive an error message about a missing feature, for example, Error retrieving the App Engine service account. If you have deleted your App Engine service account, this will not be able to recreate it. Instead, you should attempt to use the IAM undelete API if possible at https://cloud.google.com/iam/reference/rest/v1/projects.serviceAccounts/undelete?apix_params=%7B"name"%3A"projects%2F-%2FserviceAccounts%2Funique_id"%2C"resource"%3A%7B%7D%7D . If the deletion was recent, the numeric ID can be found in the Cloud Console Activity Log.
#
# POST /v1beta/apps/{appsId}:repair
# operationId: appengine.apps.repair
export def "v1beta-apps create-repair" [
  apps_id: string
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
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($apps_id | is-empty) { error make --unspanned { msg: "path parameter 'appsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({apps_id: (encode-path-segment $apps_id)} | format pattern "/v1beta/apps/{apps_id}:repair") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists information about the supported locations for this service.
#
# GET /v1beta/projects/{projectsId}/locations
# operationId: appengine.projects.locations.list
export def "v1beta-projects-locations list" [
  projects_id: string
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
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like "displayName=tokyo", and is documented in more detail in AIP-160 (https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the next_page_token field in the response. Send that page token to receive the subsequent page.
]: nothing -> record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id)} | format pattern "/v1beta/projects/{projects_id}/locations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets information about a location.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}
# operationId: appengine.projects.locations.get
export def "v1beta-projects-locations get" [
  projects_id: string
  locations_id: string
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
]: nothing -> record<displayName: string, labels: record, locationId: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates an App Engine application for a Google Cloud Platform project. Required fields: id - The ID of the target Cloud Platform project. location - The region (https://cloud.google.com/appengine/docs/locations) where you want the App Engine application located.For more information about App Engine applications, see Managing Projects, Applications, and Billing (https://cloud.google.com/appengine/docs/standard/python/console/).
#
# POST /v1beta/projects/{projectsId}/locations/{locationsId}/applications
# operationId: appengine.projects.locations.applications.create
# --dispatchRules item shape: {domain?: string, path?: string, service?: string}
# --featureSettings shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
# --iap shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
export def "v1beta-projects-locations-applications create" [
  projects_id: string
  locations_id: string
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
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}/applications") $qp)
  let req_body = {"authDomain": $auth_domain, "databaseType": $database_type, "defaultCookieExpiration": $default_cookie_expiration, "dispatchRules": $dispatch_rules, "featureSettings": $feature_settings, "iap": $iap, "id": $id, "locationId": $location_id, "serviceAccount": $service_account, "servingStatus": $serving_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Gets information about an application.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}
# operationId: appengine.projects.locations.applications.get
export def "v1beta-projects-locations-applications get" [
  projects_id: string
  locations_id: string
  applications_id: string
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
]: nothing -> record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  if ($applications_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id), applications_id: (encode-path-segment $applications_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}/applications/{applications_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Recreates the required App Engine features for the specified App Engine application, for example a Cloud Storage bucket or App Engine service account. Use this method if you receive an error message about a missing feature, for example, Error retrieving the App Engine service account. If you have deleted your App Engine service account, this will not be able to recreate it. Instead, you should attempt to use the IAM undelete API if possible at https://cloud.google.com/iam/reference/rest/v1/projects.serviceAccounts/undelete?apix_params=%7B"name"%3A"projects%2F-%2FserviceAccounts%2Funique_id"%2C"resource"%3A%7B%7D%7D . If the deletion was recent, the numeric ID can be found in the Cloud Console Activity Log.
#
# POST /v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}:repair
# operationId: appengine.projects.locations.applications.repair
export def "v1beta-projects-locations-applications create-repair" [
  projects_id: string
  locations_id: string
  applications_id: string
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
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  if ($applications_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id), applications_id: (encode-path-segment $applications_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}/applications/{applications_id}:repair") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns UNIMPLEMENTED.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/operations
# operationId: appengine.projects.locations.operations.list
export def "v1beta-projects-locations-operations list" [
  projects_id: string
  locations_id: string
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
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/operations/{operationsId}
# operationId: appengine.projects.locations.operations.get
export def "v1beta-projects-locations-operations get" [
  projects_id: string
  locations_id: string
  operations_id: string
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($projects_id | is-empty) { error make --unspanned { msg: "path parameter 'projectsId' must be non-empty" } }
  if ($locations_id | is-empty) { error make --unspanned { msg: "path parameter 'locationsId' must be non-empty" } }
  if ($operations_id | is-empty) { error make --unspanned { msg: "path parameter 'operationsId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({projects_id: (encode-path-segment $projects_id), locations_id: (encode-path-segment $locations_id), operations_id: (encode-path-segment $operations_id)} | format pattern "/v1beta/projects/{projects_id}/locations/{locations_id}/operations/{operations_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}
