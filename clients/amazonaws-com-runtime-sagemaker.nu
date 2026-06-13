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

def base-url-completer [] { ["http://runtime.sagemaker.us-east-1.amazonaws.com" "http://runtime.sagemaker.us-east-2.amazonaws.com" "http://runtime.sagemaker.us-west-1.amazonaws.com" "http://runtime.sagemaker.us-west-2.amazonaws.com" "http://runtime.sagemaker.us-gov-west-1.amazonaws.com" "http://runtime.sagemaker.us-gov-east-1.amazonaws.com" "http://runtime.sagemaker.ca-central-1.amazonaws.com" "http://runtime.sagemaker.eu-north-1.amazonaws.com" "http://runtime.sagemaker.eu-west-1.amazonaws.com" "http://runtime.sagemaker.eu-west-2.amazonaws.com" "http://runtime.sagemaker.eu-west-3.amazonaws.com" "http://runtime.sagemaker.eu-central-1.amazonaws.com" "http://runtime.sagemaker.eu-south-1.amazonaws.com" "http://runtime.sagemaker.af-south-1.amazonaws.com" "http://runtime.sagemaker.ap-northeast-1.amazonaws.com" "http://runtime.sagemaker.ap-northeast-2.amazonaws.com" "http://runtime.sagemaker.ap-northeast-3.amazonaws.com" "http://runtime.sagemaker.ap-southeast-1.amazonaws.com" "http://runtime.sagemaker.ap-southeast-2.amazonaws.com" "http://runtime.sagemaker.ap-east-1.amazonaws.com" "http://runtime.sagemaker.ap-south-1.amazonaws.com" "http://runtime.sagemaker.sa-east-1.amazonaws.com" "http://runtime.sagemaker.me-south-1.amazonaws.com" "https://runtime.sagemaker.us-east-1.amazonaws.com" "https://runtime.sagemaker.us-east-2.amazonaws.com" "https://runtime.sagemaker.us-west-1.amazonaws.com" "https://runtime.sagemaker.us-west-2.amazonaws.com" "https://runtime.sagemaker.us-gov-west-1.amazonaws.com" "https://runtime.sagemaker.us-gov-east-1.amazonaws.com" "https://runtime.sagemaker.ca-central-1.amazonaws.com" "https://runtime.sagemaker.eu-north-1.amazonaws.com" "https://runtime.sagemaker.eu-west-1.amazonaws.com" "https://runtime.sagemaker.eu-west-2.amazonaws.com" "https://runtime.sagemaker.eu-west-3.amazonaws.com" "https://runtime.sagemaker.eu-central-1.amazonaws.com" "https://runtime.sagemaker.eu-south-1.amazonaws.com" "https://runtime.sagemaker.af-south-1.amazonaws.com" "https://runtime.sagemaker.ap-northeast-1.amazonaws.com" "https://runtime.sagemaker.ap-northeast-2.amazonaws.com" "https://runtime.sagemaker.ap-northeast-3.amazonaws.com" "https://runtime.sagemaker.ap-southeast-1.amazonaws.com" "https://runtime.sagemaker.ap-southeast-2.amazonaws.com" "https://runtime.sagemaker.ap-east-1.amazonaws.com" "https://runtime.sagemaker.ap-south-1.amazonaws.com" "https://runtime.sagemaker.sa-east-1.amazonaws.com" "https://runtime.sagemaker.me-south-1.amazonaws.com" "http://runtime.sagemaker.cn-north-1.amazonaws.com.cn" "http://runtime.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://runtime.sagemaker.cn-north-1.amazonaws.com.cn" "https://runtime.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "endpoints-invocations InvokeEndpoint" } } | get name | first)
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

# <p>After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint. </p> <p>For an overview of Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p> <p>Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. </p> <p>Calls to <code>InvokeEndpoint</code> are authenticated by using Amazon Web Services Signature Version 4. For information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (Amazon Web Services Signature Version 4)</a> in the <i>Amazon S3 API Reference</i>.</p> <p>A customer's model containers must respond to requests within 60 seconds. The model itself can have a maximum processing time of 60 seconds before responding to invocations. If your model is going to take 50-60 seconds of processing time, the SDK socket timeout should be set to be 70 seconds.</p> <note> <p>Endpoints are scoped to an individual account, and are not public. The URL does not contain the account ID, but Amazon SageMaker determines the account ID from the authentication token that is supplied by the caller.</p> </note>
#
# POST /endpoints/{EndpointName}/invocations
# operationId: InvokeEndpoint
export def "endpoints-invocations InvokeEndpoint" [
  EndpointName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Content-Type: string # The MIME type of the input data in the request body.
  --Accept: string # The desired MIME type of the inference in the response.
  --X-Amzn-SageMaker-Custom-Attributes: string # <p>Provides additional information about a request for an inference submitted to a model hosted at an Amazon SageMaker endpoint. The information is an opaque value that is forwarded verbatim. You could use this value, for example, to provide an ID that you can use to track a request or to provide other metadata that a service endpoint was programmed to process. The value must consist of no more than 1024 visible US-ASCII characters as specified in <a href="https://tools.ietf.org/html/rfc7230#section-3.2.6">Section 3.3.6. Field Value Components</a> of the Hypertext Transfer Protocol (HTTP/1.1). </p> <p>The code in your model is responsible for setting or updating any custom attributes in the response. If your code does not set this value in the response, an empty value is returned. For example, if a custom attribute represents the trace ID, your model can prepend the custom attribute with <code>Trace ID:</code> in your post-processing function.</p> <p>This feature is currently supported in the Amazon Web Services SDKs but not in the Amazon SageMaker Python SDK.</p>
  --X-Amzn-SageMaker-Target-Model: string # The model to request for inference when invoking a multi-model endpoint.
  --X-Amzn-SageMaker-Target-Variant: string # <p>Specify the production variant to send the inference request to when invoking an endpoint that is running two or more variants. Note that this parameter overrides the default behavior for the endpoint, which is to distribute the invocation traffic based on the variant weights.</p> <p>For information about how to use variant targeting to perform a/b testing, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-ab-testing.html">Test models in production</a> </p>
  --X-Amzn-SageMaker-Target-Container-Hostname: string # If the endpoint hosts multiple containers and is configured to use direct invocation, this parameter specifies the host name of the container to invoke.
  --X-Amzn-SageMaker-Inference-Id: string # If you provide a value, it is added to the captured data when you enable data capture on the endpoint. For information about data capture, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor-data-capture.html">Capture Data</a>.
  --X-Amzn-SageMaker-Enable-Explanations: string # An optional JMESPath expression used to override the <code>EnableExplanations</code> parameter of the <code>ClarifyExplainerConfig</code> API. See the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/clarify-online-explainability-create-endpoint.html#clarify-online-explainability-create-endpoint-enable">EnableExplanations</a> section in the developer guide for more information. 
  Body: string # <p>Provides input data, in the format specified in the <code>ContentType</code> request header. Amazon SageMaker passes all of the data in the body to the model. </p> <p>For information about the format of the request body, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/cdf-inference.html">Common Data Formats-Inference</a>.</p> (format: password)
]: any -> record<Body: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($EndpointName)/invocations")
  let body = {Body: $Body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "Content-Type": $Content_Type, "Accept": $Accept, "X-Amzn-SageMaker-Custom-Attributes": $X_Amzn_SageMaker_Custom_Attributes, "X-Amzn-SageMaker-Target-Model": $X_Amzn_SageMaker_Target_Model, "X-Amzn-SageMaker-Target-Variant": $X_Amzn_SageMaker_Target_Variant, "X-Amzn-SageMaker-Target-Container-Hostname": $X_Amzn_SageMaker_Target_Container_Hostname, "X-Amzn-SageMaker-Inference-Id": $X_Amzn_SageMaker_Inference_Id, "X-Amzn-SageMaker-Enable-Explanations": $X_Amzn_SageMaker_Enable_Explanations} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint in an asynchronous manner.</p> <p>Inference requests sent to this API are enqueued for asynchronous processing. The processing of the inference request may or may not complete before you receive a response from this API. The response from this API will not contain the result of the inference request but contain information about where you can locate it.</p> <p>Amazon SageMaker strips all <code>POST</code> headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax.</p> <p>Calls to <code>InvokeEndpointAsync</code> are authenticated by using Amazon Web Services Signature Version 4. For information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (Amazon Web Services Signature Version 4)</a> in the <i>Amazon S3 API Reference</i>.</p>
#
# POST /endpoints/{EndpointName}/async-invocations#X-Amzn-SageMaker-InputLocation
# operationId: InvokeEndpointAsync
export def "endpoints-async-invocations-x-amzn-sage-maker-input-location InvokeEndpointAsync" [
  EndpointName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amzn-SageMaker-Content-Type: string # The MIME type of the input data in the request body.
  --X-Amzn-SageMaker-Accept: string # The desired MIME type of the inference in the response.
  --X-Amzn-SageMaker-Custom-Attributes: string # <p>Provides additional information about a request for an inference submitted to a model hosted at an Amazon SageMaker endpoint. The information is an opaque value that is forwarded verbatim. You could use this value, for example, to provide an ID that you can use to track a request or to provide other metadata that a service endpoint was programmed to process. The value must consist of no more than 1024 visible US-ASCII characters as specified in <a href="https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6">Section 3.3.6. Field Value Components</a> of the Hypertext Transfer Protocol (HTTP/1.1). </p> <p>The code in your model is responsible for setting or updating any custom attributes in the response. If your code does not set this value in the response, an empty value is returned. For example, if a custom attribute represents the trace ID, your model can prepend the custom attribute with <code>Trace ID</code>: in your post-processing function. </p> <p>This feature is currently supported in the Amazon Web Services SDKs but not in the Amazon SageMaker Python SDK. </p>
  --X-Amzn-SageMaker-Inference-Id: string # The identifier for the inference request. Amazon SageMaker will generate an identifier for you if none is specified. 
  --X-Amzn-SageMaker-InputLocation: string # The Amazon S3 URI where the inference request payload is stored.
  --X-Amzn-SageMaker-RequestTTLSeconds: int # Maximum age in seconds a request can be in the queue before it is marked as expired. The default is 6 hours, or 21,600 seconds.
  --X-Amzn-SageMaker-InvocationTimeoutSeconds: int # Maximum amount of time in seconds a request can be processed before it is marked as expired. The default is 15 minutes, or 900 seconds.
]: nothing -> record<InferenceId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($EndpointName)/async-invocations#X-Amzn-SageMaker-InputLocation")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amzn-SageMaker-Content-Type": $X_Amzn_SageMaker_Content_Type, "X-Amzn-SageMaker-Accept": $X_Amzn_SageMaker_Accept, "X-Amzn-SageMaker-Custom-Attributes": $X_Amzn_SageMaker_Custom_Attributes, "X-Amzn-SageMaker-Inference-Id": $X_Amzn_SageMaker_Inference_Id, "X-Amzn-SageMaker-InputLocation": $X_Amzn_SageMaker_InputLocation, "X-Amzn-SageMaker-RequestTTLSeconds": $X_Amzn_SageMaker_RequestTTLSeconds, "X-Amzn-SageMaker-InvocationTimeoutSeconds": $X_Amzn_SageMaker_InvocationTimeoutSeconds} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
