# Auto-generated client for Registry API v0.0.1
# Source: https://api.apis.guru/v2/specs/apigee.local/registry/0.0.1/openapi.json
# Auth: --token flag or $env.REGISTRY_API_TOKEN

const BASE_URL = "http://apigee.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REGISTRY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://apigee.local" "https://apigeeregistry.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects-locations-apis list-registry" } } | get name | first)
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

# ListApis returns matching APIs.
#
# GET /v1/projects/{project}/locations/{location}/apis
# operationId: Registry_ListApis
export def "projects-locations-apis list-registry" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of APIs to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApis` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApis` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> record<apis: table<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/v1/projects/{project}/locations/{location}/apis") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CreateApi creates a specified API.
#
# POST /v1/projects/{project}/locations/{location}/apis
# operationId: Registry_CreateApi
export def "projects-locations-apis create-registry" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # Required. The ID to use for the api, which will become the final component of the api's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --availability: string # A user-definable description of the availability of this service. Format: free-form, but we expect single words that describe availability, e.g. "NONE", "TESTING", "PREVIEW", "GENERAL", "DEPRECATED", "SHUTDOWN".
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --recommended-deployment: string # The recommended deployment of the API. Format: apis/{api}/deployments/{deployment}
  --recommended-version: string # The recommended version of the API. Format: apis/{api}/versions/{version}
]: any -> record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiId" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/v1/projects/{project}/locations/{location}/apis") $qp)
  let req_body = {"annotations": $annotations, "availability": $availability, "description": $description, "displayName": $display_name, "labels": $labels, "name": $name, "recommendedDeployment": $recommended_deployment, "recommendedVersion": $recommended_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApi removes a specified API and all of the resources that it owns.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}
# operationId: Registry_DeleteApi
export def "projects-locations-apis delete-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetApi returns a specified API.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}
# operationId: Registry_GetApi
export def "projects-locations-apis get-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# UpdateApi can be used to modify a specified API.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}
# operationId: Registry_UpdateApi
export def "projects-locations-apis update-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the api is not found, a new api_versions will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --availability: string # A user-definable description of the availability of this service. Format: free-form, but we expect single words that describe availability, e.g. "NONE", "TESTING", "PREVIEW", "GENERAL", "DEPRECATED", "SHUTDOWN".
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --recommended-deployment: string # The recommended deployment of the API. Format: apis/{api}/deployments/{deployment}
  --recommended-version: string # The recommended version of the API. Format: apis/{api}/versions/{version}
]: any -> record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateMask" $update_mask "scalar") (serialize-qp "allowMissing" $allow_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}") $qp)
  let req_body = {"annotations": $annotations, "availability": $availability, "description": $description, "displayName": $display_name, "labels": $labels, "name": $name, "recommendedDeployment": $recommended_deployment, "recommendedVersion": $recommended_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# ListApiDeployments returns matching deployments.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments
# operationId: Registry_ListApiDeployments
export def "projects-locations-apis-deployments list-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of deployments to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiDeployments` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiDeployments` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CreateApiDeployment creates a specified deployment.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments
# operationId: Registry_CreateApiDeployment
export def "projects-locations-apis-deployments create-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-deployment-id: string # Required. The ID to use for the deployment, which will become the final component of the deployment's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --access-guidance: string # Text briefly describing how to access the endpoint. Changes to this value will not affect the revision.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --api-spec-revision: string # The full resource name (including revision id) of the spec of the API being served by the deployment. Changes to this value will update the revision. Format: apis/{api}/deployments/{deployment}
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --endpoint-uri: string # The address where the deployment is serving. Changes to this value will update the revision.
  --external-channel-uri: string # The address of the external channel of the API (e.g. the Developer Portal). Changes to this value will not affect the revision.
  --intended-audience: string # Text briefly identifying the intended audience of the API. Changes to this value will not affect the revision.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "registry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
]: any -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiDeploymentId" $api_deployment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments") $qp)
  let req_body = {"accessGuidance": $access_guidance, "annotations": $annotations, "apiSpecRevision": $api_spec_revision, "description": $description, "displayName": $display_name, "endpointUri": $endpoint_uri, "externalChannelUri": $external_channel_uri, "intendedAudience": $intended_audience, "labels": $labels, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApiDeployment removes a specified deployment, all revisions, and all child resources (e.g. artifacts).
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# operationId: Registry_DeleteApiDeployment
export def "projects-locations-apis-deployments delete-registry" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetApiDeployment returns a specified deployment.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# operationId: Registry_GetApiDeployment
export def "projects-locations-apis-deployments get-registry" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# UpdateApiDeployment can be used to modify a specified deployment.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# operationId: Registry_UpdateApiDeployment
export def "projects-locations-apis-deployments update-registry" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the deployment is not found, a new deployment will be created. In this situation, `update_mask` is ignored.
  --access-guidance: string # Text briefly describing how to access the endpoint. Changes to this value will not affect the revision.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --api-spec-revision: string # The full resource name (including revision id) of the spec of the API being served by the deployment. Changes to this value will update the revision. Format: apis/{api}/deployments/{deployment}
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --endpoint-uri: string # The address where the deployment is serving. Changes to this value will update the revision.
  --external-channel-uri: string # The address of the external channel of the API (e.g. the Developer Portal). Changes to this value will not affect the revision.
  --intended-audience: string # Text briefly identifying the intended audience of the API. Changes to this value will not affect the revision.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "registry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
]: any -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateMask" $update_mask "scalar") (serialize-qp "allowMissing" $allow_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}") $qp)
  let req_body = {"accessGuidance": $access_guidance, "annotations": $annotations, "apiSpecRevision": $api_spec_revision, "description": $description, "displayName": $display_name, "endpointUri": $endpoint_uri, "externalChannelUri": $external_channel_uri, "intendedAudience": $intended_audience, "labels": $labels, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApiDeploymentRevision deletes a revision of a deployment.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:deleteRevision
# operationId: Registry_DeleteApiDeploymentRevision
export def "projects-locations-apis-deployments delete-registry-revision" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:deleteRevision"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ListApiDeploymentRevisions lists all revisions of a deployment. Revisions are returned in descending order of revision creation time.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:listRevisions
# operationId: Registry_ListApiDeploymentRevisions
export def "projects-locations-apis-deployments list-registry-revisions" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of revisions to return per page. (format: int32)
  --page-token: string # The page token, received from a previous ListApiDeploymentRevisions call. Provide this to retrieve the subsequent page.
]: nothing -> record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:listRevisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RollbackApiDeployment sets the current revision to a specified prior revision. Note that this creates a new revision with a new revision ID.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:rollback
# operationId: Registry_RollbackApiDeployment
export def "projects-locations-apis-deployments create-registry-rollback" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The deployment being rolled back.
  revision_id: string # Required. The revision ID to roll back to. It must be a revision of the same deployment. Example: c7cfa2a8
]: any -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:rollback"))
  let req_body = {"name": $name, "revisionId": $revision_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# TagApiDeploymentRevision adds a tag to a specified revision of a deployment.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:tagRevision
# operationId: Registry_TagApiDeploymentRevision
export def "projects-locations-apis-deployments tag-registry-revision" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The name of the deployment to be tagged, including the revision ID.
  tag: string # Required. The tag to apply. The tag should be at most 40 characters, and match `[a-z][a-z0-9-]{3,39}`.
]: any -> record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), deployment: (encode-path-segment $deployment)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:tagRevision"))
  let req_body = {"name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# ListApiVersions returns matching versions.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions
# operationId: Registry_ListApiVersions
export def "projects-locations-apis-versions list-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of versions to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiVersions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiVersions` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> record<apiVersions: table<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CreateApiVersion creates a specified version.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions
# operationId: Registry_CreateApiVersion
export def "projects-locations-apis-versions create-registry" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version-id: string # Required. The ID to use for the version, which will become the final component of the version's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --state: string # A user-definable description of the lifecycle phase of this API version. Format: free-form, but we expect single words that describe API maturity, e.g. "CONCEPT", "DESIGN", "DEVELOPMENT", "STAGING", "PRODUCTION", "DEPRECATED", "RETIRED".
]: any -> record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiVersionId" $api_version_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions") $qp)
  let req_body = {"annotations": $annotations, "description": $description, "displayName": $display_name, "labels": $labels, "name": $name, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApiVersion removes a specified version and all of the resources that it owns.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# operationId: Registry_DeleteApiVersion
export def "projects-locations-apis-versions delete-registry" [
  project: string
  location: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetApiVersion returns a specified version.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# operationId: Registry_GetApiVersion
export def "projects-locations-apis-versions get-registry" [
  project: string
  location: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# UpdateApiVersion can be used to modify a specified version.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# operationId: Registry_UpdateApiVersion
export def "projects-locations-apis-versions update-registry" [
  project: string
  location: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the version is not found, a new version will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --state: string # A user-definable description of the lifecycle phase of this API version. Format: free-form, but we expect single words that describe API maturity, e.g. "CONCEPT", "DESIGN", "DEVELOPMENT", "STAGING", "PRODUCTION", "DEPRECATED", "RETIRED".
]: any -> record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateMask" $update_mask "scalar") (serialize-qp "allowMissing" $allow_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}") $qp)
  let req_body = {"annotations": $annotations, "description": $description, "displayName": $display_name, "labels": $labels, "name": $name, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# ListApiSpecs returns matching specs.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs
# operationId: Registry_ListApiSpecs
export def "projects-locations-apis-versions-specs list-registry" [
  project: string
  location: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of specs to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiSpecs` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiSpecs` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields except contents.
]: nothing -> record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CreateApiSpec creates a specified spec.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs
# operationId: Registry_CreateApiSpec
export def "projects-locations-apis-versions-specs create-registry" [
  project: string
  location: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-spec-id: string # Required. The ID to use for the spec, which will become the final component of the spec's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --contents: string # Input only. The contents of the spec. Provided by API callers when specs are created or updated. To access the contents of a spec, use GetApiSpecContents. (format: bytes)
  --description: string # A detailed description.
  --filename: string # A possibly-hierarchical name used to refer to the spec from other specs.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --mime-type: string # A style (format) descriptor for this spec that is specified as a Media Type (https://en.wikipedia.org/wiki/Media_type). Possible values include "application/vnd.apigee.proto", "application/vnd.apigee.openapi", and "application/vnd.apigee.graphql", with possible suffixes representing compression types. These hypothetical names are defined in the vendor tree defined in RFC6838 (https://tools.ietf.org/html/rfc6838) and are not final. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
  --source-uri: string # The original source URI of the spec (if one exists). This is an external location that can be used for reference purposes but which may not be authoritative since this external resource may change after the spec is retrieved.
]: any -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiSpecId" $api_spec_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs") $qp)
  let req_body = {"annotations": $annotations, "contents": $contents, "description": $description, "filename": $filename, "labels": $labels, "mimeType": $mime_type, "name": $name, "sourceUri": $source_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApiSpec removes a specified spec, all revisions, and all child resources (e.g. artifacts).
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# operationId: Registry_DeleteApiSpec
export def "projects-locations-apis-versions-specs delete-registry" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetApiSpec returns a specified spec.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# operationId: Registry_GetApiSpec
export def "projects-locations-apis-versions-specs get-registry" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# UpdateApiSpec can be used to modify a specified spec.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# operationId: Registry_UpdateApiSpec
export def "projects-locations-apis-versions-specs update-registry" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the spec is not found, a new spec will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --contents: string # Input only. The contents of the spec. Provided by API callers when specs are created or updated. To access the contents of a spec, use GetApiSpecContents. (format: bytes)
  --description: string # A detailed description.
  --filename: string # A possibly-hierarchical name used to refer to the spec from other specs.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --mime-type: string # A style (format) descriptor for this spec that is specified as a Media Type (https://en.wikipedia.org/wiki/Media_type). Possible values include "application/vnd.apigee.proto", "application/vnd.apigee.openapi", and "application/vnd.apigee.graphql", with possible suffixes representing compression types. These hypothetical names are defined in the vendor tree defined in RFC6838 (https://tools.ietf.org/html/rfc6838) and are not final. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
  --source-uri: string # The original source URI of the spec (if one exists). This is an external location that can be used for reference purposes but which may not be authoritative since this external resource may change after the spec is retrieved.
]: any -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateMask" $update_mask "scalar") (serialize-qp "allowMissing" $allow_missing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}") $qp)
  let req_body = {"annotations": $annotations, "contents": $contents, "description": $description, "filename": $filename, "labels": $labels, "mimeType": $mime_type, "name": $name, "sourceUri": $source_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteApiSpecRevision deletes a revision of a spec.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:deleteRevision
# operationId: Registry_DeleteApiSpecRevision
export def "projects-locations-apis-versions-specs delete-registry-revision" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:deleteRevision"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetApiSpecContents returns the contents of a specified spec. If specs are stored with GZip compression, the default behavior is to return the spec uncompressed (the mime_type response field indicates the exact format returned).
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:getContents
# operationId: Registry_GetApiSpecContents
export def "projects-locations-apis-versions-specs get-registry-contents" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:getContents"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ListApiSpecRevisions lists all revisions of a spec. Revisions are returned in descending order of revision creation time.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:listRevisions
# operationId: Registry_ListApiSpecRevisions
export def "projects-locations-apis-versions-specs list-registry-revisions" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of revisions to return per page. (format: int32)
  --page-token: string # The page token, received from a previous ListApiSpecRevisions call. Provide this to retrieve the subsequent page.
]: nothing -> record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:listRevisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# RollbackApiSpec sets the current revision to a specified prior revision. Note that this creates a new revision with a new revision ID.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:rollback
# operationId: Registry_RollbackApiSpec
export def "projects-locations-apis-versions-specs create-registry-rollback" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The spec being rolled back.
  revision_id: string # Required. The revision ID to roll back to. It must be a revision of the same spec. Example: c7cfa2a8
]: any -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:rollback"))
  let req_body = {"name": $name, "revisionId": $revision_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# TagApiSpecRevision adds a tag to a specified revision of a spec.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:tagRevision
# operationId: Registry_TagApiSpecRevision
export def "projects-locations-apis-versions-specs tag-registry-revision" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The name of the spec to be tagged, including the revision ID.
  tag: string # Required. The tag to apply. The tag should be at most 40 characters, and match `[a-z][a-z0-9-]{3,39}`.
]: any -> record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), api: (encode-path-segment $api), version: (encode-path-segment $version), spec: (encode-path-segment $spec)} | format pattern "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:tagRevision"))
  let req_body = {"name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# ListArtifacts returns matching artifacts.
#
# GET /v1/projects/{project}/locations/{location}/artifacts
# operationId: Registry_ListArtifacts
export def "projects-locations-artifacts list-registry" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of artifacts to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListArtifacts` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListArtifacts` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields except contents.
]: nothing -> record<artifacts: table<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# CreateArtifact creates a specified artifact.
#
# POST /v1/projects/{project}/locations/{location}/artifacts
# operationId: Registry_CreateArtifact
export def "projects-locations-artifacts create-registry" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-id: string # Required. The ID to use for the artifact, which will become the final component of the artifact's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --contents: string # Input only. The contents of the artifact. Provided by API callers when artifacts are created or replaced. To access the contents of an artifact, use GetArtifactContents. (format: bytes)
  --mime-type: string # A content type specifier for the artifact. Content type specifiers are Media Types (https://en.wikipedia.org/wiki/Media_type) with a possible "schema" parameter that specifies a schema for the stored information. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
]: any -> record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artifactId" $artifact_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts") $qp)
  let req_body = {"contents": $contents, "mimeType": $mime_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DeleteArtifact removes a specified artifact.
#
# DELETE /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# operationId: Registry_DeleteArtifact
export def "projects-locations-artifacts delete-registry" [
  project: string
  location: string
  artifact: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), artifact: (encode-path-segment $artifact)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GetArtifact returns a specified artifact.
#
# GET /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# operationId: Registry_GetArtifact
export def "projects-locations-artifacts get-registry" [
  project: string
  location: string
  artifact: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), artifact: (encode-path-segment $artifact)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# ReplaceArtifact can be used to replace a specified artifact.
#
# PUT /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# operationId: Registry_ReplaceArtifact
export def "projects-locations-artifacts update-registry" [
  project: string
  location: string
  artifact: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: string # Input only. The contents of the artifact. Provided by API callers when artifacts are created or replaced. To access the contents of an artifact, use GetArtifactContents. (format: bytes)
  --mime-type: string # A content type specifier for the artifact. Content type specifiers are Media Types (https://en.wikipedia.org/wiki/Media_type) with a possible "schema" parameter that specifies a schema for the stored information. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
]: any -> record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), artifact: (encode-path-segment $artifact)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"))
  let req_body = {"contents": $contents, "mimeType": $mime_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# GetArtifactContents returns the contents of a specified artifact. If artifacts are stored with GZip compression, the default behavior is to return the artifact uncompressed (the mime_type response field indicates the exact format returned).
#
# GET /v1/projects/{project}/locations/{location}/artifacts/{artifact}:getContents
# operationId: Registry_GetArtifactContents
export def "projects-locations-artifacts get-registry-contents" [
  project: string
  location: string
  artifact: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: int, details: table<_type: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), artifact: (encode-path-segment $artifact)} | format pattern "/v1/projects/{project}/locations/{location}/artifacts/{artifact}:getContents"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
