# Auto-generated client for Amazon API Gateway v2015-07-09
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apigateway/2015-07-09/openapi.json
# Auth: --token flag or $env.AMAZON_API_GATEWAY_TOKEN

const BASE_URL = "http://apigateway.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_API_GATEWAY_TOKEN | default "" }
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
def type-completer [] { ["COGNITO_USER_POOLS" "REQUEST" "TOKEN"] }
def cache-cluster-size-completer [] { ["0.5" "1.6" "118" "13.5" "237" "28.4" "58.2" "6.1"] }
def type-completer-1 [] { ["API" "AUTHORIZER" "METHOD" "MODEL" "PATH_PARAMETER" "QUERY_PARAMETER" "REQUEST_BODY" "REQUEST_HEADER" "RESOURCE" "RESPONSE" "RESPONSE_BODY" "RESPONSE_HEADER"] }
def location-status-completer [] { ["DOCUMENTED" "UNDOCUMENTED"] }
def mode-completer [] { ["merge" "overwrite"] }
def security-policy-completer [] { ["TLS_1_0" "TLS_1_2"] }
def api-key-source-completer [] { ["AUTHORIZER" "HEADER"] }
def type-completer-2 [] { ["AWS" "AWS_PROXY" "HTTP" "HTTP_PROXY" "MOCK"] }
def connection-type-completer [] { ["INTERNET" "VPC_LINK"] }
def content-handling-completer [] { ["CONVERT_TO_BINARY" "CONVERT_TO_TEXT"] }
def format-completer [] { ["csv"] }
def mode-completer-1 [] { ["import"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apikeys create-key" } } | get name | first)
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

# Create an ApiKey resource.
#
# POST /apikeys
# operationId: CreateApiKey
# --stageKeys item shape: {restApiId?: any, stageName?: any}
export def "apikeys create-key" [
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
  --name: string # The name of the ApiKey.
  --description: string # The description of the ApiKey.
  --enabled: oneof<nothing, bool> # Specifies whether the ApiKey can be used by callers.
  --generate-distinct-id: oneof<nothing, bool> # Specifies whether (true) or not (false) the key identifier is distinct from the created API key value. This parameter is deprecated and should not be used.
  --value: string # Specifies a value of the API key.
  --stage-keys: list # DEPRECATED FOR USAGE PLANS - Specifies stages associated with the API key. — item shape: {restApiId?: any, stageName?: any}
  --customer-id: string # An AWS Marketplace customer identifier , when integrating with the AWS SaaS Marketplace.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> record<id: record, value: record, name: record, customerId: record, description: record, enabled: record, createdDate: record, lastUpdatedDate: record, stageKeys: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apikeys")
  let req_body = {"name": $name, "description": $description, "enabled": $enabled, "generateDistinctId": $generate_distinct_id, "value": $value, "stageKeys": $stage_keys, "customerId": $customer_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the current ApiKeys resource.
#
# GET /apikeys
# operationId: GetApiKeys
export def "apikeys get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # The name of queried API keys.
  --customer-id: string # The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  --include-values: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains key values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<warnings: record, position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "includeValues" $include_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit, "name": $name, "customerId": $customer_id, "includeValues": $include_values} | compact), body: null}
}

# Adds a new Authorizer resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/authorizers
# operationId: CreateAuthorizer
export def "restapis-authorizers create" [
  restapi_id: string
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
  name: string # The name of the authorizer.
  type: string@type-completer # The authorizer type. Valid values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, and COGNITO_USER_POOLS for using an Amazon Cognito user pool.
  --provider-ar-ns: list<string> # A list of the Amazon Cognito user pool ARNs for the COGNITO_USER_POOLS authorizer. Each element is of this format: arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}. For a TOKEN or REQUEST authorizer, this is not defined.
  --auth-type: string # Optional customer-defined field, used in OpenAPI imports and exports without functional impact.
  --authorizer-uri: string # Specifies the authorizer's Uniform Resource Identifier (URI). For TOKEN or REQUEST authorizers, this must be a well-formed Lambda function URI, for example, arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:{account_id}:function:{lambda_function_name}/invocations. In general, the URI has this form arn:aws:apigateway:{region}:lambda:path/{service_api}, where {region} is the same as the region hosting the Lambda function, path indicates that the remaining substring in the URI should be treated as the path to the resource, including the initial /. For Lambda functions, this is usually of the form /2015-03-31/functions/[FunctionARN]/invocations.
  --authorizer-credentials: string # Specifies the required credentials as an IAM role for API Gateway to invoke the authorizer. To specify an IAM role for API Gateway to assume, use the role's Amazon Resource Name (ARN). To use resource-based permissions on the Lambda function, specify null.
  --identity-source: string # The identity source for which authorization is requested. For a TOKEN or COGNITO_USER_POOLS authorizer, this is required and specifies the request header mapping expression for the custom header holding the authorization token submitted by the client. For example, if the token header name is Auth, the header mapping expression is method.request.header.Auth. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is method.request.header.Auth, method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A validation expression for the incoming identity token. For TOKEN authorizers, this value is a regular expression. For COGNITO_USER_POOLS authorizers, API Gateway will match the aud field of the incoming token from the client against the specified regular expression. It will invoke the authorizer's Lambda function when there is a match. Otherwise, it will return a 401 Unauthorized response without calling the Lambda function. The validation expression does not apply to the REQUEST authorizer.
  --authorizer-result-ttl-in-seconds: int # The TTL in seconds of cached authorizer results. If it equals 0, authorization caching is disabled. If it is greater than 0, API Gateway will cache authorizer responses. If this field is not set, the default value is 300. The maximum value is 3600, or 1 hour.
]: any -> record<id: record, name: record, type: record, providerARNs: record, authType: record, authorizerUri: record, authorizerCredentials: record, identitySource: record, identityValidationExpression: record, authorizerResultTtlInSeconds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/authorizers"))
  let req_body = {"name": $name, "type": $type, "providerARNs": $provider_ar_ns, "authType": $auth_type, "authorizerUri": $authorizer_uri, "authorizerCredentials": $authorizer_credentials, "identitySource": $identity_source, "identityValidationExpression": $identity_validation_expression, "authorizerResultTtlInSeconds": $authorizer_result_ttl_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describe an existing Authorizers resource.
#
# GET /restapis/{restapi_id}/authorizers
# operationId: GetAuthorizers
export def "restapis-authorizers list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/authorizers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a new BasePathMapping resource.
#
# POST /domainnames/{domain_name}/basepathmappings
# operationId: CreateBasePathMapping
export def "domainnames-basepathmappings create-base-path-mapping" [
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
  --base-path: string # The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify a base path name after the domain name.
  rest_api_id: string # The string identifier of the associated RestApi.
  --stage: string # The name of the API's stage that you want to use for this mapping. Specify '(none)' if you want callers to explicitly specify the stage name after any base path name.
]: any -> record<basePath: record, restApiId: record, stage: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}/basepathmappings"))
  let req_body = {"basePath": $base_path, "restApiId": $rest_api_id, "stage": $stage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents a collection of BasePathMapping resources.
#
# GET /domainnames/{domain_name}/basepathmappings
# operationId: GetBasePathMappings
export def "domainnames-basepathmappings get-base-path-mappings" [
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}/basepathmappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a Deployment resource, which makes a specified RestApi callable over the internet.
#
# POST /restapis/{restapi_id}/deployments
# operationId: CreateDeployment
# --canarySettings shape: {percentTraffic?: any, stageVariableOverrides?: any, useStageCache?: any}
export def "restapis-deployments create" [
  restapi_id: string
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
  --stage-name: string # The name of the Stage resource for the Deployment resource to create.
  --stage-description: string # The description of the Stage resource for the Deployment resource to create.
  --description: string # The description for the Deployment resource to create.
  --cache-cluster-enabled: oneof<nothing, bool> # Enables a cache cluster for the Stage resource specified in the input.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the Stage resource that is associated with the new deployment. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --canary-settings: record # The input configuration for a canary deployment. — shape: {percentTraffic?: any, stageVariableOverrides?: any, useStageCache?: any}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
]: any -> record<id: record, description: record, createdDate: record, apiSummary: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/deployments"))
  let req_body = {"stageName": $stage_name, "stageDescription": $stage_description, "description": $description, "cacheClusterEnabled": $cache_cluster_enabled, "cacheClusterSize": $cache_cluster_size, "variables": $variables, "canarySettings": $canary_settings, "tracingEnabled": $tracing_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about a Deployments collection.
#
# GET /restapis/{restapi_id}/deployments
# operationId: GetDeployments
export def "restapis-deployments list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a documentation part.
#
# POST /restapis/{restapi_id}/documentation/parts
# operationId: CreateDocumentationPart
# --location shape: {type?: any, path?: any, method?: any, statusCode?: any, name?: any}
export def "restapis-documentation-parts create" [
  restapi_id: string
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
  location: record # Specifies the target API entity to which the documentation applies. — shape: {type?: any, path?: any, method?: any, statusCode?: any, name?: any}
  properties: string # The new documentation content map of the targeted API entity. Enclosed key-value pairs are API-specific, but only OpenAPI-compliant key-value pairs can be exported and, hence, published.
]: any -> record<id: record, location: record<type: record, path: record, method: record, statusCode: record, name: record>, properties: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts"))
  let req_body = {"location": $location, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets documentation parts.
#
# GET /restapis/{restapi_id}/documentation/parts
# operationId: GetDocumentationParts
export def "restapis-documentation-parts list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of API entities of the to-be-retrieved documentation parts.
  --name: string # The name of API entities of the to-be-retrieved documentation parts.
  --path: string # The path of API entities of the to-be-retrieved documentation parts.
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --location-status: string@location-status-completer # The status of the API documentation parts to retrieve. Valid values are DOCUMENTED for retrieving DocumentationPart resources with content and UNDOCUMENTED for DocumentationPart resources without content.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "locationStatus" $location_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "name": $name, "path": $path, "position": $position, "limit": $limit, "locationStatus": $location_status} | compact), body: null}
}

# Imports documentation parts
#
# PUT /restapis/{restapi_id}/documentation/parts
# operationId: ImportDocumentationParts
export def "restapis-documentation-parts import" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # A query parameter to indicate whether to overwrite (OVERWRITE) any existing DocumentationParts definition or to merge (MERGE) the new definition into the existing one. The default value is MERGE.
  --failonwarnings: oneof<nothing, bool> # A query parameter to specify whether to rollback the documentation importation (true) or not (false) when a warning is encountered. The default value is false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # Raw byte array representing the to-be-imported documentation parts. To import from an OpenAPI file, this is a JSON object.
]: any -> record<ids: record, warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts") $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"mode": $mode, "failonwarnings": $failonwarnings} | compact), body: $req_body}
}

# Creates a documentation version
#
# POST /restapis/{restapi_id}/documentation/versions
# operationId: CreateDocumentationVersion
export def "restapis-documentation-versions create" [
  restapi_id: string
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
  documentation_version: string # The version identifier of the new snapshot.
  --stage-name: string # The stage name to be associated with the new documentation snapshot.
  --description: string # A description about the new documentation snapshot.
]: any -> record<version: record, createdDate: record, description: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/versions"))
  let req_body = {"documentationVersion": $documentation_version, "stageName": $stage_name, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets documentation versions.
#
# GET /restapis/{restapi_id}/documentation/versions
# operationId: GetDocumentationVersions
export def "restapis-documentation-versions list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a new domain name.
#
# POST /domainnames
# operationId: CreateDomainName
# --endpointConfiguration shape: {types?: any, vpcEndpointIds?: any}
# --mutualTlsAuthentication shape: {truststoreUri?: any, truststoreVersion?: any}
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
  domain_name: string # The name of the DomainName resource.
  --certificate-name: string # The user-friendly name of the certificate that will be used by edge-optimized endpoint for this domain name.
  --certificate-body: string # [Deprecated] The body of the server certificate that will be used by edge-optimized endpoint for this domain name provided by your certificate authority.
  --certificate-private-key: string # [Deprecated] Your edge-optimized endpoint's domain name certificate's private key.
  --certificate-chain: string # [Deprecated] The intermediate certificates and optionally the root certificate, one after the other without any blank lines, used by an edge-optimized endpoint for this domain name. If you include the root certificate, your certificate chain must start with intermediate certificates and end with the root certificate. Use the intermediate certificates that were provided by your certificate authority. Do not include any intermediaries that are not in the chain of trust path.
  --certificate-arn: string # The reference to an AWS-managed certificate that will be used by edge-optimized endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --regional-certificate-name: string # The user-friendly name of the certificate that will be used by regional endpoint for this domain name.
  --regional-certificate-arn: string # The reference to an AWS-managed certificate that will be used by regional endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: any, vpcEndpointIds?: any}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --security-policy: string@security-policy-completer # The Transport Layer Security (TLS) version + cipher suite for this DomainName. The valid values are TLS_1_0 and TLS_1_2.
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. If specified, API Gateway performs two-way authentication between the client and the server. Clients must present a trusted certificate to access your API. — shape: {truststoreUri?: any, truststoreVersion?: any}
  --ownership-verification-certificate-arn: string # The ARN of the public certificate issued by ACM to validate ownership of your custom domain. Only required when configuring mutual TLS and using an ACM imported or private CA certificate ARN as the regionalCertificateArn.
]: any -> record<domainName: record, certificateName: record, certificateArn: record, certificateUploadDate: record, regionalDomainName: record, regionalHostedZoneId: record, regionalCertificateName: record, regionalCertificateArn: record, distributionDomainName: record, distributionHostedZoneId: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, domainNameStatus: record, domainNameStatusMessage: record, securityPolicy: record, tags: record, mutualTlsAuthentication: record<truststoreUri: record, truststoreVersion: record, truststoreWarnings: record>, ownershipVerificationCertificateArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domainnames")
  let req_body = {"domainName": $domain_name, "certificateName": $certificate_name, "certificateBody": $certificate_body, "certificatePrivateKey": $certificate_private_key, "certificateChain": $certificate_chain, "certificateArn": $certificate_arn, "regionalCertificateName": $regional_certificate_name, "regionalCertificateArn": $regional_certificate_arn, "endpointConfiguration": $endpoint_configuration, "tags": $tags, "securityPolicy": $security_policy, "mutualTlsAuthentication": $mutual_tls_authentication, "ownershipVerificationCertificateArn": $ownership_verification_certificate_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents a collection of DomainName resources.
#
# GET /domainnames
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domainnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Adds a new Model resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/models
# operationId: CreateModel
export def "restapis-models create" [
  restapi_id: string
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
  name: string # The name of the model. Must be alphanumeric.
  --description: string # The description of the model.
  --schema: string # The schema for the model. For application/json models, this should be JSON schema draft 4 model.
  content_type: string # The content-type for the model.
]: any -> record<id: record, name: record, description: record, schema: record, contentType: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/models"))
  let req_body = {"name": $name, "description": $description, "schema": $schema, "contentType": $content_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes existing Models defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models
# operationId: GetModels
export def "restapis-models list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a RequestValidator of a given RestApi.
#
# POST /restapis/{restapi_id}/requestvalidators
# operationId: CreateRequestValidator
export def "restapis-requestvalidators create-request-validator" [
  restapi_id: string
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
  --name: string # The name of the to-be-created RequestValidator.
  --validate-request-body: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request body according to the configured model schema for the method (true) or not (false).
  --validate-request-parameters: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request parameters, true, or not false.
]: any -> record<id: record, name: record, validateRequestBody: record, validateRequestParameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/requestvalidators"))
  let req_body = {"name": $name, "validateRequestBody": $validate_request_body, "validateRequestParameters": $validate_request_parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the RequestValidators collection of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators
# operationId: GetRequestValidators
export def "restapis-requestvalidators get-request-validators" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/requestvalidators") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a Resource resource.
#
# POST /restapis/{restapi_id}/resources/{parent_id}
# operationId: CreateResource
export def "restapis-resources create" [
  restapi_id: string
  parent_id: string
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
  path_part: string # The last path segment for this resource.
]: any -> record<id: record, parentId: record, pathPart: record, path: record, resourceMethods: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($parent_id | is-empty) { error make --unspanned { msg: "path parameter 'parent_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), parent_id: (encode-path-segment $parent_id)} | format pattern "/restapis/{restapi_id}/resources/{parent_id}"))
  let req_body = {"pathPart": $path_part} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new RestApi resource.
#
# POST /restapis
# operationId: CreateRestApi
# --endpointConfiguration shape: {types?: any, vpcEndpointIds?: any}
export def "restapis create-rest" [
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
  name: string # The name of the RestApi.
  --description: string # The description of the RestApi.
  --version: string # A version identifier for the API.
  --clone-from: string # The ID of the RestApi that you want to clone from.
  --binary-media-types: list<string> # The list of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads.
  --minimum-compression-size: int # A nullable integer that is used to enable compression (with non-negative between 0 and 10485760 (10M) bytes, inclusive) or disable compression (with a null value) on an API. When compression is enabled, compression or decompression is not applied on the payload if the payload size is smaller than this value. Setting it to zero allows compression for any payload size.
  --api-key-source: string@api-key-source-completer # The source of the API key for metering requests according to a usage plan. Valid values are: >HEADER to read the API key from the X-API-Key header of a request. AUTHORIZER to read the API key from the UsageIdentifierKey from a custom authorizer.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: any, vpcEndpointIds?: any}
  --policy: string # A stringified JSON policy document that applies to this RestApi regardless of the caller and Method configuration.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint
]: any -> record<id: record, name: record, description: record, createdDate: record, version: record, warnings: record, binaryMediaTypes: record, minimumCompressionSize: record, apiKeySource: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, policy: record, tags: record, disableExecuteApiEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapis")
  let req_body = {"name": $name, "description": $description, "version": $version, "cloneFrom": $clone_from, "binaryMediaTypes": $binary_media_types, "minimumCompressionSize": $minimum_compression_size, "apiKeySource": $api_key_source, "endpointConfiguration": $endpoint_configuration, "policy": $policy, "tags": $tags, "disableExecuteApiEndpoint": $disable_execute_api_endpoint} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the RestApis resources for your collection.
#
# GET /restapis
# operationId: GetRestApis
export def "restapis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Creates a new Stage resource that references a pre-existing Deployment for the API.
#
# POST /restapis/{restapi_id}/stages
# operationId: CreateStage
# --canarySettings shape: {percentTraffic?: any, deploymentId?: any, stageVariableOverrides?: any, useStageCache?: any}
export def "restapis-stages create" [
  restapi_id: string
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
  stage_name: string # The name for the Stage resource. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  deployment_id: string # The identifier of the Deployment resource for the Stage resource.
  --description: string # The description of the Stage resource.
  --cache-cluster-enabled: oneof<nothing, bool> # Whether cache clustering is enabled for the stage.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the new Stage resource. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --documentation-version: string # The version of the associated API documentation.
  --canary-settings: record # Configuration settings of a canary deployment. — shape: {percentTraffic?: any, deploymentId?: any, stageVariableOverrides?: any, useStageCache?: any}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> record<deploymentId: record, clientCertificateId: record, stageName: record, description: record, cacheClusterEnabled: record, cacheClusterSize: record, cacheClusterStatus: record, methodSettings: record, variables: record, documentationVersion: record, accessLogSettings: record<format: record, destinationArn: record>, canarySettings: record<percentTraffic: record, deploymentId: record, stageVariableOverrides: record, useStageCache: record>, tracingEnabled: record, webAclArn: record, tags: record, createdDate: record, lastUpdatedDate: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/stages"))
  let req_body = {"stageName": $stage_name, "deploymentId": $deployment_id, "description": $description, "cacheClusterEnabled": $cache_cluster_enabled, "cacheClusterSize": $cache_cluster_size, "variables": $variables, "documentationVersion": $documentation_version, "canarySettings": $canary_settings, "tracingEnabled": $tracing_enabled, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about one or more Stage resources.
#
# GET /restapis/{restapi_id}/stages
# operationId: GetStages
export def "restapis-stages list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The stages' deployment identifiers.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<item: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "deploymentId" $deployment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/stages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deploymentId": $deployment_id} | compact), body: null}
}

# Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload.
#
# POST /usageplans
# operationId: CreateUsagePlan
# --apiStages item shape: {apiId?: any, stage?: any, throttle?: any}
# --throttle shape: {burstLimit?: any, rateLimit?: any}
# --quota shape: {limit?: any, offset?: any, period?: any}
export def "usageplans create-usage-plan" [
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
  name: string # The name of the usage plan.
  --description: string # The description of the usage plan.
  --api-stages: list # The associated API stages of the usage plan. — item shape: {apiId?: any, stage?: any, throttle?: any}
  --throttle: record # The API request rate limits. — shape: {burstLimit?: any, rateLimit?: any}
  --quota: record # Quotas configured for a usage plan. — shape: {limit?: any, offset?: any, period?: any}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> record<id: record, name: record, description: record, apiStages: record, throttle: record<burstLimit: record, rateLimit: record>, quota: record<limit: record, offset: record, period: record>, productCode: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usageplans")
  let req_body = {"name": $name, "description": $description, "apiStages": $api_stages, "throttle": $throttle, "quota": $quota, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all the usage plans of the caller's account.
#
# GET /usageplans
# operationId: GetUsagePlans
export def "usageplans get-usage-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --key-id: string # The identifier of the API key associated with the usage plans.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "keyId" $key_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usageplans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "keyId": $key_id, "limit": $limit} | compact), body: null}
}

# Creates a usage plan key for adding an existing API key to a usage plan.
#
# POST /usageplans/{usageplanId}/keys
# operationId: CreateUsagePlanKey
export def "usageplans-keys create-usage-plan" [
  usageplan_id: string
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
  key_id: string # The identifier of a UsagePlanKey resource for a plan customer.
  key_type: string # The type of a UsagePlanKey resource for a plan customer.
]: any -> record<id: record, type: record, value: record, name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/keys"))
  let req_body = {"keyId": $key_id, "keyType": $key_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all the usage plan keys representing the API keys added to a specified usage plan.
#
# GET /usageplans/{usageplanId}/keys
# operationId: GetUsagePlanKeys
export def "usageplans-keys list" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # A query parameter specifying the name of the to-be-returned usage plan keys.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit, "name": $name} | compact), body: null}
}

# Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
#
# POST /vpclinks
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
  name: string # The name used to label and identify the VPC link.
  --description: string # The description of the VPC link.
  target_arns: list<string> # The ARN of the network load balancer of the VPC targeted by the VPC link. The network load balancer must be owned by the same AWS account of the API owner.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> record<id: record, name: record, description: record, targetArns: record, status: record, statusMessage: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vpclinks")
  let req_body = {"name": $name, "description": $description, "targetArns": $target_arns, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the VpcLinks collection under the caller's account in a selected region.
#
# GET /vpclinks
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
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vpclinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Deletes the ApiKey resource.
#
# DELETE /apikeys/{api_Key}
# operationId: DeleteApiKey
export def "apikeys delete" [
  api_key: string
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
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the current ApiKey resource.
#
# GET /apikeys/{api_Key}
# operationId: GetApiKey
export def "apikeys get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-value: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains the key value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<id: record, value: record, name: record, customerId: record, description: record, enabled: record, createdDate: record, lastUpdatedDate: record, stageKeys: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let qp = [(serialize-qp "includeValue" $include_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeValue": $include_value} | compact), body: null}
}

# Changes information about an ApiKey resource.
#
# PATCH /apikeys/{api_Key}
# operationId: UpdateApiKey
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "apikeys update" [
  api_key: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, value: record, name: record, customerId: record, description: record, enabled: record, createdDate: record, lastUpdatedDate: record, stageKeys: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an existing Authorizer resource.
#
# DELETE /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: DeleteAuthorizer
export def "restapis-authorizers delete" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describe an existing Authorizer resource.
#
# GET /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: GetAuthorizer
export def "restapis-authorizers get" [
  restapi_id: string
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
]: nothing -> record<id: record, name: record, type: record, providerARNs: record, authType: record, authorizerUri: record, authorizerCredentials: record, identitySource: record, identityValidationExpression: record, authorizerResultTtlInSeconds: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Simulate the execution of an Authorizer in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: TestInvokeAuthorizer
export def "restapis-authorizers test-invoke" [
  restapi_id: string
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
  --headers: record # A key-value map of headers to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, should be specified.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, may be specified.
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
  --additional-context: record # A key-value map of additional context variables.
]: any -> record<clientStatus: record, log: record, latency: record, principalId: record, policy: record, authorization: record, claims: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}"))
  let req_body = {"headers": $headers, "multiValueHeaders": $multi_value_headers, "pathWithQueryString": $path_with_query_string, "body": $body, "stageVariables": $stage_variables, "additionalContext": $additional_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates an existing Authorizer resource.
#
# PATCH /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: UpdateAuthorizer
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-authorizers update" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, type: record, providerARNs: record, authType: record, authorizerUri: record, authorizerCredentials: record, identitySource: record, identityValidationExpression: record, authorizerResultTtlInSeconds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the BasePathMapping resource.
#
# DELETE /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: DeleteBasePathMapping
export def "domainnames-basepathmappings delete-mapping" [
  domain_name: string
  base_path: string
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
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describe a BasePathMapping resource.
#
# GET /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: GetBasePathMapping
export def "domainnames-basepathmappings get-mapping" [
  domain_name: string
  base_path: string
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
]: nothing -> record<basePath: record, restApiId: record, stage: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes information about the BasePathMapping resource.
#
# PATCH /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: UpdateBasePathMapping
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "domainnames-basepathmappings update-mapping" [
  domain_name: string
  base_path: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<basePath: record, restApiId: record, stage: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the ClientCertificate resource.
#
# DELETE /clientcertificates/{clientcertificate_id}
# operationId: DeleteClientCertificate
export def "clientcertificates delete-client-certificate" [
  clientcertificate_id: string
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
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the current ClientCertificate resource.
#
# GET /clientcertificates/{clientcertificate_id}
# operationId: GetClientCertificate
export def "clientcertificates get-client-certificate" [
  clientcertificate_id: string
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
]: nothing -> record<clientCertificateId: record, description: record, pemEncodedCertificate: record, createdDate: record, expirationDate: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes information about an ClientCertificate resource.
#
# PATCH /clientcertificates/{clientcertificate_id}
# operationId: UpdateClientCertificate
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "clientcertificates update-client-certificate" [
  clientcertificate_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<clientCertificateId: record, description: record, pemEncodedCertificate: record, createdDate: record, expirationDate: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Deployment resource. Deleting a deployment will only succeed if there are no Stage resources associated with it.
#
# DELETE /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: DeleteDeployment
export def "restapis-deployments delete" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about a Deployment resource.
#
# GET /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: GetDeployment
export def "restapis-deployments get" [
  restapi_id: string
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
  --embed: list # A query parameter to retrieve the specified embedded resources of the returned Deployment resource in the response. In a REST API call, this embed parameter value is a list of comma-separated strings, as in GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the "apisummary" string. For example, GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<id: record, description: record, createdDate: record, apiSummary: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed": $embed} | compact), body: null}
}

# Changes information about a Deployment resource.
#
# PATCH /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: UpdateDeployment
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-deployments update" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, description: record, createdDate: record, apiSummary: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a documentation part
#
# DELETE /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: DeleteDocumentationPart
export def "restapis-documentation-parts delete" [
  restapi_id: string
  part_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a documentation part.
#
# GET /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: GetDocumentationPart
export def "restapis-documentation-parts get" [
  restapi_id: string
  part_id: string
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
]: nothing -> record<id: record, location: record<type: record, path: record, method: record, statusCode: record, name: record>, properties: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a documentation part.
#
# PATCH /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: UpdateDocumentationPart
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-documentation-parts update" [
  restapi_id: string
  part_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, location: record<type: record, path: record, method: record, statusCode: record, name: record>, properties: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a documentation version.
#
# DELETE /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: DeleteDocumentationVersion
export def "restapis-documentation-versions delete" [
  restapi_id: string
  doc_version: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a documentation version.
#
# GET /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: GetDocumentationVersion
export def "restapis-documentation-versions get" [
  restapi_id: string
  doc_version: string
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
]: nothing -> record<version: record, createdDate: record, description: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a documentation version.
#
# PATCH /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: UpdateDocumentationVersion
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-documentation-versions update" [
  restapi_id: string
  doc_version: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<version: record, createdDate: record, description: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the DomainName resource.
#
# DELETE /domainnames/{domain_name}
# operationId: DeleteDomainName
export def "domainnames delete" [
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
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
#
# GET /domainnames/{domain_name}
# operationId: GetDomainName
export def "domainnames get" [
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
]: nothing -> record<domainName: record, certificateName: record, certificateArn: record, certificateUploadDate: record, regionalDomainName: record, regionalHostedZoneId: record, regionalCertificateName: record, regionalCertificateArn: record, distributionDomainName: record, distributionHostedZoneId: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, domainNameStatus: record, domainNameStatusMessage: record, securityPolicy: record, tags: record, mutualTlsAuthentication: record<truststoreUri: record, truststoreVersion: record, truststoreWarnings: record>, ownershipVerificationCertificateArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes information about the DomainName resource.
#
# PATCH /domainnames/{domain_name}
# operationId: UpdateDomainName
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "domainnames update" [
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<domainName: record, certificateName: record, certificateArn: record, certificateUploadDate: record, regionalDomainName: record, regionalHostedZoneId: record, regionalCertificateName: record, regionalCertificateArn: record, distributionDomainName: record, distributionHostedZoneId: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, domainNameStatus: record, domainNameStatusMessage: record, securityPolicy: record, tags: record, mutualTlsAuthentication: record<truststoreUri: record, truststoreVersion: record, truststoreWarnings: record>, ownershipVerificationCertificateArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Clears any customization of a GatewayResponse of a specified response type on the given RestApi and resets it with the default settings.
#
# DELETE /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: DeleteGatewayResponse
export def "restapis-gatewayresponses delete-gateway" [
  restapi_id: string
  response_type: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a GatewayResponse of a specified response type on the given RestApi.
#
# GET /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: GetGatewayResponse
export def "restapis-gatewayresponses get-gateway" [
  restapi_id: string
  response_type: string
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
]: nothing -> record<responseType: record, statusCode: record, responseParameters: record, responseTemplates: record, defaultResponse: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a customization of a GatewayResponse of a specified response type and status code on the given RestApi.
#
# PUT /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: PutGatewayResponse
export def "restapis-gatewayresponses update-gateway-by-restapi-id-response-type" [
  restapi_id: string
  response_type: string
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
  --status-code: string # The status code.
  --response-parameters: record # Response parameters (paths, query strings and headers) of the GatewayResponse as a string-to-string map of key-value pairs.
  --response-templates: record # Response templates of the GatewayResponse as a string-to-string map of key-value pairs.
]: any -> record<responseType: record, statusCode: record, responseParameters: record, responseTemplates: record, defaultResponse: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}"))
  let req_body = {"statusCode": $status_code, "responseParameters": $response_parameters, "responseTemplates": $response_templates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates a GatewayResponse of a specified response type on the given RestApi.
#
# PATCH /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: UpdateGatewayResponse
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-gatewayresponses update-gateway-by-restapi-id-response-type-1" [
  restapi_id: string
  response_type: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<responseType: record, statusCode: record, responseParameters: record, responseTemplates: record, defaultResponse: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents a delete integration.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: DeleteIntegration
export def "restapis-resources-methods-integration delete" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the integration settings.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: GetIntegration
export def "restapis-resources-methods-integration get" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets up a method's integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: PutIntegration
# --tlsConfig shape: {insecureSkipVerification?: any}
export def "restapis-resources-methods-integration update-by-restapi-id-resource-id-http-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  type: string@type-completer-2 # The integration type. The valid value is HTTP for integrating an API method with an HTTP backend; AWS with any AWS service endpoints; MOCK for testing without actually invoking the backend; HTTP_PROXY for integrating with the HTTP proxy integration; AWS_PROXY for integrating with the Lambda proxy integration.
  --body-http-method: string # The HTTP method for the integration.
  --uri: string # Specifies Uniform Resource Identifier (URI) of the integration endpoint. For HTTP or HTTP_PROXY integrations, the URI must be a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification, for either standard integration, where connectionType is not VPC_LINK, or private integration, where connectionType is VPC_LINK. For a private HTTP integration, the URI is not used for routing. For AWS or AWS_PROXY integrations, the URI is of the form arn:aws:apigateway:{region}:{subdomain.service|service}:path|action/{service_api}. Here, {Region} is the API Gateway region (e.g., us-east-1); {service} is the name of the integrated Amazon Web Services service (e.g., s3); and {subdomain} is a designated subdomain supported by certain Amazon Web Services service for fast host-name lookup. action can be used for an Amazon Web Services service action-based API, using an Action={name}&{p1}={v1}&p2={v2}... query string. The ensuing {service_api} refers to a supported action {name} plus any required input parameters. Alternatively, path can be used for an Amazon Web Services service path-based API. The ensuing service_api refers to the path to an Amazon Web Services service resource, including the region of the integrated Amazon Web Services service, if applicable. For example, for integration with the S3 API of GetObject, the uri can be either arn:aws:apigateway:us-west-2:s3:action/GetObject&Bucket={bucket}&Key={key} or arn:aws:apigateway:us-west-2:s3:path/{bucket}/{key}.
  --connection-type: string@connection-type-completer # The type of the network connection to the integration endpoint. The valid value is INTERNET for connections through the public routable internet or VPC_LINK for private connections between API Gateway and a network load balancer in a VPC. The default value is INTERNET.
  --connection-id: string # The ID of the VpcLink used for the integration. Specify this value only if you specify VPC_LINK as the connection type.
  --credentials: string # Specifies whether credentials are required for a put integration.
  --request-parameters: record # A key-value map specifying request parameters that are passed from the method request to the back end. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the back end. The method request parameter value must match the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name must be a valid and unique method request parameter name.
  --request-templates: record # Represents a map of Velocity templates that are applied on the request payload based on the value of the Content-Type header sent by the client. The content type value is the key in this map, and the template (as a String) is the value.
  --passthrough-behavior: string # Specifies the pass-through behavior for incoming requests based on the Content-Type header in the request, and the available mapping templates specified as the requestTemplates property on the Integration resource. There are three valid values: WHEN_NO_MATCH, WHEN_NO_TEMPLATES, and NEVER.
  --cache-namespace: string # Specifies a group of related cached parameters. By default, API Gateway uses the resource ID as the cacheNamespace. You can specify the same cacheNamespace across resources to return the same cached data for requests to different resources.
  --cache-key-parameters: list<string> # A list of request parameters whose values API Gateway caches. To be valid values for cacheKeyParameters, these parameters must also be specified for Method requestParameters.
  --content-handling: string@content-handling-completer # Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the request payload will be passed through from the method request to integration request without modification, provided that the passthroughBehavior is configured to support payload pass-through.
  --timeout-in-millis: int # Custom timeout between 50 and 29,000 milliseconds. The default value is 29,000 milliseconds or 29 seconds.
  --tls-config: record # Specifies the TLS configuration for an integration. — shape: {insecureSkipVerification?: any}
]: any -> record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"))
  let req_body = {"type": $type, "httpMethod": $body_http_method, "uri": $uri, "connectionType": $connection_type, "connectionId": $connection_id, "credentials": $credentials, "requestParameters": $request_parameters, "requestTemplates": $request_templates, "passthroughBehavior": $passthrough_behavior, "cacheNamespace": $cache_namespace, "cacheKeyParameters": $cache_key_parameters, "contentHandling": $content_handling, "timeoutInMillis": $timeout_in_millis, "tlsConfig": $tls_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents an update integration.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: UpdateIntegration
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-resources-methods-integration update-by-restapi-id-resource-id-http-method-1" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents a delete integration response.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: DeleteIntegrationResponse
export def "restapis-resources-methods-integration-responses delete" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Represents a get integration response.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: GetIntegrationResponse
export def "restapis-resources-methods-integration-responses get" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> record<statusCode: record, selectionPattern: record, responseParameters: record, responseTemplates: record, contentHandling: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Represents a put integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: PutIntegrationResponse
export def "restapis-resources-methods-integration-responses update-by-restapi-id-resource-id-http-method-status-code" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --selection-pattern: string # Specifies the selection pattern of a put integration response.
  --response-parameters: record # A key-value map specifying response parameters that are passed to the method response from the back end. The key is a method response header parameter name and the mapped value is an integration response header value, a static value enclosed within a pair of single quotes, or a JSON expression from the integration response body. The mapping key must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The mapped non-static value must match the pattern of integration.response.header.{name} or integration.response.body.{JSON-expression}, where name must be a valid and unique response header name and JSON-expression a valid JSON expression without the $ prefix.
  --response-templates: record # Specifies a put integration response's templates.
  --content-handling: string@content-handling-completer # Specifies how to handle response payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the response payload will be passed through from the integration response to the method response without modification.
]: any -> record<statusCode: record, selectionPattern: record, responseParameters: record, responseTemplates: record, contentHandling: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"))
  let req_body = {"selectionPattern": $selection_pattern, "responseParameters": $response_parameters, "responseTemplates": $response_templates, "contentHandling": $content_handling} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents an update integration response.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: UpdateIntegrationResponse
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-resources-methods-integration-responses update-by-restapi-id-resource-id-http-method-status-code-1" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<statusCode: record, selectionPattern: record, responseParameters: record, responseTemplates: record, contentHandling: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an existing Method resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: DeleteMethod
export def "restapis-resources-methods delete" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describe an existing Method resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: GetMethod
export def "restapis-resources-methods get" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> record<httpMethod: record, authorizationType: record, authorizerId: record, apiKeyRequired: record, requestValidatorId: record, operationName: record, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>>, authorizationScopes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a method to an existing Resource resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: PutMethod
export def "restapis-resources-methods update-by-restapi-id-resource-id-http-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  authorization_type: string # The method's authorization type. Valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, CUSTOM for using a custom authorizer, or COGNITO_USER_POOLS for using a Cognito user pool.
  --authorizer-id: string # Specifies the identifier of an Authorizer to use on this Method, if the type is CUSTOM or COGNITO_USER_POOLS. The authorizer identifier is generated by API Gateway when you created the authorizer.
  --api-key-required: oneof<nothing, bool> # Specifies whether the method required a valid ApiKey.
  --operation-name: string # A human-friendly operation identifier for the method. For example, you can assign the operationName of ListPets for the GET /pets method in the PetStore example.
  --request-parameters: record # A key-value map defining required or optional method request parameters that can be accepted by API Gateway. A key defines a method request parameter name matching the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name is a valid and unique parameter name. The value associated with the key is a Boolean flag indicating whether the parameter is required (true) or optional (false). The method request parameter names defined here are available in Integration to be mapped to integration request parameters or body-mapping templates.
  --request-models: record # Specifies the Model resources used for the request's content type. Request models are represented as a key/value map, with a content type as the key and a Model name as the value.
  --request-validator-id: string # The identifier of a RequestValidator for validating the method request.
  --authorization-scopes: list<string> # A list of authorization scopes configured on the method. The scopes are used with a COGNITO_USER_POOLS authorizer to authorize the method invocation. The authorization works by matching the method scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any method scopes matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the method scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
]: any -> record<httpMethod: record, authorizationType: record, authorizerId: record, apiKeyRequired: record, requestValidatorId: record, operationName: record, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>>, authorizationScopes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"))
  let req_body = {"authorizationType": $authorization_type, "authorizerId": $authorizer_id, "apiKeyRequired": $api_key_required, "operationName": $operation_name, "requestParameters": $request_parameters, "requestModels": $request_models, "requestValidatorId": $request_validator_id, "authorizationScopes": $authorization_scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Simulate the invocation of a Method in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: TestInvokeMethod
export def "restapis-resources-methods test-invoke" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --headers: record # A key-value map of headers to simulate an incoming invocation request.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request.
  --client-certificate-id: string # A ClientCertificate identifier to use in the test invocation. API Gateway will use the certificate when making the HTTPS request to the defined back-end endpoint.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
]: any -> record<status: record, body: record, headers: record, multiValueHeaders: record, log: record, latency: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"))
  let req_body = {"pathWithQueryString": $path_with_query_string, "body": $body, "headers": $headers, "multiValueHeaders": $multi_value_headers, "clientCertificateId": $client_certificate_id, "stageVariables": $stage_variables} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates an existing Method resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: UpdateMethod
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-resources-methods update-by-restapi-id-resource-id-http-method-1" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<httpMethod: record, authorizationType: record, authorizerId: record, apiKeyRequired: record, requestValidatorId: record, operationName: record, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: record, httpMethod: record, uri: record, connectionType: record, connectionId: record, credentials: record, requestParameters: record, requestTemplates: record, passthroughBehavior: record, contentHandling: record, timeoutInMillis: record, cacheNamespace: record, cacheKeyParameters: record, integrationResponses: record, tlsConfig: record<insecureSkipVerification: record>>, authorizationScopes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an existing MethodResponse resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: DeleteMethodResponse
export def "restapis-resources-methods-responses delete" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes a MethodResponse resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: GetMethodResponse
export def "restapis-resources-methods-responses get" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> record<statusCode: record, responseParameters: record, responseModels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a MethodResponse to an existing Method resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: PutMethodResponse
export def "restapis-resources-methods-responses update-by-restapi-id-resource-id-http-method-status-code" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --response-parameters: record # A key-value map specifying required or optional response parameters that API Gateway can send back to the caller. A key defines a method response header name and the associated value is a Boolean flag indicating whether the method response parameter is required or not. The method response header names must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The response parameter names defined here are available in the integration response to be mapped from an integration response header expressed in integration.response.header.{name}, a static value enclosed within a pair of single quotes (e.g., 'application/json'), or a JSON expression from the back-end response payload in the form of integration.response.body.{JSON-expression}, where JSON-expression is a valid JSON expression without the $ prefix.)
  --response-models: record # Specifies the Model resources used for the response's content type. Response models are represented as a key/value map, with a content type as the key and a Model name as the value.
]: any -> record<statusCode: record, responseParameters: record, responseModels: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"))
  let req_body = {"responseParameters": $response_parameters, "responseModels": $response_models} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates an existing MethodResponse resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: UpdateMethodResponse
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-resources-methods-responses update-by-restapi-id-resource-id-http-method-status-code-1" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<statusCode: record, responseParameters: record, responseModels: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a model.
#
# DELETE /restapis/{restapi_id}/models/{model_name}
# operationId: DeleteModel
export def "restapis-models delete" [
  restapi_id: string
  model_name: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes an existing model defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models/{model_name}
# operationId: GetModel
export def "restapis-models get" [
  restapi_id: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # A query parameter of a Boolean value to resolve (true) all external model references and returns a flattened model schema or not (false) The default is false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<id: record, name: record, description: record, schema: record, contentType: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"flatten": $flatten} | compact), body: null}
}

# Changes information about a model.
#
# PATCH /restapis/{restapi_id}/models/{model_name}
# operationId: UpdateModel
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-models update" [
  restapi_id: string
  model_name: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, description: record, schema: record, contentType: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a RequestValidator of a given RestApi.
#
# DELETE /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: DeleteRequestValidator
export def "restapis-requestvalidators delete-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a RequestValidator of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: GetRequestValidator
export def "restapis-requestvalidators get-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
]: nothing -> record<id: record, name: record, validateRequestBody: record, validateRequestParameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a RequestValidator of a given RestApi.
#
# PATCH /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: UpdateRequestValidator
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-requestvalidators update-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, validateRequestBody: record, validateRequestParameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Resource resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}
# operationId: DeleteResource
export def "restapis-resources delete" [
  restapi_id: string
  resource_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists information about a resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}
# operationId: GetResource
export def "restapis-resources get" [
  restapi_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: list # A query parameter to retrieve the specified resources embedded in the returned Resource representation in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<id: record, parentId: record, pathPart: record, path: record, resourceMethods: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"embed": $embed} | compact), body: null}
}

# Changes information about a Resource resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}
# operationId: UpdateResource
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-resources update" [
  restapi_id: string
  resource_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, parentId: record, pathPart: record, path: record, resourceMethods: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified API.
#
# DELETE /restapis/{restapi_id}
# operationId: DeleteRestApi
export def "restapis delete-rest" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists the RestApi resource in the collection.
#
# GET /restapis/{restapi_id}
# operationId: GetRestApi
export def "restapis get-rest" [
  restapi_id: string
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
]: nothing -> record<id: record, name: record, description: record, createdDate: record, version: record, warnings: record, binaryMediaTypes: record, minimumCompressionSize: record, apiKeySource: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, policy: record, tags: record, disableExecuteApiEndpoint: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
#
# PUT /restapis/{restapi_id}
# operationId: PutRestApi
export def "restapis update-rest-by-restapi-id" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # The mode query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API update (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # Custom header parameters as part of the request. For example, to exclude DocumentationParts from an imported API, set ignore=documentation as a parameters value, as in the AWS CLI command of aws apigateway import-rest-api --parameters ignore=documentation --body 'file:///path/to/imported-api-body.json'.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The PUT request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> record<id: record, name: record, description: record, createdDate: record, version: record, warnings: record, binaryMediaTypes: record, minimumCompressionSize: record, apiKeySource: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, policy: record, tags: record, disableExecuteApiEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}") $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"mode": $mode, "failonwarnings": $failonwarnings, "parameters": $parameters} | compact), body: $req_body}
}

# Changes information about the specified API.
#
# PATCH /restapis/{restapi_id}
# operationId: UpdateRestApi
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis update-rest-by-restapi-id-1" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, description: record, createdDate: record, version: record, warnings: record, binaryMediaTypes: record, minimumCompressionSize: record, apiKeySource: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, policy: record, tags: record, disableExecuteApiEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Stage resource.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}
# operationId: DeleteStage
export def "restapis-stages delete" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about a Stage resource.
#
# GET /restapis/{restapi_id}/stages/{stage_name}
# operationId: GetStage
export def "restapis-stages get" [
  restapi_id: string
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
]: nothing -> record<deploymentId: record, clientCertificateId: record, stageName: record, description: record, cacheClusterEnabled: record, cacheClusterSize: record, cacheClusterStatus: record, methodSettings: record, variables: record, documentationVersion: record, accessLogSettings: record<format: record, destinationArn: record>, canarySettings: record<percentTraffic: record, deploymentId: record, stageVariableOverrides: record, useStageCache: record>, tracingEnabled: record, webAclArn: record, tags: record, createdDate: record, lastUpdatedDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes information about a Stage resource.
#
# PATCH /restapis/{restapi_id}/stages/{stage_name}
# operationId: UpdateStage
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "restapis-stages update" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<deploymentId: record, clientCertificateId: record, stageName: record, description: record, cacheClusterEnabled: record, cacheClusterSize: record, cacheClusterStatus: record, methodSettings: record, variables: record, documentationVersion: record, accessLogSettings: record<format: record, destinationArn: record>, canarySettings: record<percentTraffic: record, deploymentId: record, stageVariableOverrides: record, useStageCache: record>, tracingEnabled: record, webAclArn: record, tags: record, createdDate: record, lastUpdatedDate: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a usage plan of a given plan Id.
#
# DELETE /usageplans/{usageplanId}
# operationId: DeleteUsagePlan
export def "usageplans delete-usage-plan" [
  usageplan_id: string
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
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a usage plan of a given plan identifier.
#
# GET /usageplans/{usageplanId}
# operationId: GetUsagePlan
export def "usageplans get-usage-plan" [
  usageplan_id: string
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
]: nothing -> record<id: record, name: record, description: record, apiStages: record, throttle: record<burstLimit: record, rateLimit: record>, quota: record<limit: record, offset: record, period: record>, productCode: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a usage plan of a given plan Id.
#
# PATCH /usageplans/{usageplanId}
# operationId: UpdateUsagePlan
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "usageplans update-usage-plan" [
  usageplan_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, description: record, apiStages: record, throttle: record<burstLimit: record, rateLimit: record>, quota: record<limit: record, offset: record, period: record>, productCode: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a usage plan key and remove the underlying API key from the associated usage plan.
#
# DELETE /usageplans/{usageplanId}/keys/{keyId}
# operationId: DeleteUsagePlanKey
export def "usageplans-keys delete-usage-plan" [
  usageplan_id: string
  key_id: string
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
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a usage plan key of a given key identifier.
#
# GET /usageplans/{usageplanId}/keys/{keyId}
# operationId: GetUsagePlanKey
export def "usageplans-keys get-usage-plan" [
  usageplan_id: string
  key_id: string
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
]: nothing -> record<id: record, type: record, value: record, name: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an existing VpcLink of a specified identifier.
#
# DELETE /vpclinks/{vpclink_id}
# operationId: DeleteVpcLink
export def "vpclinks delete-vpc-link" [
  vpclink_id: string
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
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a specified VPC link under the caller's account in a region.
#
# GET /vpclinks/{vpclink_id}
# operationId: GetVpcLink
export def "vpclinks get-vpc-link" [
  vpclink_id: string
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
]: nothing -> record<id: record, name: record, description: record, targetArns: record, status: record, statusMessage: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing VpcLink of a specified identifier.
#
# PATCH /vpclinks/{vpclink_id}
# operationId: UpdateVpcLink
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "vpclinks update-vpc-link" [
  vpclink_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<id: record, name: record, description: record, targetArns: record, status: record, statusMessage: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Flushes all authorizer cache entries on a stage.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/authorizers
# operationId: FlushStageAuthorizersCache
export def "restapis-stages-cache-authorizers delete-flush" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Flushes a stage's cache.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/data
# operationId: FlushStageCache
export def "restapis-stages-cache-data delete-flush" [
  restapi_id: string
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
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/cache/data"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generates a ClientCertificate resource.
#
# POST /clientcertificates
# operationId: GenerateClientCertificate
export def "clientcertificates generate-client-certificate" [
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
  --description: string # The description of the ClientCertificate.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> record<clientCertificateId: record, description: record, pemEncodedCertificate: record, createdDate: record, expirationDate: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clientcertificates")
  let req_body = {"description": $description, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a collection of ClientCertificate resources.
#
# GET /clientcertificates
# operationId: GetClientCertificates
export def "clientcertificates get-client-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clientcertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Gets information about the current Account resource.
#
# GET /account
# operationId: GetAccount
export def "account get" [
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
]: nothing -> record<cloudwatchRoleArn: record, throttleSettings: record<burstLimit: record, rateLimit: record>, features: record, apiKeyVersion: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes information about the current Account resource.
#
# PATCH /account
# operationId: UpdateAccount
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "account update" [
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<cloudwatchRoleArn: record, throttleSettings: record<burstLimit: record, rateLimit: record>, features: record, apiKeyVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Exports a deployed version of a RestApi in a specified format.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}
# operationId: GetExport
export def "restapis-stages-exports get" [
  restapi_id: string
  stage_name: string
  export_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A key-value map of query string parameters that specify properties of the export, depending on the requested exportType. For exportType oas30 and swagger, any combination of the following parameters are supported: extensions='integrations' or extensions='apigateway' will export the API with x-amazon-apigateway-integration extensions. extensions='authorizers' will export the API with x-amazon-apigateway-authorizer extensions. postman will export the API with Postman extensions, allowing for import to the Postman tool
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --hdr-accept: string # The content-type of the export, for example application/json. Currently application/json and application/yaml are supported for exportType ofoas30 and swagger. This should be specified in the Accept header for direct API requests.
]: nothing -> record<body: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  if ($export_type | is-empty) { error make --unspanned { msg: "path parameter 'export_type' must be non-empty" } }
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name), export_type: (encode-path-segment $export_type)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"parameters": $parameters} | compact), body: null}
}

# Gets the GatewayResponses collection on the given RestApi. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default GatewayResponses collection for the supported response types.
#
# GET /restapis/{restapi_id}/gatewayresponses
# operationId: GetGatewayResponses
export def "restapis-gatewayresponses get-gateway-responses" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set. The GatewayResponse collection does not support pagination and the position does not apply here.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The GatewayResponses collection does not support pagination and the limit does not apply here.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/gatewayresponses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Generates a sample mapping template that can be used to transform a payload into the structure of a model.
#
# GET /restapis/{restapi_id}/models/{model_name}/default_template
# operationId: GetModelTemplate
export def "restapis-models-default-template get" [
  restapi_id: string
  model_name: string
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
]: nothing -> record<value: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}/default_template"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists information about a collection of Resource resources.
#
# GET /restapis/{restapi_id}/resources
# operationId: GetResources
export def "restapis-resources list" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --embed: list # A query parameter used to retrieve the specified resources embedded in the returned Resources resource in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources?embed=methods.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/resources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit, "embed": $embed} | compact), body: null}
}

# Generates a client SDK for a RestApi and Stage.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}
# operationId: GetSdk
export def "restapis-stages-sdks get" [
  restapi_id: string
  stage_name: string
  sdk_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A string-to-string key-value map of query parameters sdkType-dependent properties of the SDK. For sdkType of objectivec or swift, a parameter named classPrefix is required. For sdkType of android, parameters named groupId, artifactId, artifactVersion, and invokerPackage are required. For sdkType of java, parameters named serviceName and javaPackageName are required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<body: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  if ($sdk_type | is-empty) { error make --unspanned { msg: "path parameter 'sdk_type' must be non-empty" } }
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name), sdk_type: (encode-path-segment $sdk_type)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"parameters": $parameters} | compact), body: null}
}

# Gets an SDK type.
#
# GET /sdktypes/{sdktype_id}
# operationId: GetSdkType
export def "sdktypes get-sdk-type" [
  sdktype_id: string
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
]: nothing -> record<id: record, friendlyName: record, description: record, configurationProperties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sdktype_id | is-empty) { error make --unspanned { msg: "path parameter 'sdktype_id' must be non-empty" } }
  let full_url = (build-url $base ({sdktype_id: (encode-path-segment $sdktype_id)} | format pattern "/sdktypes/{sdktype_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets SDK types
#
# GET /sdktypes
# operationId: GetSdkTypes
export def "sdktypes get-sdk-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdktypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Gets the Tags collection for a given resource.
#
# GET /tags/{resource_arn}
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
  --position: string # (Not currently supported) The current pagination position in the paged result set.
  --limit: int # (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"position": $position, "limit": $limit} | compact), body: null}
}

# Adds or updates a tag on a given resource.
#
# PUT /tags/{resource_arn}
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
  tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the usage data of a usage plan in a specified time interval.
#
# GET /usageplans/{usageplanId}/usage
# operationId: GetUsage
export def "usageplans-usage get" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-id: string # The Id of the API key associated with the resultant usage data.
  --start-date: string # The starting date (e.g., 2016-01-01) of the usage data.
  --end-date: string # The ending date (e.g., 2016-12-31) of the usage data.
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<usagePlanId: record, startDate: record, endDate: record, position: string, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let qp = [(serialize-qp "keyId" $key_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/usage") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"keyId": $key_id, "startDate": $start_date, "endDate": $end_date, "position": $position, "limit": $limit} | compact), body: null}
}

# Import API keys from an external source, such as a CSV-formatted file.
#
# POST /apikeys
# operationId: ImportApiKeys
export def "apikeys import-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # A query parameter to specify the input format to imported API keys. Currently, only the csv format is supported.
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback ApiKey importation (true) or not (false) when error is encountered.
  --mode: string@mode-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The payload of the POST request to import API keys. For the payload format, see API Key File Format.
]: any -> record<ids: record, warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys" $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"format": $format, "failonwarnings": $failonwarnings, "mode": $mode} | compact), body: $req_body}
}

# A feature of the API Gateway control service for creating a new API from an external API definition file.
#
# POST /restapis
# operationId: ImportRestApi
export def "restapis import-rest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # A key-value map of context-specific query string parameters specifying the behavior of different API importing operations. The following shows operation-specific parameters and their supported values. To exclude DocumentationParts from the import, set parameters as ignore=documentation. To configure the endpoint type, set parameters as endpointConfigurationTypes=EDGE, endpointConfigurationTypes=REGIONAL, or endpointConfigurationTypes=PRIVATE. The default endpoint type is EDGE. To handle imported basepath, set parameters as basepath=ignore, basepath=prepend or basepath=split. For example, the AWS CLI command to exclude documentation from the imported API is: The AWS CLI command to set the regional endpoint on the imported API is:
  --mode: string@mode-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The POST request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> record<id: record, name: record, description: record, createdDate: record, version: record, warnings: record, binaryMediaTypes: record, minimumCompressionSize: record, apiKeySource: record, endpointConfiguration: record<types: record, vpcEndpointIds: record>, policy: record, tags: record, disableExecuteApiEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "parameters" $parameters "multi") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapis" $qp)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"failonwarnings": $failonwarnings, "parameters": $parameters, "mode": $mode} | compact), body: $req_body}
}

# Removes a tag from a given resource.
#
# DELETE /tags/{resource_arn}
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
  --tag-keys: list # The Tag keys to delete.
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
#
# PATCH /usageplans/{usageplanId}/keys/{keyId}/usage
# operationId: UpdateUsage
# --patchOperations item shape: {op?: any, path?: any, value?: any, from?: any}
export def "usageplans-keys-usage update" [
  usageplan_id: string
  key_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: any, path?: any, value?: any, from?: any}
]: any -> record<usagePlanId: record, startDate: record, endDate: record, position: string, items: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}/usage"))
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
