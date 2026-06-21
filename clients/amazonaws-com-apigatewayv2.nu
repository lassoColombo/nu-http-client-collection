# Auto-generated client for AmazonApiGatewayV2 v2018-11-29
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apigatewayv2/2018-11-29/openapi.json
# Auth: --token flag or $env.AMAZONAPIGATEWAYV2_TOKEN

const BASE_URL = "http://apigateway.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZONAPIGATEWAYV2_TOKEN | default "" }
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

def base-url-completer [] { ["http://apigateway.us-east-1.amazonaws.com" "http://apigateway.us-east-2.amazonaws.com" "http://apigateway.us-west-1.amazonaws.com" "http://apigateway.us-west-2.amazonaws.com" "http://apigateway.us-gov-west-1.amazonaws.com" "http://apigateway.us-gov-east-1.amazonaws.com" "http://apigateway.ca-central-1.amazonaws.com" "http://apigateway.eu-north-1.amazonaws.com" "http://apigateway.eu-west-1.amazonaws.com" "http://apigateway.eu-west-2.amazonaws.com" "http://apigateway.eu-west-3.amazonaws.com" "http://apigateway.eu-central-1.amazonaws.com" "http://apigateway.eu-south-1.amazonaws.com" "http://apigateway.af-south-1.amazonaws.com" "http://apigateway.ap-northeast-1.amazonaws.com" "http://apigateway.ap-northeast-2.amazonaws.com" "http://apigateway.ap-northeast-3.amazonaws.com" "http://apigateway.ap-southeast-1.amazonaws.com" "http://apigateway.ap-southeast-2.amazonaws.com" "http://apigateway.ap-east-1.amazonaws.com" "http://apigateway.ap-south-1.amazonaws.com" "http://apigateway.sa-east-1.amazonaws.com" "http://apigateway.me-south-1.amazonaws.com" "https://apigateway.us-east-1.amazonaws.com" "https://apigateway.us-east-2.amazonaws.com" "https://apigateway.us-west-1.amazonaws.com" "https://apigateway.us-west-2.amazonaws.com" "https://apigateway.us-gov-west-1.amazonaws.com" "https://apigateway.us-gov-east-1.amazonaws.com" "https://apigateway.ca-central-1.amazonaws.com" "https://apigateway.eu-north-1.amazonaws.com" "https://apigateway.eu-west-1.amazonaws.com" "https://apigateway.eu-west-2.amazonaws.com" "https://apigateway.eu-west-3.amazonaws.com" "https://apigateway.eu-central-1.amazonaws.com" "https://apigateway.eu-south-1.amazonaws.com" "https://apigateway.af-south-1.amazonaws.com" "https://apigateway.ap-northeast-1.amazonaws.com" "https://apigateway.ap-northeast-2.amazonaws.com" "https://apigateway.ap-northeast-3.amazonaws.com" "https://apigateway.ap-southeast-1.amazonaws.com" "https://apigateway.ap-southeast-2.amazonaws.com" "https://apigateway.ap-east-1.amazonaws.com" "https://apigateway.ap-south-1.amazonaws.com" "https://apigateway.sa-east-1.amazonaws.com" "https://apigateway.me-south-1.amazonaws.com" "http://apigateway.cn-north-1.amazonaws.com.cn" "http://apigateway.cn-northwest-1.amazonaws.com.cn" "https://apigateway.cn-north-1.amazonaws.com.cn" "https://apigateway.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def protocol-type-completer [] { ["HTTP" "WEBSOCKET"] }
def authorizer-type-completer [] { ["JWT" "REQUEST"] }
def connection-type-completer [] { ["INTERNET" "VPC_LINK"] }
def content-handling-strategy-completer [] { ["CONVERT_TO_BINARY" "CONVERT_TO_TEXT"] }
def integration-type-completer [] { ["AWS" "AWS_PROXY" "HTTP" "HTTP_PROXY" "MOCK"] }
def passthrough-behavior-completer [] { ["NEVER" "WHEN_NO_MATCH" "WHEN_NO_TEMPLATES"] }
def authorization-type-completer [] { ["AWS_IAM" "CUSTOM" "JWT" "NONE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apis create" } } | get name | first)
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

# Creates an Api resource.
#
# POST /v2/apis
# operationId: CreateApi
# --corsConfiguration shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "apis create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --cors-configuration: record # Represents a CORS configuration. Supported only for HTTP APIs. See Configuring CORS (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html) for more information. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --disable-schema-validation: oneof<nothing, bool> # Avoid validating models when creating a deployment. Supported only for WebSocket APIs.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint.
  name: string # A string with a length between [1-128].
  protocol_type: string@protocol-type-completer # Represents a protocol type.
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --tags: record # Represents a collection of tags associated with the resource.
  --target: string # A string representation of a URI with a length between [1-2048].
  --version: string # A string with a length between [1-64].
]: any -> record<ApiEndpoint: record, ApiGatewayManaged: record, ApiId: record, ApiKeySelectionExpression: record, CorsConfiguration: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreatedDate: record, Description: record, DisableSchemaValidation: record, DisableExecuteApiEndpoint: record, ImportInfo: record, Name: record, ProtocolType: record, RouteSelectionExpression: record, Tags: record, Version: record, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apis")
  let req_body = {"apiKeySelectionExpression": $api_key_selection_expression, "corsConfiguration": $cors_configuration, "credentialsArn": $credentials_arn, "description": $description, "disableSchemaValidation": $disable_schema_validation, "disableExecuteApiEndpoint": $disable_execute_api_endpoint, "name": $name, "protocolType": $protocol_type, "routeKey": $route_key, "routeSelectionExpression": $route_selection_expression, "tags": $tags, "target": $target, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a collection of Api resources.
#
# GET /v2/apis
# operationId: GetApis
export def "apis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/apis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Imports an API.
#
# PUT /v2/apis
# operationId: ImportApi
export def "apis import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basepath: string # Specifies how to interpret the base path of the API during import. Valid values are ignore, prepend, and split. The default value is ignore. To learn more, see Set the OpenAPI basePath Property (https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-import-api-basePath.html). Supported only for HTTP APIs.
  --fail-on-warnings: oneof<nothing, bool> # Specifies whether to rollback the API creation when a warning is encountered. By default, API creation continues if a warning is encountered.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The OpenAPI definition. Supported only for HTTP APIs.
]: any -> record<ApiEndpoint: record, ApiGatewayManaged: record, ApiId: record, ApiKeySelectionExpression: record, CorsConfiguration: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreatedDate: record, Description: record, DisableSchemaValidation: record, DisableExecuteApiEndpoint: record, ImportInfo: record, Name: record, ProtocolType: record, RouteSelectionExpression: record, Tags: record, Version: record, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "basepath" $basepath "scalar") (serialize-qp "failOnWarnings" $fail_on_warnings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/apis" $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"basepath": $basepath, "failOnWarnings": $fail_on_warnings} | compact), body: $req_body}
}

# Creates an API mapping.
#
# POST /v2/domainnames/{domainName}/apimappings
# operationId: CreateApiMapping
export def "domainnames-apimappings create-mapping" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The identifier.
  --api-mapping-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  stage: string # A string with a length between [1-128].
]: any -> record<ApiId: record, ApiMappingId: record, ApiMappingKey: record, Stage: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domainnames/{domain_name}/apimappings"))
  let req_body = {"apiId": $api_id, "apiMappingKey": $api_mapping_key, "stage": $stage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets API mappings.
#
# GET /v2/domainnames/{domainName}/apimappings
# operationId: GetApiMappings
export def "domainnames-apimappings get-mappings" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domainnames/{domain_name}/apimappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates an Authorizer for an API.
#
# POST /v2/apis/{apiId}/authorizers
# operationId: CreateAuthorizer
# --jwtConfiguration shape: {Audience?: any, Issuer?: any}
export def "apis-authorizers create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authorizer-credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --authorizer-payload-format-version: string # A string with a length between [1-64].
  --authorizer-result-ttl-in-seconds: int # An integer with a value between [0-3600].
  authorizer_type: string@authorizer-type-completer # The authorizer type. Specify REQUEST for a Lambda function using incoming request parameters. Specify JWT to use JSON Web Tokens (supported only for HTTP APIs).
  --authorizer-uri: string # A string representation of a URI with a length between [1-2048].
  --enable-simple-responses: oneof<nothing, bool> # Specifies whether a Lambda authorizer returns a response in a simple format. By default, a Lambda authorizer must return an IAM policy. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs. To learn more, see Working with AWS Lambda authorizers for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html)
  identity_source: list<string> # The identity source for which authorization is requested. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is $method.request.header.Auth, $method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A string with a length between [0-1024].
  --jwt-configuration: record # Represents the configuration of a JWT authorizer. Required for the JWT authorizer type. Supported only for HTTP APIs. — shape: {Audience?: any, Issuer?: any}
  name: string # A string with a length between [1-128].
]: any -> record<AuthorizerCredentialsArn: record, AuthorizerId: record, AuthorizerPayloadFormatVersion: record, AuthorizerResultTtlInSeconds: record, AuthorizerType: record, AuthorizerUri: record, EnableSimpleResponses: record, IdentitySource: record, IdentityValidationExpression: record, JwtConfiguration: record<Audience: record, Issuer: record>, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/authorizers"))
  let req_body = {"authorizerCredentialsArn": $authorizer_credentials_arn, "authorizerPayloadFormatVersion": $authorizer_payload_format_version, "authorizerResultTtlInSeconds": $authorizer_result_ttl_in_seconds, "authorizerType": $authorizer_type, "authorizerUri": $authorizer_uri, "enableSimpleResponses": $enable_simple_responses, "identitySource": $identity_source, "identityValidationExpression": $identity_validation_expression, "jwtConfiguration": $jwt_configuration, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Authorizers for an API.
#
# GET /v2/apis/{apiId}/authorizers
# operationId: GetAuthorizers
export def "apis-authorizers list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/authorizers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a Deployment for an API.
#
# POST /v2/apis/{apiId}/deployments
# operationId: CreateDeployment
export def "apis-deployments create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A string with a length between [0-1024].
  --stage-name: string # A string with a length between [1-128].
]: any -> record<AutoDeployed: record, CreatedDate: record, DeploymentId: record, DeploymentStatus: record, DeploymentStatusMessage: record, Description: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/deployments"))
  let req_body = {"description": $description, "stageName": $stage_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Deployments for an API.
#
# GET /v2/apis/{apiId}/deployments
# operationId: GetDeployments
export def "apis-deployments list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a domain name.
#
# POST /v2/domainnames
# operationId: CreateDomainName
# --domainNameConfigurations item shape: {ApiGatewayDomainName?: any, CertificateArn?: any, CertificateName?: any, CertificateUploadDate?: any, DomainNameStatus?: any, DomainNameStatusMessage?: any, EndpointType?: any, HostedZoneId?: any, SecurityPolicy?: any, OwnershipVerificationCertificateArn?: any}
# --mutualTlsAuthentication shape: {TruststoreUri?: any, TruststoreVersion?: any}
export def "domainnames create-domain-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # A string with a length between [1-512].
  --domain-name-configurations: list # The domain name configurations. — item shape: {ApiGatewayDomainName?: any, CertificateArn?: any, CertificateName?: any, CertificateUploadDate?: any, DomainNameStatus?: any, DomainNameStatusMessage?: any, EndpointType?: any, HostedZoneId?: any, SecurityPolicy?: any, OwnershipVerificationCertificateArn?: any}
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. — shape: {TruststoreUri?: any, TruststoreVersion?: any}
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> record<ApiMappingSelectionExpression: record, DomainName: record, DomainNameConfigurations: record, MutualTlsAuthentication: record<TruststoreUri: record, TruststoreVersion: record, TruststoreWarnings: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/domainnames")
  let req_body = {"domainName": $domain_name, "domainNameConfigurations": $domain_name_configurations, "mutualTlsAuthentication": $mutual_tls_authentication, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the domain names for an AWS account.
#
# GET /v2/domainnames
# operationId: GetDomainNames
export def "domainnames get-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/domainnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates an Integration.
#
# POST /v2/apis/{apiId}/integrations
# operationId: CreateIntegration
# --tlsConfig shape: {ServerNameToVerify?: any}
export def "apis-integrations create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connection-id: string # A string with a length between [1-1024].
  --connection-type: string@connection-type-completer # Represents a connection type.
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --integration-method: string # A string with a length between [1-64].
  --integration-subtype: string # A string with a length between [1-128].
  integration_type: string@integration-type-completer # Represents an API method integration type.
  --integration-uri: string # A string representation of a URI with a length between [1-2048].
  --passthrough-behavior: string@passthrough-behavior-completer # Represents passthrough behavior for an integration response. Supported only for WebSocket APIs.
  --payload-format-version: string # A string with a length between [1-64].
  --request-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --request-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --response-parameters: record # Supported only for HTTP APIs. You use response parameters to transform the HTTP response from a backend integration before returning the response to clients.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --timeout-in-millis: int # An integer with a value between [50-30000].
  --tls-config: record # The TLS configuration for a private integration. If you specify a TLS configuration, private integration traffic uses the HTTPS protocol. Supported only for HTTP APIs. — shape: {ServerNameToVerify?: any}
]: any -> record<ApiGatewayManaged: record, ConnectionId: record, ConnectionType: record, ContentHandlingStrategy: record, CredentialsArn: record, Description: record, IntegrationId: record, IntegrationMethod: record, IntegrationResponseSelectionExpression: record, IntegrationSubtype: record, IntegrationType: record, IntegrationUri: record, PassthroughBehavior: record, PayloadFormatVersion: record, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: record, TimeoutInMillis: record, TlsConfig: record<ServerNameToVerify: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/integrations"))
  let req_body = {"connectionId": $connection_id, "connectionType": $connection_type, "contentHandlingStrategy": $content_handling_strategy, "credentialsArn": $credentials_arn, "description": $description, "integrationMethod": $integration_method, "integrationSubtype": $integration_subtype, "integrationType": $integration_type, "integrationUri": $integration_uri, "passthroughBehavior": $passthrough_behavior, "payloadFormatVersion": $payload_format_version, "requestParameters": $request_parameters, "requestTemplates": $request_templates, "responseParameters": $response_parameters, "templateSelectionExpression": $template_selection_expression, "timeoutInMillis": $timeout_in_millis, "tlsConfig": $tls_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Integrations for an API.
#
# GET /v2/apis/{apiId}/integrations
# operationId: GetIntegrations
export def "apis-integrations list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/integrations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates an IntegrationResponses.
#
# POST /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses
# operationId: CreateIntegrationResponse
export def "apis-integrations-integrationresponses create-response" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  integration_response_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --response-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --response-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
]: any -> record<ContentHandlingStrategy: record, IntegrationResponseId: record, IntegrationResponseKey: record, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}/integrationresponses"))
  let req_body = {"contentHandlingStrategy": $content_handling_strategy, "integrationResponseKey": $integration_response_key, "responseParameters": $response_parameters, "responseTemplates": $response_templates, "templateSelectionExpression": $template_selection_expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the IntegrationResponses for an Integration.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses
# operationId: GetIntegrationResponses
export def "apis-integrations-integrationresponses get-responses" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}/integrationresponses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a Model for an API.
#
# POST /v2/apis/{apiId}/models
# operationId: CreateModel
export def "apis-models create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string # A string with a length between [1-256].
  --description: string # A string with a length between [0-1024].
  name: string # A string with a length between [1-128].
  schema: string # A string with a length between [0-32768].
]: any -> record<ContentType: record, Description: record, ModelId: record, Name: record, Schema: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/models"))
  let req_body = {"contentType": $content_type, "description": $description, "name": $name, "schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Models for an API.
#
# GET /v2/apis/{apiId}/models
# operationId: GetModels
export def "apis-models list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a Route for an API.
#
# POST /v2/apis/{apiId}/routes
# operationId: CreateRoute
export def "apis-routes create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-required: oneof<nothing, bool> # Specifies whether an API key is required for the route. Supported only for WebSocket APIs.
  --authorization-scopes: list<string> # A list of authorization scopes configured on a route. The scopes are used with a JWT authorizer to authorize the method invocation. The authorization works by matching the route scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any route scope matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the route scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
  --authorization-type: string@authorization-type-completer # The authorization type. For WebSocket APIs, valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer. For HTTP APIs, valid values are NONE for open access, JWT for using JSON Web Tokens, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer.
  --authorizer-id: string # The identifier.
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --operation-name: string # A string with a length between [1-64].
  --request-models: record # The route models.
  --request-parameters: record # The route parameters.
  route_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-response-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string with a length between [1-128].
]: any -> record<ApiGatewayManaged: record, ApiKeyRequired: record, AuthorizationScopes: record, AuthorizationType: record, AuthorizerId: record, ModelSelectionExpression: record, OperationName: record, RequestModels: record, RequestParameters: record, RouteId: record, RouteKey: record, RouteResponseSelectionExpression: record, Target: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/routes"))
  let req_body = {"apiKeyRequired": $api_key_required, "authorizationScopes": $authorization_scopes, "authorizationType": $authorization_type, "authorizerId": $authorizer_id, "modelSelectionExpression": $model_selection_expression, "operationName": $operation_name, "requestModels": $request_models, "requestParameters": $request_parameters, "routeKey": $route_key, "routeResponseSelectionExpression": $route_response_selection_expression, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Routes for an API.
#
# GET /v2/apis/{apiId}/routes
# operationId: GetRoutes
export def "apis-routes list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/routes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a RouteResponse for a Route.
#
# POST /v2/apis/{apiId}/routes/{routeId}/routeresponses
# operationId: CreateRouteResponse
export def "apis-routes-routeresponses create-response" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --response-models: record # The route models.
  --response-parameters: record # The route parameters.
  route_response_key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
]: any -> record<ModelSelectionExpression: record, ResponseModels: record, ResponseParameters: record, RouteResponseId: record, RouteResponseKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/routeresponses"))
  let req_body = {"modelSelectionExpression": $model_selection_expression, "responseModels": $response_models, "responseParameters": $response_parameters, "routeResponseKey": $route_response_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the RouteResponses for a Route.
#
# GET /v2/apis/{apiId}/routes/{routeId}/routeresponses
# operationId: GetRouteResponses
export def "apis-routes-routeresponses get-responses" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/routeresponses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a Stage for an API.
#
# POST /v2/apis/{apiId}/stages
# operationId: CreateStage
# --accessLogSettings shape: {DestinationArn?: any, Format?: any}
# --defaultRouteSettings shape: {DataTraceEnabled?: any, DetailedMetricsEnabled?: any, LoggingLevel?: any, ThrottlingBurstLimit?: any, ThrottlingRateLimit?: any}
export def "apis-stages create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --access-log-settings: record # Settings for logging access in a stage. — shape: {DestinationArn?: any, Format?: any}
  --auto-deploy: oneof<nothing, bool> # Specifies whether updates to an API automatically trigger a new deployment. The default value is false.
  --client-certificate-id: string # The identifier.
  --default-route-settings: record # Represents a collection of route settings. — shape: {DataTraceEnabled?: any, DetailedMetricsEnabled?: any, LoggingLevel?: any, ThrottlingBurstLimit?: any, ThrottlingRateLimit?: any}
  --deployment-id: string # The identifier.
  --description: string # A string with a length between [0-1024].
  --route-settings: record # The route settings map.
  stage_name: string # A string with a length between [1-128].
  --stage-variables: record # The stage variable map.
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> record<AccessLogSettings: record<DestinationArn: record, Format: record>, ApiGatewayManaged: record, AutoDeploy: record, ClientCertificateId: record, CreatedDate: record, DefaultRouteSettings: record<DataTraceEnabled: record, DetailedMetricsEnabled: record, LoggingLevel: record, ThrottlingBurstLimit: record, ThrottlingRateLimit: record>, DeploymentId: record, Description: record, LastDeploymentStatusMessage: record, LastUpdatedDate: record, RouteSettings: record, StageName: record, StageVariables: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/stages"))
  let req_body = {"accessLogSettings": $access_log_settings, "autoDeploy": $auto_deploy, "clientCertificateId": $client_certificate_id, "defaultRouteSettings": $default_route_settings, "deploymentId": $deployment_id, "description": $description, "routeSettings": $route_settings, "stageName": $stage_name, "stageVariables": $stage_variables, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the Stages for an API.
#
# GET /v2/apis/{apiId}/stages
# operationId: GetStages
export def "apis-stages list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/stages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Creates a VPC link.
#
# POST /v2/vpclinks
# operationId: CreateVpcLink
export def "vpclinks create-vpc-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A string with a length between [1-128].
  --security-group-ids: list<string> # A list of security group IDs for the VPC link.
  subnet_ids: list<string> # A list of subnet IDs to include in the VPC link.
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> record<CreatedDate: record, Name: record, SecurityGroupIds: record, SubnetIds: record, Tags: record, VpcLinkId: record, VpcLinkStatus: record, VpcLinkStatusMessage: record, VpcLinkVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vpclinks")
  let req_body = {"name": $name, "securityGroupIds": $security_group_ids, "subnetIds": $subnet_ids, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a collection of VPC links.
#
# GET /v2/vpclinks
# operationId: GetVpcLinks
export def "vpclinks get-vpc-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # The maximum number of elements to be returned for this resource.
  --next-token: string # The next page of elements from this collection. Not valid for the last element of the collection.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vpclinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Deletes the AccessLogSettings for a Stage. To disable access logging for a Stage, delete its AccessLogSettings.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/accesslogsettings
# operationId: DeleteAccessLogSettings
export def "apis-stages-accesslogsettings delete-access-log-settings" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}/accesslogsettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an Api resource.
#
# DELETE /v2/apis/{apiId}
# operationId: DeleteApi
export def "apis delete" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets an Api resource.
#
# GET /v2/apis/{apiId}
# operationId: GetApi
export def "apis get" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApiEndpoint: record, ApiGatewayManaged: record, ApiId: record, ApiKeySelectionExpression: record, CorsConfiguration: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreatedDate: record, Description: record, DisableSchemaValidation: record, DisableExecuteApiEndpoint: record, ImportInfo: record, Name: record, ProtocolType: record, RouteSelectionExpression: record, Tags: record, Version: record, Warnings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Puts an Api resource.
#
# PUT /v2/apis/{apiId}
# operationId: ReimportApi
export def "apis update-reimport" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basepath: string # Specifies how to interpret the base path of the API during import. Valid values are ignore, prepend, and split. The default value is ignore. To learn more, see Set the OpenAPI basePath Property (https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-import-api-basePath.html). Supported only for HTTP APIs.
  --fail-on-warnings: oneof<nothing, bool> # Specifies whether to rollback the API creation when a warning is encountered. By default, API creation continues if a warning is encountered.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The OpenAPI definition. Supported only for HTTP APIs.
]: any -> record<ApiEndpoint: record, ApiGatewayManaged: record, ApiId: record, ApiKeySelectionExpression: record, CorsConfiguration: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreatedDate: record, Description: record, DisableSchemaValidation: record, DisableExecuteApiEndpoint: record, ImportInfo: record, Name: record, ProtocolType: record, RouteSelectionExpression: record, Tags: record, Version: record, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "basepath" $basepath "scalar") (serialize-qp "failOnWarnings" $fail_on_warnings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}") $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"basepath": $basepath, "failOnWarnings": $fail_on_warnings} | compact), body: $req_body}
}

# Updates an Api resource.
#
# PATCH /v2/apis/{apiId}
# operationId: UpdateApi
# --corsConfiguration shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "apis update" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --cors-configuration: record # Represents a CORS configuration. Supported only for HTTP APIs. See Configuring CORS (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html) for more information. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --disable-schema-validation: oneof<nothing, bool> # Avoid validating models when creating a deployment. Supported only for WebSocket APIs.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint.
  --name: string # A string with a length between [1-128].
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string representation of a URI with a length between [1-2048].
  --version: string # A string with a length between [1-64].
]: any -> record<ApiEndpoint: record, ApiGatewayManaged: record, ApiId: record, ApiKeySelectionExpression: record, CorsConfiguration: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreatedDate: record, Description: record, DisableSchemaValidation: record, DisableExecuteApiEndpoint: record, ImportInfo: record, Name: record, ProtocolType: record, RouteSelectionExpression: record, Tags: record, Version: record, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}"))
  let req_body = {"apiKeySelectionExpression": $api_key_selection_expression, "corsConfiguration": $cors_configuration, "credentialsArn": $credentials_arn, "description": $description, "disableSchemaValidation": $disable_schema_validation, "disableExecuteApiEndpoint": $disable_execute_api_endpoint, "name": $name, "routeKey": $route_key, "routeSelectionExpression": $route_selection_expression, "target": $target, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an API mapping.
#
# DELETE /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# operationId: DeleteApiMapping
export def "domainnames-apimappings delete-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($api_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'apiMappingId' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), api_mapping_id: (encode-path-segment $api_mapping_id)} | format pattern "/v2/domainnames/{domain_name}/apimappings/{api_mapping_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets an API mapping.
#
# GET /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# operationId: GetApiMapping
export def "domainnames-apimappings get-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApiId: record, ApiMappingId: record, ApiMappingKey: record, Stage: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($api_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'apiMappingId' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), api_mapping_id: (encode-path-segment $api_mapping_id)} | format pattern "/v2/domainnames/{domain_name}/apimappings/{api_mapping_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The API mapping.
#
# PATCH /v2/domainnames/{domainName}/apimappings/{apiMappingId}
# operationId: UpdateApiMapping
export def "domainnames-apimappings update-mapping" [
  domain_name: string
  api_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The identifier.
  --api-mapping-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --stage: string # A string with a length between [1-128].
]: any -> record<ApiId: record, ApiMappingId: record, ApiMappingKey: record, Stage: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  if ($api_mapping_id | is-empty) { error make --unspanned { msg: "path parameter 'apiMappingId' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), api_mapping_id: (encode-path-segment $api_mapping_id)} | format pattern "/v2/domainnames/{domain_name}/apimappings/{api_mapping_id}"))
  let req_body = {"apiId": $api_id, "apiMappingKey": $api_mapping_key, "stage": $stage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an Authorizer.
#
# DELETE /v2/apis/{apiId}/authorizers/{authorizerId}
# operationId: DeleteAuthorizer
export def "apis-authorizers delete" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizerId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/v2/apis/{api_id}/authorizers/{authorizer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets an Authorizer.
#
# GET /v2/apis/{apiId}/authorizers/{authorizerId}
# operationId: GetAuthorizer
export def "apis-authorizers get" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthorizerCredentialsArn: record, AuthorizerId: record, AuthorizerPayloadFormatVersion: record, AuthorizerResultTtlInSeconds: record, AuthorizerType: record, AuthorizerUri: record, EnableSimpleResponses: record, IdentitySource: record, IdentityValidationExpression: record, JwtConfiguration: record<Audience: record, Issuer: record>, Name: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizerId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/v2/apis/{api_id}/authorizers/{authorizer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an Authorizer.
#
# PATCH /v2/apis/{apiId}/authorizers/{authorizerId}
# operationId: UpdateAuthorizer
# --jwtConfiguration shape: {Audience?: any, Issuer?: any}
export def "apis-authorizers update" [
  api_id: string
  authorizer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authorizer-credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --authorizer-payload-format-version: string # A string with a length between [1-64].
  --authorizer-result-ttl-in-seconds: int # An integer with a value between [0-3600].
  --authorizer-type: string@authorizer-type-completer # The authorizer type. Specify REQUEST for a Lambda function using incoming request parameters. Specify JWT to use JSON Web Tokens (supported only for HTTP APIs).
  --authorizer-uri: string # A string representation of a URI with a length between [1-2048].
  --enable-simple-responses: oneof<nothing, bool> # Specifies whether a Lambda authorizer returns a response in a simple format. By default, a Lambda authorizer must return an IAM policy. If enabled, the Lambda authorizer can return a boolean value instead of an IAM policy. Supported only for HTTP APIs. To learn more, see Working with AWS Lambda authorizers for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html)
  --identity-source: list<string> # The identity source for which authorization is requested. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is $method.request.header.Auth, $method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A string with a length between [0-1024].
  --jwt-configuration: record # Represents the configuration of a JWT authorizer. Required for the JWT authorizer type. Supported only for HTTP APIs. — shape: {Audience?: any, Issuer?: any}
  --name: string # A string with a length between [1-128].
]: any -> record<AuthorizerCredentialsArn: record, AuthorizerId: record, AuthorizerPayloadFormatVersion: record, AuthorizerResultTtlInSeconds: record, AuthorizerType: record, AuthorizerUri: record, EnableSimpleResponses: record, IdentitySource: record, IdentityValidationExpression: record, JwtConfiguration: record<Audience: record, Issuer: record>, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizerId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/v2/apis/{api_id}/authorizers/{authorizer_id}"))
  let req_body = {"authorizerCredentialsArn": $authorizer_credentials_arn, "authorizerPayloadFormatVersion": $authorizer_payload_format_version, "authorizerResultTtlInSeconds": $authorizer_result_ttl_in_seconds, "authorizerType": $authorizer_type, "authorizerUri": $authorizer_uri, "enableSimpleResponses": $enable_simple_responses, "identitySource": $identity_source, "identityValidationExpression": $identity_validation_expression, "jwtConfiguration": $jwt_configuration, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a CORS configuration.
#
# DELETE /v2/apis/{apiId}/cors
# operationId: DeleteCorsConfiguration
export def "apis-cors delete-configuration" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v2/apis/{api_id}/cors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a Deployment.
#
# DELETE /v2/apis/{apiId}/deployments/{deploymentId}
# operationId: DeleteDeployment
export def "apis-deployments delete" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apis/{api_id}/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a Deployment.
#
# GET /v2/apis/{apiId}/deployments/{deploymentId}
# operationId: GetDeployment
export def "apis-deployments get" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AutoDeployed: record, CreatedDate: record, DeploymentId: record, DeploymentStatus: record, DeploymentStatusMessage: record, Description: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apis/{api_id}/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Deployment.
#
# PATCH /v2/apis/{apiId}/deployments/{deploymentId}
# operationId: UpdateDeployment
export def "apis-deployments update" [
  api_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A string with a length between [0-1024].
]: any -> record<AutoDeployed: record, CreatedDate: record, DeploymentId: record, DeploymentStatus: record, DeploymentStatusMessage: record, Description: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apis/{api_id}/deployments/{deployment_id}"))
  let req_body = {"description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a domain name.
#
# DELETE /v2/domainnames/{domainName}
# operationId: DeleteDomainName
export def "domainnames delete-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a domain name.
#
# GET /v2/domainnames/{domainName}
# operationId: GetDomainName
export def "domainnames get-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApiMappingSelectionExpression: record, DomainName: record, DomainNameConfigurations: record, MutualTlsAuthentication: record<TruststoreUri: record, TruststoreVersion: record, TruststoreWarnings: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a domain name.
#
# PATCH /v2/domainnames/{domainName}
# operationId: UpdateDomainName
# --domainNameConfigurations item shape: {ApiGatewayDomainName?: any, CertificateArn?: any, CertificateName?: any, CertificateUploadDate?: any, DomainNameStatus?: any, DomainNameStatusMessage?: any, EndpointType?: any, HostedZoneId?: any, SecurityPolicy?: any, OwnershipVerificationCertificateArn?: any}
# --mutualTlsAuthentication shape: {TruststoreUri?: any, TruststoreVersion?: any}
export def "domainnames update-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --domain-name-configurations: list # The domain name configurations. — item shape: {ApiGatewayDomainName?: any, CertificateArn?: any, CertificateName?: any, CertificateUploadDate?: any, DomainNameStatus?: any, DomainNameStatusMessage?: any, EndpointType?: any, HostedZoneId?: any, SecurityPolicy?: any, OwnershipVerificationCertificateArn?: any}
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. — shape: {TruststoreUri?: any, TruststoreVersion?: any}
]: any -> record<ApiMappingSelectionExpression: record, DomainName: record, DomainNameConfigurations: record, MutualTlsAuthentication: record<TruststoreUri: record, TruststoreVersion: record, TruststoreWarnings: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domainnames/{domain_name}"))
  let req_body = {"domainNameConfigurations": $domain_name_configurations, "mutualTlsAuthentication": $mutual_tls_authentication} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an Integration.
#
# DELETE /v2/apis/{apiId}/integrations/{integrationId}
# operationId: DeleteIntegration
export def "apis-integrations delete" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets an Integration.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}
# operationId: GetIntegration
export def "apis-integrations get" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApiGatewayManaged: record, ConnectionId: record, ConnectionType: record, ContentHandlingStrategy: record, CredentialsArn: record, Description: record, IntegrationId: record, IntegrationMethod: record, IntegrationResponseSelectionExpression: record, IntegrationSubtype: record, IntegrationType: record, IntegrationUri: record, PassthroughBehavior: record, PayloadFormatVersion: record, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: record, TimeoutInMillis: record, TlsConfig: record<ServerNameToVerify: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an Integration.
#
# PATCH /v2/apis/{apiId}/integrations/{integrationId}
# operationId: UpdateIntegration
# --tlsConfig shape: {ServerNameToVerify?: any}
export def "apis-integrations update" [
  api_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connection-id: string # A string with a length between [1-1024].
  --connection-type: string@connection-type-completer # Represents a connection type.
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --credentials-arn: string # Represents an Amazon Resource Name (ARN).
  --description: string # A string with a length between [0-1024].
  --integration-method: string # A string with a length between [1-64].
  --integration-subtype: string # A string with a length between [1-128].
  --integration-type: string@integration-type-completer # Represents an API method integration type.
  --integration-uri: string # A string representation of a URI with a length between [1-2048].
  --passthrough-behavior: string@passthrough-behavior-completer # Represents passthrough behavior for an integration response. Supported only for WebSocket APIs.
  --payload-format-version: string # A string with a length between [1-64].
  --request-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --request-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --response-parameters: record # Supported only for HTTP APIs. You use response parameters to transform the HTTP response from a backend integration before returning the response to clients.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --timeout-in-millis: int # An integer with a value between [50-30000].
  --tls-config: record # The TLS configuration for a private integration. If you specify a TLS configuration, private integration traffic uses the HTTPS protocol. Supported only for HTTP APIs. — shape: {ServerNameToVerify?: any}
]: any -> record<ApiGatewayManaged: record, ConnectionId: record, ConnectionType: record, ContentHandlingStrategy: record, CredentialsArn: record, Description: record, IntegrationId: record, IntegrationMethod: record, IntegrationResponseSelectionExpression: record, IntegrationSubtype: record, IntegrationType: record, IntegrationUri: record, PassthroughBehavior: record, PayloadFormatVersion: record, RequestParameters: record, RequestTemplates: record, ResponseParameters: record, TemplateSelectionExpression: record, TimeoutInMillis: record, TlsConfig: record<ServerNameToVerify: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}"))
  let req_body = {"connectionId": $connection_id, "connectionType": $connection_type, "contentHandlingStrategy": $content_handling_strategy, "credentialsArn": $credentials_arn, "description": $description, "integrationMethod": $integration_method, "integrationSubtype": $integration_subtype, "integrationType": $integration_type, "integrationUri": $integration_uri, "passthroughBehavior": $passthrough_behavior, "payloadFormatVersion": $payload_format_version, "requestParameters": $request_parameters, "requestTemplates": $request_templates, "responseParameters": $response_parameters, "templateSelectionExpression": $template_selection_expression, "timeoutInMillis": $timeout_in_millis, "tlsConfig": $tls_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an IntegrationResponses.
#
# DELETE /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# operationId: DeleteIntegrationResponse
export def "apis-integrations-integrationresponses delete-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  if ($integration_response_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id), integration_response_id: (encode-path-segment $integration_response_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}/integrationresponses/{integration_response_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets an IntegrationResponses.
#
# GET /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# operationId: GetIntegrationResponse
export def "apis-integrations-integrationresponses get-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ContentHandlingStrategy: record, IntegrationResponseId: record, IntegrationResponseKey: record, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  if ($integration_response_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id), integration_response_id: (encode-path-segment $integration_response_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}/integrationresponses/{integration_response_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an IntegrationResponses.
#
# PATCH /v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}
# operationId: UpdateIntegrationResponse
export def "apis-integrations-integrationresponses update-response" [
  api_id: string
  integration_id: string
  integration_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-handling-strategy: string@content-handling-strategy-completer # Specifies how to handle response payload content type conversions. Supported only for WebSocket APIs.
  --integration-response-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --response-parameters: record # For WebSocket APIs, a key-value map specifying request parameters that are passed from the method request to the backend. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the backend. The method request parameter value must match the pattern of method.request.{location}.{name} , where {location} is querystring, path, or header; and {name} must be a valid and unique method request parameter name. For HTTP API integrations with a specified integrationSubtype, request parameters are a key-value map specifying parameters that are passed to AWS_PROXY integrations. You can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Working with AWS service integrations for HTTP APIs (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html). For HTTP API integrations without a specified integrationSubtype request parameters are a key-value map specifying how to transform HTTP requests before sending them to the backend. The key should follow the pattern <action>:<header|querystring|path>.<location> where action can be append, overwrite or remove. For values, you can provide static values, or map request data, stage variables, or context variables that are evaluated at runtime. To learn more, see Transforming API requests and responses (https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html).
  --response-templates: record # A mapping of identifier keys to templates. The value is an actual template script. The key is typically a SelectionKey which is chosen based on evaluating a selection expression.
  --template-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
]: any -> record<ContentHandlingStrategy: record, IntegrationResponseId: record, IntegrationResponseKey: record, ResponseParameters: record, ResponseTemplates: record, TemplateSelectionExpression: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  if ($integration_response_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), integration_id: (encode-path-segment $integration_id), integration_response_id: (encode-path-segment $integration_response_id)} | format pattern "/v2/apis/{api_id}/integrations/{integration_id}/integrationresponses/{integration_response_id}"))
  let req_body = {"contentHandlingStrategy": $content_handling_strategy, "integrationResponseKey": $integration_response_key, "responseParameters": $response_parameters, "responseTemplates": $response_templates, "templateSelectionExpression": $template_selection_expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Model.
#
# DELETE /v2/apis/{apiId}/models/{modelId}
# operationId: DeleteModel
export def "apis-models delete" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), model_id: (encode-path-segment $model_id)} | format pattern "/v2/apis/{api_id}/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a Model.
#
# GET /v2/apis/{apiId}/models/{modelId}
# operationId: GetModel
export def "apis-models get" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ContentType: record, Description: record, ModelId: record, Name: record, Schema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), model_id: (encode-path-segment $model_id)} | format pattern "/v2/apis/{api_id}/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Model.
#
# PATCH /v2/apis/{apiId}/models/{modelId}
# operationId: UpdateModel
export def "apis-models update" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --content-type: string # A string with a length between [1-256].
  --description: string # A string with a length between [0-1024].
  --name: string # A string with a length between [1-128].
  --schema: string # A string with a length between [0-32768].
]: any -> record<ContentType: record, Description: record, ModelId: record, Name: record, Schema: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), model_id: (encode-path-segment $model_id)} | format pattern "/v2/apis/{api_id}/models/{model_id}"))
  let req_body = {"contentType": $content_type, "description": $description, "name": $name, "schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Route.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}
# operationId: DeleteRoute
export def "apis-routes delete" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a Route.
#
# GET /v2/apis/{apiId}/routes/{routeId}
# operationId: GetRoute
export def "apis-routes get" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApiGatewayManaged: record, ApiKeyRequired: record, AuthorizationScopes: record, AuthorizationType: record, AuthorizerId: record, ModelSelectionExpression: record, OperationName: record, RequestModels: record, RequestParameters: record, RouteId: record, RouteKey: record, RouteResponseSelectionExpression: record, Target: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Route.
#
# PATCH /v2/apis/{apiId}/routes/{routeId}
# operationId: UpdateRoute
export def "apis-routes update" [
  api_id: string
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --api-key-required: oneof<nothing, bool> # Specifies whether an API key is required for the route. Supported only for WebSocket APIs.
  --authorization-scopes: list<string> # A list of authorization scopes configured on a route. The scopes are used with a JWT authorizer to authorize the method invocation. The authorization works by matching the route scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any route scope matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the route scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
  --authorization-type: string@authorization-type-completer # The authorization type. For WebSocket APIs, valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer. For HTTP APIs, valid values are NONE for open access, JWT for using JSON Web Tokens, AWS_IAM for using AWS IAM permissions, and CUSTOM for using a Lambda authorizer.
  --authorizer-id: string # The identifier.
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --operation-name: string # A string with a length between [1-64].
  --request-models: record # The route models.
  --request-parameters: record # The route parameters.
  --route-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
  --route-response-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --target: string # A string with a length between [1-128].
]: any -> record<ApiGatewayManaged: record, ApiKeyRequired: record, AuthorizationScopes: record, AuthorizationType: record, AuthorizerId: record, ModelSelectionExpression: record, OperationName: record, RequestModels: record, RequestParameters: record, RouteId: record, RouteKey: record, RouteResponseSelectionExpression: record, Target: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}"))
  let req_body = {"apiKeyRequired": $api_key_required, "authorizationScopes": $authorization_scopes, "authorizationType": $authorization_type, "authorizerId": $authorizer_id, "modelSelectionExpression": $model_selection_expression, "operationName": $operation_name, "requestModels": $request_models, "requestParameters": $request_parameters, "routeKey": $route_key, "routeResponseSelectionExpression": $route_response_selection_expression, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a route request parameter.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}/requestparameters/{requestParameterKey}
# operationId: DeleteRouteRequestParameter
export def "apis-routes-requestparameters delete-request-parameter" [
  api_id: string
  route_id: string
  request_parameter_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  if ($request_parameter_key | is-empty) { error make --unspanned { msg: "path parameter 'requestParameterKey' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id), request_parameter_key: (encode-path-segment $request_parameter_key)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/requestparameters/{request_parameter_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a RouteResponse.
#
# DELETE /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# operationId: DeleteRouteResponse
export def "apis-routes-routeresponses delete-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  if ($route_response_id | is-empty) { error make --unspanned { msg: "path parameter 'routeResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id), route_response_id: (encode-path-segment $route_response_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/routeresponses/{route_response_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a RouteResponse.
#
# GET /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# operationId: GetRouteResponse
export def "apis-routes-routeresponses get-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ModelSelectionExpression: record, ResponseModels: record, ResponseParameters: record, RouteResponseId: record, RouteResponseKey: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  if ($route_response_id | is-empty) { error make --unspanned { msg: "path parameter 'routeResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id), route_response_id: (encode-path-segment $route_response_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/routeresponses/{route_response_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a RouteResponse.
#
# PATCH /v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}
# operationId: UpdateRouteResponse
export def "apis-routes-routeresponses update-response" [
  api_id: string
  route_id: string
  route_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --model-selection-expression: string # An expression used to extract information at runtime. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for more information.
  --response-models: record # The route models.
  --response-parameters: record # The route parameters.
  --route-response-key: string # After evaluating a selection expression, the result is compared against one or more selection keys to find a matching key. See Selection Expressions (https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-selection-expressions.html#apigateway-websocket-api-apikey-selection-expressions) for a list of expressions and each expression's associated selection key type.
]: any -> record<ModelSelectionExpression: record, ResponseModels: record, ResponseParameters: record, RouteResponseId: record, RouteResponseKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'routeId' must be non-empty" } }
  if ($route_response_id | is-empty) { error make --unspanned { msg: "path parameter 'routeResponseId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), route_id: (encode-path-segment $route_id), route_response_id: (encode-path-segment $route_response_id)} | format pattern "/v2/apis/{api_id}/routes/{route_id}/routeresponses/{route_response_id}"))
  let req_body = {"modelSelectionExpression": $model_selection_expression, "responseModels": $response_models, "responseParameters": $response_parameters, "routeResponseKey": $route_response_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the RouteSettings for a stage.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}
# operationId: DeleteRouteSettings
export def "apis-stages-routesettings delete-route-settings" [
  api_id: string
  stage_name: string
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  if ($route_key | is-empty) { error make --unspanned { msg: "path parameter 'routeKey' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name), route_key: (encode-path-segment $route_key)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}/routesettings/{route_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a Stage.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}
# operationId: DeleteStage
export def "apis-stages delete" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a Stage.
#
# GET /v2/apis/{apiId}/stages/{stageName}
# operationId: GetStage
export def "apis-stages get" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AccessLogSettings: record<DestinationArn: record, Format: record>, ApiGatewayManaged: record, AutoDeploy: record, ClientCertificateId: record, CreatedDate: record, DefaultRouteSettings: record<DataTraceEnabled: record, DetailedMetricsEnabled: record, LoggingLevel: record, ThrottlingBurstLimit: record, ThrottlingRateLimit: record>, DeploymentId: record, Description: record, LastDeploymentStatusMessage: record, LastUpdatedDate: record, RouteSettings: record, StageName: record, StageVariables: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Stage.
#
# PATCH /v2/apis/{apiId}/stages/{stageName}
# operationId: UpdateStage
# --accessLogSettings shape: {DestinationArn?: any, Format?: any}
# --defaultRouteSettings shape: {DataTraceEnabled?: any, DetailedMetricsEnabled?: any, LoggingLevel?: any, ThrottlingBurstLimit?: any, ThrottlingRateLimit?: any}
export def "apis-stages update" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --access-log-settings: record # Settings for logging access in a stage. — shape: {DestinationArn?: any, Format?: any}
  --auto-deploy: oneof<nothing, bool> # Specifies whether updates to an API automatically trigger a new deployment. The default value is false.
  --client-certificate-id: string # The identifier.
  --default-route-settings: record # Represents a collection of route settings. — shape: {DataTraceEnabled?: any, DetailedMetricsEnabled?: any, LoggingLevel?: any, ThrottlingBurstLimit?: any, ThrottlingRateLimit?: any}
  --deployment-id: string # The identifier.
  --description: string # A string with a length between [0-1024].
  --route-settings: record # The route settings map.
  --stage-variables: record # The stage variable map.
]: any -> record<AccessLogSettings: record<DestinationArn: record, Format: record>, ApiGatewayManaged: record, AutoDeploy: record, ClientCertificateId: record, CreatedDate: record, DefaultRouteSettings: record<DataTraceEnabled: record, DetailedMetricsEnabled: record, LoggingLevel: record, ThrottlingBurstLimit: record, ThrottlingRateLimit: record>, DeploymentId: record, Description: record, LastDeploymentStatusMessage: record, LastUpdatedDate: record, RouteSettings: record, StageName: record, StageVariables: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}"))
  let req_body = {"accessLogSettings": $access_log_settings, "autoDeploy": $auto_deploy, "clientCertificateId": $client_certificate_id, "defaultRouteSettings": $default_route_settings, "deploymentId": $deployment_id, "description": $description, "routeSettings": $route_settings, "stageVariables": $stage_variables} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a VPC link.
#
# DELETE /v2/vpclinks/{vpcLinkId}
# operationId: DeleteVpcLink
export def "vpclinks delete-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_link_id | is-empty) { error make --unspanned { msg: "path parameter 'vpcLinkId' must be non-empty" } }
  let full_url = (build-url $base ({vpc_link_id: (encode-path-segment $vpc_link_id)} | format pattern "/v2/vpclinks/{vpc_link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a VPC link.
#
# GET /v2/vpclinks/{vpcLinkId}
# operationId: GetVpcLink
export def "vpclinks get-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CreatedDate: record, Name: record, SecurityGroupIds: record, SubnetIds: record, Tags: record, VpcLinkId: record, VpcLinkStatus: record, VpcLinkStatusMessage: record, VpcLinkVersion: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_link_id | is-empty) { error make --unspanned { msg: "path parameter 'vpcLinkId' must be non-empty" } }
  let full_url = (build-url $base ({vpc_link_id: (encode-path-segment $vpc_link_id)} | format pattern "/v2/vpclinks/{vpc_link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a VPC link.
#
# PATCH /v2/vpclinks/{vpcLinkId}
# operationId: UpdateVpcLink
export def "vpclinks update-vpc-link" [
  vpc_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # A string with a length between [1-128].
]: any -> record<CreatedDate: record, Name: record, SecurityGroupIds: record, SubnetIds: record, Tags: record, VpcLinkId: record, VpcLinkStatus: record, VpcLinkStatusMessage: record, VpcLinkVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_link_id | is-empty) { error make --unspanned { msg: "path parameter 'vpcLinkId' must be non-empty" } }
  let full_url = (build-url $base ({vpc_link_id: (encode-path-segment $vpc_link_id)} | format pattern "/v2/vpclinks/{vpc_link_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /v2/apis/{apiId}/exports/{specification}
#
# operationId: ExportApi
export def "apis-exports export" [
  api_id: string
  specification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --export-version: string # The version of the API Gateway export algorithm. API Gateway uses the latest version by default. Currently, the only supported version is 1.0.
  --include-extensions: oneof<nothing, bool> # Specifies whether to include API Gateway extensions (https://docs.aws.amazon.com//apigateway/latest/developerguide/api-gateway-swagger-extensions.html) in the exported API definition. API Gateway extensions are included by default.
  --output-type: string # The output type of the exported definition file. Valid values are JSON and YAML.
  --stage-name: string # The name of the API stage to export. If you don't specify this property, a representation of the latest API configuration is exported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($specification | is-empty) { error make --unspanned { msg: "path parameter 'specification' must be non-empty" } }
  let qp = [(serialize-qp "exportVersion" $export_version "scalar") (serialize-qp "includeExtensions" $include_extensions "scalar") (serialize-qp "outputType" $output_type "scalar") (serialize-qp "stageName" $stage_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), specification: (encode-path-segment $specification)} | format pattern "/v2/apis/{api_id}/exports/{specification}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"exportVersion": $export_version, "includeExtensions": $include_extensions, "outputType": $output_type, "stageName": $stage_name} | compact), body: null}
}

# Resets all authorizer cache entries on a stage. Supported only for HTTP APIs.
#
# DELETE /v2/apis/{apiId}/stages/{stageName}/cache/authorizers
# operationId: ResetAuthorizersCache
export def "apis-stages-cache-authorizers reset" [
  api_id: string
  stage_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stageName' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/v2/apis/{api_id}/stages/{stage_name}/cache/authorizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a model template.
#
# GET /v2/apis/{apiId}/models/{modelId}/template
# operationId: GetModelTemplate
export def "apis-models-template get" [
  api_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Value: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), model_id: (encode-path-segment $model_id)} | format pattern "/v2/apis/{api_id}/models/{model_id}/template"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a collection of Tag resources.
#
# GET /v2/tags/{resource-arn}
# operationId: GetTags
export def "tags get" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v2/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new Tag resource to represent a tag.
#
# POST /v2/tags/{resource-arn}
# operationId: TagResource
export def "tags tag" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --tags: record # Represents a collection of tags associated with the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v2/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Tag.
#
# DELETE /v2/tags/{resource-arn}
# operationId: UntagResource
export def "tags untag" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The Tag keys to delete
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v2/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
