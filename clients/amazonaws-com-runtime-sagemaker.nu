# Auto-generated client for Amazon SageMaker Runtime v2017-05-13
# Source: https://api.apis.guru/v2/specs/amazonaws.com/runtime.sagemaker/2017-05-13/openapi.json
# Auth: --token flag or $env.AMAZON_SAGEMAKER_RUNTIME_TOKEN

const BASE_URL = "http://runtime.sagemaker.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SAGEMAKER_RUNTIME_TOKEN | default "" }
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

def base-url-completer [] { ["http://runtime.sagemaker.us-east-1.amazonaws.com" "http://runtime.sagemaker.us-east-2.amazonaws.com" "http://runtime.sagemaker.us-west-1.amazonaws.com" "http://runtime.sagemaker.us-west-2.amazonaws.com" "http://runtime.sagemaker.us-gov-west-1.amazonaws.com" "http://runtime.sagemaker.us-gov-east-1.amazonaws.com" "http://runtime.sagemaker.ca-central-1.amazonaws.com" "http://runtime.sagemaker.eu-north-1.amazonaws.com" "http://runtime.sagemaker.eu-west-1.amazonaws.com" "http://runtime.sagemaker.eu-west-2.amazonaws.com" "http://runtime.sagemaker.eu-west-3.amazonaws.com" "http://runtime.sagemaker.eu-central-1.amazonaws.com" "http://runtime.sagemaker.eu-south-1.amazonaws.com" "http://runtime.sagemaker.af-south-1.amazonaws.com" "http://runtime.sagemaker.ap-northeast-1.amazonaws.com" "http://runtime.sagemaker.ap-northeast-2.amazonaws.com" "http://runtime.sagemaker.ap-northeast-3.amazonaws.com" "http://runtime.sagemaker.ap-southeast-1.amazonaws.com" "http://runtime.sagemaker.ap-southeast-2.amazonaws.com" "http://runtime.sagemaker.ap-east-1.amazonaws.com" "http://runtime.sagemaker.ap-south-1.amazonaws.com" "http://runtime.sagemaker.sa-east-1.amazonaws.com" "http://runtime.sagemaker.me-south-1.amazonaws.com" "https://runtime.sagemaker.us-east-1.amazonaws.com" "https://runtime.sagemaker.us-east-2.amazonaws.com" "https://runtime.sagemaker.us-west-1.amazonaws.com" "https://runtime.sagemaker.us-west-2.amazonaws.com" "https://runtime.sagemaker.us-gov-west-1.amazonaws.com" "https://runtime.sagemaker.us-gov-east-1.amazonaws.com" "https://runtime.sagemaker.ca-central-1.amazonaws.com" "https://runtime.sagemaker.eu-north-1.amazonaws.com" "https://runtime.sagemaker.eu-west-1.amazonaws.com" "https://runtime.sagemaker.eu-west-2.amazonaws.com" "https://runtime.sagemaker.eu-west-3.amazonaws.com" "https://runtime.sagemaker.eu-central-1.amazonaws.com" "https://runtime.sagemaker.eu-south-1.amazonaws.com" "https://runtime.sagemaker.af-south-1.amazonaws.com" "https://runtime.sagemaker.ap-northeast-1.amazonaws.com" "https://runtime.sagemaker.ap-northeast-2.amazonaws.com" "https://runtime.sagemaker.ap-northeast-3.amazonaws.com" "https://runtime.sagemaker.ap-southeast-1.amazonaws.com" "https://runtime.sagemaker.ap-southeast-2.amazonaws.com" "https://runtime.sagemaker.ap-east-1.amazonaws.com" "https://runtime.sagemaker.ap-south-1.amazonaws.com" "https://runtime.sagemaker.sa-east-1.amazonaws.com" "https://runtime.sagemaker.me-south-1.amazonaws.com" "http://runtime.sagemaker.cn-north-1.amazonaws.com.cn" "http://runtime.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://runtime.sagemaker.cn-north-1.amazonaws.com.cn" "https://runtime.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "endpoints-invocations create-invoke" } } | get name | first)
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

# After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint. For an overview of Amazon SageMaker, see How It Works (https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html). Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. Calls to InvokeEndpoint are authenticated by using Amazon Web Services Signature Version 4. For information, see Authenticating Requests (Amazon Web Services Signature Version 4) (https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html) in the Amazon S3 API Reference. A customer's model containers must respond to requests within 60 seconds. The model itself can have a maximum processing time of 60 seconds before responding to invocations. If your model is going to take 50-60 seconds of processing time, the SDK socket timeout should be set to be 70 seconds. Endpoints are scoped to an individual account, and are not public. The URL does not contain the account ID, but Amazon SageMaker determines the account ID from the authentication token that is supplied by the caller.
#
# POST /endpoints/{EndpointName}/invocations
# operationId: InvokeEndpoint
export def "endpoints-invocations create-invoke" [
  endpoint_name: string
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
  --content-type: string # The MIME type of the input data in the request body.
  --hdr-accept: string # The desired MIME type of the inference in the response.
  --x-amzn-sage-maker-custom-attributes: string # Provides additional information about a request for an inference submitted to a model hosted at an Amazon SageMaker endpoint. The information is an opaque value that is forwarded verbatim. You could use this value, for example, to provide an ID that you can use to track a request or to provide other metadata that a service endpoint was programmed to process. The value must consist of no more than 1024 visible US-ASCII characters as specified in Section 3.3.6. Field Value Components (https://tools.ietf.org/html/rfc7230#section-3.2.6) of the Hypertext Transfer Protocol (HTTP/1.1). The code in your model is responsible for setting or updating any custom attributes in the response. If your code does not set this value in the response, an empty value is returned. For example, if a custom attribute represents the trace ID, your model can prepend the custom attribute with Trace ID: in your post-processing function. This feature is currently supported in the Amazon Web Services SDKs but not in the Amazon SageMaker Python SDK.
  --x-amzn-sage-maker-target-model: string # The model to request for inference when invoking a multi-model endpoint.
  --x-amzn-sage-maker-target-variant: string # Specify the production variant to send the inference request to when invoking an endpoint that is running two or more variants. Note that this parameter overrides the default behavior for the endpoint, which is to distribute the invocation traffic based on the variant weights. For information about how to use variant targeting to perform a/b testing, see Test models in production (https://docs.aws.amazon.com/sagemaker/latest/dg/model-ab-testing.html)
  --x-amzn-sage-maker-target-container-hostname: string # If the endpoint hosts multiple containers and is configured to use direct invocation, this parameter specifies the host name of the container to invoke.
  --x-amzn-sage-maker-inference-id: string # If you provide a value, it is added to the captured data when you enable data capture on the endpoint. For information about data capture, see Capture Data (https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor-data-capture.html).
  --x-amzn-sage-maker-enable-explanations: string # An optional JMESPath expression used to override the EnableExplanations parameter of the ClarifyExplainerConfig API. See the EnableExplanations (https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-online-explainability-create-endpoint.html#clarify-online-explainability-create-endpoint-enable) section in the developer guide for more information.
  body: string # Provides input data, in the format specified in the ContentType request header. Amazon SageMaker passes all of the data in the body to the model. For information about the format of the request body, see Common Data Formats-Inference (https://docs.aws.amazon.com/sagemaker/latest/dg/cdf-inference.html). (format: password)
]: any -> record<Body: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_name: (encode-path-segment $endpoint_name)} | format pattern "/endpoints/{endpoint_name}/invocations"))
  let req_body = {"Body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Content-Type": $content_type, "Accept": $hdr_accept, "X-Amzn-SageMaker-Custom-Attributes": $x_amzn_sage_maker_custom_attributes, "X-Amzn-SageMaker-Target-Model": $x_amzn_sage_maker_target_model, "X-Amzn-SageMaker-Target-Variant": $x_amzn_sage_maker_target_variant, "X-Amzn-SageMaker-Target-Container-Hostname": $x_amzn_sage_maker_target_container_hostname, "X-Amzn-SageMaker-Inference-Id": $x_amzn_sage_maker_inference_id, "X-Amzn-SageMaker-Enable-Explanations": $x_amzn_sage_maker_enable_explanations} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint in an asynchronous manner. Inference requests sent to this API are enqueued for asynchronous processing. The processing of the inference request may or may not complete before you receive a response from this API. The response from this API will not contain the result of the inference request but contain information about where you can locate it. Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. Calls to InvokeEndpointAsync are authenticated by using Amazon Web Services Signature Version 4. For information, see Authenticating Requests (Amazon Web Services Signature Version 4) (https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html) in the Amazon S3 API Reference.
#
# POST /endpoints/{EndpointName}/async-invocations#X-Amzn-SageMaker-InputLocation
# operationId: InvokeEndpointAsync
export def "endpoints-async-invocations-x-amzn-sage-maker-input-location create-invoke" [
  endpoint_name: string
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
  --x-amzn-sage-maker-content-type: string # The MIME type of the input data in the request body.
  --x-amzn-sage-maker-accept: string # The desired MIME type of the inference in the response.
  --x-amzn-sage-maker-custom-attributes: string # Provides additional information about a request for an inference submitted to a model hosted at an Amazon SageMaker endpoint. The information is an opaque value that is forwarded verbatim. You could use this value, for example, to provide an ID that you can use to track a request or to provide other metadata that a service endpoint was programmed to process. The value must consist of no more than 1024 visible US-ASCII characters as specified in Section 3.3.6. Field Value Components (https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6) of the Hypertext Transfer Protocol (HTTP/1.1). The code in your model is responsible for setting or updating any custom attributes in the response. If your code does not set this value in the response, an empty value is returned. For example, if a custom attribute represents the trace ID, your model can prepend the custom attribute with Trace ID: in your post-processing function. This feature is currently supported in the Amazon Web Services SDKs but not in the Amazon SageMaker Python SDK.
  --x-amzn-sage-maker-inference-id: string # The identifier for the inference request. Amazon SageMaker will generate an identifier for you if none is specified.
  --x-amzn-sage-maker-input-location: string # The Amazon S3 URI where the inference request payload is stored.
  --x-amzn-sage-maker-request-ttl-seconds: int # Maximum age in seconds a request can be in the queue before it is marked as expired. The default is 6 hours, or 21,600 seconds.
  --x-amzn-sage-maker-invocation-timeout-seconds: int # Maximum amount of time in seconds a request can be processed before it is marked as expired. The default is 15 minutes, or 900 seconds.
]: nothing -> record<InferenceId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_name: (encode-path-segment $endpoint_name)} | format pattern "/endpoints/{endpoint_name}/async-invocations#X-Amzn-SageMaker-InputLocation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-SageMaker-Content-Type": $x_amzn_sage_maker_content_type, "X-Amzn-SageMaker-Accept": $x_amzn_sage_maker_accept, "X-Amzn-SageMaker-Custom-Attributes": $x_amzn_sage_maker_custom_attributes, "X-Amzn-SageMaker-Inference-Id": $x_amzn_sage_maker_inference_id, "X-Amzn-SageMaker-InputLocation": $x_amzn_sage_maker_input_location, "X-Amzn-SageMaker-RequestTTLSeconds": $x_amzn_sage_maker_request_ttl_seconds, "X-Amzn-SageMaker-InvocationTimeoutSeconds": $x_amzn_sage_maker_invocation_timeout_seconds} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
