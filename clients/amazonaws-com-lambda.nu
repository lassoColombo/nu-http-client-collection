# Auto-generated client for AWS Lambda v2015-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lambda/2015-03-31/openapi.json
# Auth: --token flag or $env.AWS_LAMBDA_TOKEN

const BASE_URL = "http://lambda.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_LAMBDA_TOKEN | default "" }
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

def base-url-completer [] { ["http://lambda.us-east-1.amazonaws.com" "http://lambda.us-east-2.amazonaws.com" "http://lambda.us-west-1.amazonaws.com" "http://lambda.us-west-2.amazonaws.com" "http://lambda.us-gov-west-1.amazonaws.com" "http://lambda.us-gov-east-1.amazonaws.com" "http://lambda.ca-central-1.amazonaws.com" "http://lambda.eu-north-1.amazonaws.com" "http://lambda.eu-west-1.amazonaws.com" "http://lambda.eu-west-2.amazonaws.com" "http://lambda.eu-west-3.amazonaws.com" "http://lambda.eu-central-1.amazonaws.com" "http://lambda.eu-south-1.amazonaws.com" "http://lambda.af-south-1.amazonaws.com" "http://lambda.ap-northeast-1.amazonaws.com" "http://lambda.ap-northeast-2.amazonaws.com" "http://lambda.ap-northeast-3.amazonaws.com" "http://lambda.ap-southeast-1.amazonaws.com" "http://lambda.ap-southeast-2.amazonaws.com" "http://lambda.ap-east-1.amazonaws.com" "http://lambda.ap-south-1.amazonaws.com" "http://lambda.sa-east-1.amazonaws.com" "http://lambda.me-south-1.amazonaws.com" "https://lambda.us-east-1.amazonaws.com" "https://lambda.us-east-2.amazonaws.com" "https://lambda.us-west-1.amazonaws.com" "https://lambda.us-west-2.amazonaws.com" "https://lambda.us-gov-west-1.amazonaws.com" "https://lambda.us-gov-east-1.amazonaws.com" "https://lambda.ca-central-1.amazonaws.com" "https://lambda.eu-north-1.amazonaws.com" "https://lambda.eu-west-1.amazonaws.com" "https://lambda.eu-west-2.amazonaws.com" "https://lambda.eu-west-3.amazonaws.com" "https://lambda.eu-central-1.amazonaws.com" "https://lambda.eu-south-1.amazonaws.com" "https://lambda.af-south-1.amazonaws.com" "https://lambda.ap-northeast-1.amazonaws.com" "https://lambda.ap-northeast-2.amazonaws.com" "https://lambda.ap-northeast-3.amazonaws.com" "https://lambda.ap-southeast-1.amazonaws.com" "https://lambda.ap-southeast-2.amazonaws.com" "https://lambda.ap-east-1.amazonaws.com" "https://lambda.ap-south-1.amazonaws.com" "https://lambda.sa-east-1.amazonaws.com" "https://lambda.me-south-1.amazonaws.com" "http://lambda.cn-north-1.amazonaws.com.cn" "http://lambda.cn-northwest-1.amazonaws.com.cn" "https://lambda.cn-north-1.amazonaws.com.cn" "https://lambda.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def function-url-auth-type-completer [] { ["AWS_IAM" "NONE"] }
def starting-position-completer [] { ["AT_TIMESTAMP" "LATEST" "TRIM_HORIZON"] }
def runtime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def package-type-completer [] { ["Image" "Zip"] }
def auth-type-completer [] { ["AWS_IAM" "NONE"] }
def invoke-mode-completer [] { ["BUFFERED" "RESPONSE_STREAM"] }
def find-completer [] { ["LayerVersion"] }
def update-runtime-on-completer [] { ["Auto" "FunctionUpdate" "Manual"] }
def x-amz-invocation-type-completer [] { ["DryRun" "Event" "RequestResponse"] }
def x-amz-log-type-completer [] { ["None" "Tail"] }
def x-amz-invocation-type-completer-1 [] { ["DryRun" "RequestResponse"] }
def function-version-completer [] { ["ALL"] }
def compatible-runtime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def compatible-architecture-completer [] { ["arm64" "x86_64"] }
def list-completer [] { ["ALL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2018-10-31-layers-versions-policy create-permission" } } | get name | first)
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

# Adds permissions to the resource-based policy of a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all accounts in an organization, or all Amazon Web Services accounts. To revoke permission, call RemoveLayerVersionPermission with the statement ID that you specified when you added it.
#
# POST /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# operationId: AddLayerVersionPermission
export def "2018-10-31-layers-versions-policy create-permission" [
  layer_name: string
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision-id: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # An identifier that distinguishes the policy from others on the same layer version.
  action: string # The API action that grants access to the layer. For example, lambda:GetLayerVersion.
  principal: string # An account ID, or * to grant layer usage permission to all accounts in an organization, or all Amazon Web Services accounts (if organizationId is not specified). For the last case, make sure that you really do want all Amazon Web Services accounts to have usage permission to this layer.
  --organization-id: string # With the principal set to *, grant permission to all accounts in the specified organization.
]: any -> record<Statement: record, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'VersionNumber' must be non-empty" } }
  let qp = [(serialize-qp "RevisionId" $revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name), version_number: (encode-path-segment $version_number)} | format pattern "/2018-10-31/layers/{layer_name}/versions/{version_number}/policy") $qp)
  let req_body = {"StatementId": $statement_id, "Action": $action, "Principal": $principal, "OrganizationId": $organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"RevisionId": $revision_id} | compact), body: $req_body}
}

# Returns the permission policy for a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). For more information, see AddLayerVersionPermission.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# operationId: GetLayerVersionPolicy
export def "2018-10-31-layers-versions-policy get" [
  layer_name: string
  version_number: int
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
]: nothing -> record<Policy: record, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'VersionNumber' must be non-empty" } }
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name), version_number: (encode-path-segment $version_number)} | format pattern "/2018-10-31/layers/{layer_name}/versions/{version_number}/policy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Grants an Amazon Web Service, Amazon Web Services account, or Amazon Web Services organization permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function. Note: Lambda does not support adding policies to version $LATEST. To grant permission to another account, specify the account ID as the Principal. To grant permission to an organization defined in Organizations, specify the organization ID as the PrincipalOrgID. For Amazon Web Services, the principal is a domain-style identifier that the service defines, such as s3.amazonaws.com or sns.amazonaws.com. For Amazon Web Services, you can also specify the ARN of the associated resource as the SourceArn. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function. This operation adds a statement to a resource-based permissions policy for the function. For more information about function policies, see Using resource-based policies for Lambda (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html).
#
# POST /2015-03-31/functions/{FunctionName}/policy
# operationId: AddPermission
export def "2015-03-31-functions-policy create-permission" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to add permissions to a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # A statement identifier that differentiates the statement from others in the same policy.
  action: string # The action that the principal can use on the function. For example, lambda:InvokeFunction or lambda:GetFunction.
  principal: string # The Amazon Web Service or Amazon Web Services account that invokes the function. If you specify a service, use SourceArn or SourceAccount to limit who can invoke the function through that service.
  --source-arn: string # For Amazon Web Services, the ARN of the Amazon Web Services resource that invokes the function. For example, an Amazon S3 bucket or Amazon SNS topic. Note that Lambda configures the comparison using the StringLike operator.
  --source-account: string # For Amazon Web Service, the ID of the Amazon Web Services account that owns the resource. Use this together with SourceArn to ensure that the specified account owns the resource. It is possible for an Amazon S3 bucket to be deleted by its owner and recreated by another account.
  --event-source-token: string # For Alexa Smart Home functions, a token that the invoker must supply.
  --revision-id: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --principal-org-id: string # The identifier for your organization in Organizations. Use this to grant permissions to all the Amazon Web Services accounts under this organization.
  --function-url-auth-type: string@function-url-auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
]: any -> record<Statement: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/policy") $qp)
  let req_body = {"StatementId": $statement_id, "Action": $action, "Principal": $principal, "SourceArn": $source_arn, "SourceAccount": $source_account, "EventSourceToken": $event_source_token, "RevisionId": $revision_id, "PrincipalOrgID": $principal_org_id, "FunctionUrlAuthType": $function_url_auth_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Returns the resource-based IAM policy (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html) for a function, version, or alias.
#
# GET /2015-03-31/functions/{FunctionName}/policy
# operationId: GetPolicy
export def "2015-03-31-functions-policy get" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get the policy for that resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Policy: record, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/policy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Creates an alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version. You can also map an alias to split invocation requests between two versions. Use the RoutingConfig parameter to specify a second version and the percentage of invocation requests that it receives.
#
# POST /2015-03-31/functions/{FunctionName}/aliases
# operationId: CreateAlias
# --RoutingConfig shape: {AdditionalVersionWeights?: any}
export def "2015-03-31-functions-aliases create-alias" [
  function_name: string
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
  name: string # The name of the alias.
  function_version: string # The function version that the alias invokes.
  --description: string # A description of the alias.
  --routing-config: record # The traffic-shifting (https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html) configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: any}
]: any -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/aliases"))
  let req_body = {"Name": $name, "FunctionVersion": $function_version, "Description": $description, "RoutingConfig": $routing_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of aliases (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) for a Lambda function.
#
# GET /2015-03-31/functions/{FunctionName}/aliases
# operationId: ListAliases
export def "2015-03-31-functions-aliases list" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --function-version: string # Specify a function version to only list aliases that invoke that version.
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Limit the number of aliases returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, Aliases: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "FunctionVersion" $function_version "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FunctionVersion": $function_version, "Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Creates a code signing configuration. A code signing configuration (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html) defines a list of allowed signing profiles and defines the code-signing validation policy (action to be taken if deployment validation checks fail).
#
# POST /2020-04-22/code-signing-configs/
# operationId: CreateCodeSigningConfig
# --AllowedPublishers shape: {SigningProfileVersionArns?: any}
# --CodeSigningPolicies shape: {UntrustedArtifactOnDeployment?: any}
export def "2020-04-22-code-signing-configs create" [
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
  --description: string # Descriptive name for this code signing configuration.
  allowed_publishers: record # List of signing profiles that can sign a code package. — shape: {SigningProfileVersionArns?: any}
  --code-signing-policies: record # Code signing configuration policies (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies) specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: any}
]: any -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2020-04-22/code-signing-configs/")
  let req_body = {"Description": $description, "AllowedPublishers": $allowed_publishers, "CodeSigningPolicies": $code_signing_policies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of code signing configurations (https://docs.aws.amazon.com/lambda/latest/dg/configuring-codesigning.html). A request returns up to 10,000 configurations per call. You can use the MaxItems parameter to return fewer configurations per call.
#
# GET /2020-04-22/code-signing-configs/
# operationId: ListCodeSigningConfigs
export def "2020-04-22-code-signing-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Maximum number of items to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, CodeSigningConfigs: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-04-22/code-signing-configs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Creates a mapping between an event source and an Lambda function. Lambda reads items from the event source and invokes the function. For details about how to configure different event sources, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html) The following error handling options are available only for stream sources (DynamoDB and Kinesis): BisectBatchOnFunctionError – If the function returns an error, split the batch in two and retry. DestinationConfig – Send discarded records to an Amazon SQS queue or Amazon SNS topic. MaximumRecordAgeInSeconds – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires MaximumRetryAttempts – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires. ParallelizationFactor – Process multiple batches from each shard concurrently. For information about which configuration parameters apply to each event source, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration)
#
# POST /2015-03-31/event-source-mappings/
# operationId: CreateEventSourceMapping
# --FilterCriteria shape: {Filters?: any}
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
# --SourceAccessConfigurations item shape: {Type?: any, URI?: any}
# --SelfManagedEventSource shape: {Endpoints?: any}
# --AmazonManagedKafkaEventSourceConfig shape: {ConsumerGroupId?: any}
# --SelfManagedKafkaEventSourceConfig shape: {ConsumerGroupId?: any}
# --ScalingConfig shape: {MaximumConcurrency?: any}
# --DocumentDBEventSourceConfig shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
export def "2015-03-31-event-source-mappings create" [
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
  --event-source-arn: string # The Amazon Resource Name (ARN) of the event source. Amazon Kinesis – The ARN of the data stream or a stream consumer. Amazon DynamoDB Streams – The ARN of the stream. Amazon Simple Queue Service – The ARN of the queue. Amazon Managed Streaming for Apache Kafka – The ARN of the cluster. Amazon MQ – The ARN of the broker. Amazon DocumentDB – The ARN of the DocumentDB change stream.
  function_name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --enabled: oneof<nothing, bool> # When true, the event source mapping is active. When false, Lambda pauses polling and invocation. Default: True
  --batch-size: int # The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB). Amazon Kinesis – Default 100. Max 10,000. Amazon DynamoDB Streams – Default 100. Max 10,000. Amazon Simple Queue Service – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10. Amazon Managed Streaming for Apache Kafka – Default 100. Max 10,000. Self-managed Apache Kafka – Default 100. Max 10,000. Amazon MQ (ActiveMQ and RabbitMQ) – Default 100. Max 10,000. DocumentDB – Default 100. Max 10,000.
  --filter-criteria: record # An object that contains the filters for an event source. — shape: {Filters?: any}
  --maximum-batching-window-in-seconds: int # The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure MaximumBatchingWindowInSeconds to any value from 0 seconds to 300 seconds in increments of seconds. For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change MaximumBatchingWindowInSeconds in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping. Related setting: For streams and Amazon SQS event sources, when you set BatchSize to a value greater than 10, you must set MaximumBatchingWindowInSeconds to at least 1.
  --parallelization-factor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --starting-position: string@starting-position-completer # The position in a stream from which to start reading. Required for Amazon Kinesis, Amazon DynamoDB, and Amazon MSK Streams sources. AT_TIMESTAMP is supported only for Amazon Kinesis streams and Amazon DocumentDB.
  --starting-position-timestamp: string # With StartingPosition set to AT_TIMESTAMP, the time from which to start reading. (format: date-time)
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
  --maximum-record-age-in-seconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --bisect-batch-on-function-error: oneof<nothing, bool> # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --maximum-retry-attempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --tumbling-window-in-seconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --topics: list<string> # The name of the Kafka topic.
  --queues: list<string> # (MQ) The name of the Amazon MQ broker destination queue to consume.
  --source-access-configurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: any, URI?: any}
  --self-managed-event-source: record # The self-managed Apache Kafka cluster for your event source. — shape: {Endpoints?: any}
  --function-response-types: list<string> # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --amazon-managed-kafka-event-source-config: record # Specific configuration settings for an Amazon Managed Streaming for Apache Kafka (Amazon MSK) event source. — shape: {ConsumerGroupId?: any}
  --self-managed-kafka-event-source-config: record # Specific configuration settings for a self-managed Apache Kafka event source. — shape: {ConsumerGroupId?: any}
  --scaling-config: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: any}
  --document-db-event-source-config: record # Specific configuration settings for a DocumentDB event source. — shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
]: any -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-03-31/event-source-mappings/")
  let req_body = {"EventSourceArn": $event_source_arn, "FunctionName": $function_name, "Enabled": $enabled, "BatchSize": $batch_size, "FilterCriteria": $filter_criteria, "MaximumBatchingWindowInSeconds": $maximum_batching_window_in_seconds, "ParallelizationFactor": $parallelization_factor, "StartingPosition": $starting_position, "StartingPositionTimestamp": $starting_position_timestamp, "DestinationConfig": $destination_config, "MaximumRecordAgeInSeconds": $maximum_record_age_in_seconds, "BisectBatchOnFunctionError": $bisect_batch_on_function_error, "MaximumRetryAttempts": $maximum_retry_attempts, "TumblingWindowInSeconds": $tumbling_window_in_seconds, "Topics": $topics, "Queues": $queues, "SourceAccessConfigurations": $source_access_configurations, "SelfManagedEventSource": $self_managed_event_source, "FunctionResponseTypes": $function_response_types, "AmazonManagedKafkaEventSourceConfig": $amazon_managed_kafka_event_source_config, "SelfManagedKafkaEventSourceConfig": $self_managed_kafka_event_source_config, "ScalingConfig": $scaling_config, "DocumentDBEventSourceConfig": $document_db_event_source_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists event source mappings. Specify an EventSourceArn to show only event source mappings for a single event source.
#
# GET /2015-03-31/event-source-mappings/
# operationId: ListEventSourceMappings
export def "2015-03-31-event-source-mappings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-source-arn: string # The Amazon Resource Name (ARN) of the event source. Amazon Kinesis – The ARN of the data stream or a stream consumer. Amazon DynamoDB Streams – The ARN of the stream. Amazon Simple Queue Service – The ARN of the queue. Amazon Managed Streaming for Apache Kafka – The ARN of the cluster. Amazon MQ – The ARN of the broker. Amazon DocumentDB – The ARN of the DocumentDB change stream.
  --function-name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of event source mappings to return. Note that ListEventSourceMappings returns a maximum of 100 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, EventSourceMappings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EventSourceArn" $event_source_arn "scalar") (serialize-qp "FunctionName" $function_name "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-03-31/event-source-mappings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EventSourceArn": $event_source_arn, "FunctionName": $function_name, "Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Creates a Lambda function. To create a function, you need a deployment package (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html) and an execution role (https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role). The deployment package is a .zip file archive or container image that contains your function code. The execution role grants the function permission to use Amazon Web Services, such as Amazon CloudWatch Logs for log streaming and X-Ray for request tracing. If the deployment package is a container image (https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html), then you set the package type to Image. For a container image, the code property must include the URI of a container image in the Amazon ECR registry. You do not need to specify the handler and runtime properties. If the deployment package is a .zip file archive (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip), then you set the package type to Zip. For a .zip file archive, the code property specifies the location of the .zip file. You must also specify the handler and runtime properties. The code in the deployment package must be compatible with the target instruction set architecture of the function (x86-64 or arm64). If you do not specify the architecture, then the default value is x86-64. When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The State, StateReason, and StateReasonCode fields in the response from GetFunctionConfiguration indicate when the function is ready to invoke. For more information, see Lambda function states (https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html). A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the Publish parameter to create version 1 of your function from its initial configuration. The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with UpdateFunctionConfiguration. Function-level settings apply to both the unpublished and published versions of the function, and include tags (TagResource) and per-function concurrency limits (PutFunctionConcurrency). You can use code signing if your deployment package is a .zip file archive. To enable code signing for this function, specify the ARN of a code-signing configuration. When a user attempts to deploy a code package with UpdateFunctionCode, Lambda checks that the code package has a valid signature from a trusted publisher. The code-signing configuration includes set of signing profiles, which define the trusted publishers for this function. If another Amazon Web Services account or an Amazon Web Service invokes your function, use AddPermission to grant permission by creating a resource-based Identity and Access Management (IAM) policy. You can grant permissions at the function level, on a version, or on an alias. To invoke your function directly, use Invoke. To invoke your function in response to events in other Amazon Web Services, create an event source mapping (CreateEventSourceMapping), or configure a function trigger in the other service. For more information, see Invoking Lambda functions (https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html).
#
# POST /2015-03-31/functions
# operationId: CreateFunction
# --Code shape: {ZipFile?: any, S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ImageUri?: any}
# --VpcConfig shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --DeadLetterConfig shape: {TargetArn?: any}
# --Environment shape: {Variables?: any}
# --TracingConfig shape: {Mode?: any}
# --FileSystemConfigs item shape: {Arn: any, LocalMountPath: any}
# --ImageConfig shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
# --EphemeralStorage shape: {Size?: any}
# --SnapStart shape: {ApplyOn?: any}
export def "2015-03-31-functions create" [
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
  function_name: string # The name of the Lambda function. Name formats Function name – my-function. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:my-function. Partial ARN – 123456789012:function:my-function. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.
  --runtime: string@runtime-completer # The identifier of the function's runtime (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Runtime is required if the deployment package is a .zip file archive. The following list includes deprecated runtimes. For more information, see Runtime deprecation policy (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy).
  role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see Lambda programming model (https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html).
  code: record # The code for the Lambda function. You can either specify an object in Amazon S3, upload a .zip file archive deployment package directly, or specify the URI of a container image. — shape: {ZipFile?: any, S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ImageUri?: any}
  --description: string # A description of the function.
  --timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see Lambda execution environment (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).
  --memory-size: int # The amount of memory available to the function (https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console) at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --publish: oneof<nothing, bool> # Set to true to publish the first version of the function during creation.
  --vpc-config: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see Configuring a Lambda function to access resources in a VPC (https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --package-type: string@package-type-completer # The type of deployment package. Set to Image for container image and set to Zip for .zip file archive.
  --dead-letter-config: record # The dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq) for failed asynchronous invocations. — shape: {TargetArn?: any}
  --environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: any}
  --kms-key-arn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's environment variables (https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption). When Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html) is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --tracing-config: record # The function's X-Ray (https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html) tracing configuration. To sample and record incoming requests, set Mode to Active. — shape: {Mode?: any}
  --tags: record # A list of tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) to apply to the function.
  --layers: list<string> # A list of function layers (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --file-system-configs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: any, LocalMountPath: any}
  --image-config: record # Configuration values that override the container image Dockerfile settings. For more information, see Container image settings (https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms). — shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
  --code-signing-config-arn: string # To enable code signing for this function, specify the ARN of a code-signing configuration. A code-signing configuration includes a set of signing profiles, which define the trusted publishers for this function.
  --architectures: list<string> # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is x86_64.
  --ephemeral-storage: record # The size of the function's /tmp directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: any}
  --snap-start: record # The function's Lambda SnapStart setting. Set ApplyOn to PublishedVersions to create a snapshot of the initialized execution environment when you publish a function version. SnapStart is supported with the java11 runtime. For more information, see Improving startup performance with Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html). — shape: {ApplyOn?: any}
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-03-31/functions")
  let req_body = {"FunctionName": $function_name, "Runtime": $runtime, "Role": $role, "Handler": $handler, "Code": $code, "Description": $description, "Timeout": $timeout, "MemorySize": $memory_size, "Publish": $publish, "VpcConfig": $vpc_config, "PackageType": $package_type, "DeadLetterConfig": $dead_letter_config, "Environment": $environment, "KMSKeyArn": $kms_key_arn, "TracingConfig": $tracing_config, "Tags": $tags, "Layers": $layers, "FileSystemConfigs": $file_system_configs, "ImageConfig": $image_config, "CodeSigningConfigArn": $code_signing_config_arn, "Architectures": $architectures, "EphemeralStorage": $ephemeral_storage, "SnapStart": $snap_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a Lambda function URL with the specified configuration parameters. A function URL is a dedicated HTTP(S) endpoint that you can use to invoke your function.
#
# POST /2021-10-31/functions/{FunctionName}/url
# operationId: CreateFunctionUrlConfig
# --Cors shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "2021-10-31-functions-url create-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  auth_type: string@auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
  --cors: record # The cross-origin resource sharing (CORS) (https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --invoke-mode: string@invoke-mode-completer # Use one of the following options: BUFFERED – This is the default option. Lambda invokes your function using the Invoke API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB. RESPONSE_STREAM – Your function streams payload results as they become available. Lambda invokes your function using the InvokeWithResponseStream API operation. The maximum response payload size is 20 MB, however, you can request a quota increase (https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html).
]: any -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, InvokeMode: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-10-31/functions/{function_name}/url") $qp)
  let req_body = {"AuthType": $auth_type, "Cors": $cors, "InvokeMode": $invoke_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Deletes a Lambda function URL. When you delete a function URL, you can't recover it. Creating a new function URL results in a different URL address.
#
# DELETE /2021-10-31/functions/{FunctionName}/url
# operationId: DeleteFunctionUrlConfig
export def "2021-10-31-functions-url delete-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-10-31/functions/{function_name}/url") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Returns details about a Lambda function URL.
#
# GET /2021-10-31/functions/{FunctionName}/url
# operationId: GetFunctionUrlConfig
export def "2021-10-31-functions-url get-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, LastModifiedTime: record, InvokeMode: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-10-31/functions/{function_name}/url") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Updates the configuration for a Lambda function URL.
#
# PUT /2021-10-31/functions/{FunctionName}/url
# operationId: UpdateFunctionUrlConfig
# --Cors shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "2021-10-31-functions-url update-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --auth-type: string@auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
  --cors: record # The cross-origin resource sharing (CORS) (https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --invoke-mode: string@invoke-mode-completer # Use one of the following options: BUFFERED – This is the default option. Lambda invokes your function using the Invoke API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB. RESPONSE_STREAM – Your function streams payload results as they become available. Lambda invokes your function using the InvokeWithResponseStream API operation. The maximum response payload size is 20 MB, however, you can request a quota increase (https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html).
]: any -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, LastModifiedTime: record, InvokeMode: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-10-31/functions/{function_name}/url") $qp)
  let req_body = {"AuthType": $auth_type, "Cors": $cors, "InvokeMode": $invoke_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Deletes a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# DELETE /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: DeleteAlias
export def "2015-03-31-functions-aliases delete-alias" [
  function_name: string
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name), name: (encode-path-segment $name)} | format pattern "/2015-03-31/functions/{function_name}/aliases/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns details about a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# GET /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: GetAlias
export def "2015-03-31-functions-aliases get-alias" [
  function_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name), name: (encode-path-segment $name)} | format pattern "/2015-03-31/functions/{function_name}/aliases/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration of a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# PUT /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: UpdateAlias
# --RoutingConfig shape: {AdditionalVersionWeights?: any}
export def "2015-03-31-functions-aliases update-alias" [
  function_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --function-version: string # The function version that the alias invokes.
  --description: string # A description of the alias.
  --routing-config: record # The traffic-shifting (https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html) configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: any}
  --revision-id: string # Only update the alias if the revision ID matches the ID that's specified. Use this option to avoid modifying an alias that has changed since you last read it.
]: any -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name), name: (encode-path-segment $name)} | format pattern "/2015-03-31/functions/{function_name}/aliases/{name}"))
  let req_body = {"FunctionVersion": $function_version, "Description": $description, "RoutingConfig": $routing_config, "RevisionId": $revision_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the code signing configuration. You can delete the code signing configuration only if no function is using it.
#
# DELETE /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: DeleteCodeSigningConfig
export def "2020-04-22-code-signing-configs delete" [
  code_signing_config_arn: string
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
  if ($code_signing_config_arn | is-empty) { error make --unspanned { msg: "path parameter 'CodeSigningConfigArn' must be non-empty" } }
  let full_url = (build-url $base ({code_signing_config_arn: (encode-path-segment $code_signing_config_arn)} | format pattern "/2020-04-22/code-signing-configs/{code_signing_config_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about the specified code signing configuration.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: GetCodeSigningConfig
export def "2020-04-22-code-signing-configs get" [
  code_signing_config_arn: string
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
]: nothing -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code_signing_config_arn | is-empty) { error make --unspanned { msg: "path parameter 'CodeSigningConfigArn' must be non-empty" } }
  let full_url = (build-url $base ({code_signing_config_arn: (encode-path-segment $code_signing_config_arn)} | format pattern "/2020-04-22/code-signing-configs/{code_signing_config_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the code signing configuration. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function.
#
# PUT /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: UpdateCodeSigningConfig
# --AllowedPublishers shape: {SigningProfileVersionArns?: any}
# --CodeSigningPolicies shape: {UntrustedArtifactOnDeployment?: any}
export def "2020-04-22-code-signing-configs update" [
  code_signing_config_arn: string
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
  --description: string # Descriptive name for this code signing configuration.
  --allowed-publishers: record # List of signing profiles that can sign a code package. — shape: {SigningProfileVersionArns?: any}
  --code-signing-policies: record # Code signing configuration policies (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies) specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: any}
]: any -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code_signing_config_arn | is-empty) { error make --unspanned { msg: "path parameter 'CodeSigningConfigArn' must be non-empty" } }
  let full_url = (build-url $base ({code_signing_config_arn: (encode-path-segment $code_signing_config_arn)} | format pattern "/2020-04-22/code-signing-configs/{code_signing_config_arn}"))
  let req_body = {"Description": $description, "AllowedPublishers": $allowed_publishers, "CodeSigningPolicies": $code_signing_policies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an event source mapping (https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html). You can get the identifier of a mapping from the output of ListEventSourceMappings. When you delete an event source mapping, it enters a Deleting state and might not be completely deleted for several seconds.
#
# DELETE /2015-03-31/event-source-mappings/{UUID}
# operationId: DeleteEventSourceMapping
export def "2015-03-31-event-source-mappings delete" [
  uuid: string
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
]: nothing -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'UUID' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/2015-03-31/event-source-mappings/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns details about an event source mapping. You can get the identifier of a mapping from the output of ListEventSourceMappings.
#
# GET /2015-03-31/event-source-mappings/{UUID}
# operationId: GetEventSourceMapping
export def "2015-03-31-event-source-mappings get" [
  uuid: string
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
]: nothing -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'UUID' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/2015-03-31/event-source-mappings/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an event source mapping. You can change the function that Lambda invokes, or pause invocation and resume later from the same location. For details about how to configure different event sources, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html) The following error handling options are available only for stream sources (DynamoDB and Kinesis): BisectBatchOnFunctionError – If the function returns an error, split the batch in two and retry. DestinationConfig – Send discarded records to an Amazon SQS queue or Amazon SNS topic. MaximumRecordAgeInSeconds – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires MaximumRetryAttempts – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires. ParallelizationFactor – Process multiple batches from each shard concurrently. For information about which configuration parameters apply to each event source, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration)
#
# PUT /2015-03-31/event-source-mappings/{UUID}
# operationId: UpdateEventSourceMapping
# --FilterCriteria shape: {Filters?: any}
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
# --SourceAccessConfigurations item shape: {Type?: any, URI?: any}
# --ScalingConfig shape: {MaximumConcurrency?: any}
# --DocumentDBEventSourceConfig shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
export def "2015-03-31-event-source-mappings update" [
  uuid: string
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
  --function-name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --enabled: oneof<nothing, bool> # When true, the event source mapping is active. When false, Lambda pauses polling and invocation. Default: True
  --batch-size: int # The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB). Amazon Kinesis – Default 100. Max 10,000. Amazon DynamoDB Streams – Default 100. Max 10,000. Amazon Simple Queue Service – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10. Amazon Managed Streaming for Apache Kafka – Default 100. Max 10,000. Self-managed Apache Kafka – Default 100. Max 10,000. Amazon MQ (ActiveMQ and RabbitMQ) – Default 100. Max 10,000. DocumentDB – Default 100. Max 10,000.
  --filter-criteria: record # An object that contains the filters for an event source. — shape: {Filters?: any}
  --maximum-batching-window-in-seconds: int # The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure MaximumBatchingWindowInSeconds to any value from 0 seconds to 300 seconds in increments of seconds. For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change MaximumBatchingWindowInSeconds in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping. Related setting: For streams and Amazon SQS event sources, when you set BatchSize to a value greater than 10, you must set MaximumBatchingWindowInSeconds to at least 1.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
  --maximum-record-age-in-seconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --bisect-batch-on-function-error: oneof<nothing, bool> # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --maximum-retry-attempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --parallelization-factor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --source-access-configurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: any, URI?: any}
  --tumbling-window-in-seconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --function-response-types: list<string> # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --scaling-config: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: any}
  --document-db-event-source-config: record # Specific configuration settings for a DocumentDB event source. — shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
]: any -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'UUID' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/2015-03-31/event-source-mappings/{uuid}"))
  let req_body = {"FunctionName": $function_name, "Enabled": $enabled, "BatchSize": $batch_size, "FilterCriteria": $filter_criteria, "MaximumBatchingWindowInSeconds": $maximum_batching_window_in_seconds, "DestinationConfig": $destination_config, "MaximumRecordAgeInSeconds": $maximum_record_age_in_seconds, "BisectBatchOnFunctionError": $bisect_batch_on_function_error, "MaximumRetryAttempts": $maximum_retry_attempts, "ParallelizationFactor": $parallelization_factor, "SourceAccessConfigurations": $source_access_configurations, "TumblingWindowInSeconds": $tumbling_window_in_seconds, "FunctionResponseTypes": $function_response_types, "ScalingConfig": $scaling_config, "DocumentDBEventSourceConfig": $document_db_event_source_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Lambda function. To delete a specific function version, use the Qualifier parameter. Otherwise, all versions and aliases are deleted. To delete Lambda event source mappings that invoke a function, use DeleteEventSourceMapping. For Amazon Web Services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.
#
# DELETE /2015-03-31/functions/{FunctionName}
# operationId: DeleteFunction
export def "2015-03-31-functions delete" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version to delete. You can't delete a version that an alias references.
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
#
# GET /2015-03-31/functions/{FunctionName}
# operationId: GetFunction
export def "2015-03-31-functions get" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get details about a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Configuration: record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record, Error: record>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record>>, Code: record<RepositoryType: record, Location: record, ImageUri: record, ResolvedImageUri: record>, Tags: record, Concurrency: record<ReservedConcurrentExecutions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Removes the code signing configuration from the function.
#
# DELETE /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: DeleteFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config delete" [
  function_name: string
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2020-06-30/functions/{function_name}/code-signing-config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the code signing configuration for the specified function.
#
# GET /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: GetFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config get" [
  function_name: string
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
]: nothing -> record<CodeSigningConfigArn: record, FunctionName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2020-06-30/functions/{function_name}/code-signing-config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the code signing configuration for the function. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function.
#
# PUT /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: PutFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config update" [
  function_name: string
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
  code_signing_config_arn: string # The The Amazon Resource Name (ARN) of the code signing configuration.
]: any -> record<CodeSigningConfigArn: record, FunctionName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2020-06-30/functions/{function_name}/code-signing-config"))
  let req_body = {"CodeSigningConfigArn": $code_signing_config_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a concurrent execution limit from a function.
#
# DELETE /2017-10-31/functions/{FunctionName}/concurrency
# operationId: DeleteFunctionConcurrency
export def "2017-10-31-functions-concurrency delete" [
  function_name: string
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2017-10-31/functions/{function_name}/concurrency"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level. Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use GetFunction to see the current setting for a function. Use GetAccountSettings to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see Lambda function scaling (https://docs.aws.amazon.com/lambda/latest/dg/invocation-scaling.html).
#
# PUT /2017-10-31/functions/{FunctionName}/concurrency
# operationId: PutFunctionConcurrency
export def "2017-10-31-functions-concurrency update" [
  function_name: string
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
  reserved_concurrent_executions: int # The number of simultaneous executions to reserve for the function.
]: any -> record<ReservedConcurrentExecutions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2017-10-31/functions/{function_name}/concurrency"))
  let req_body = {"ReservedConcurrentExecutions": $reserved_concurrent_executions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# DELETE /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: DeleteFunctionEventInvokeConfig
export def "2019-09-25-functions-event-invoke-config delete" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-25/functions/{function_name}/event-invoke-config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Retrieves the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: GetFunctionEventInvokeConfig
export def "2019-09-25-functions-event-invoke-config get" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-25/functions/{function_name}/event-invoke-config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Configures options for asynchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html) on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use UpdateFunctionEventInvokeConfig. By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with UpdateFunctionConfiguration. To send an invocation record to a queue, topic, function, or event bus, specify a destination (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations). You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.
#
# PUT /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: PutFunctionEventInvokeConfig
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
export def "2019-09-25-functions-event-invoke-config update-by-function-name" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --maximum-retry-attempts: int # The maximum number of times to retry when the function returns an error.
  --maximum-event-age-in-seconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
]: any -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-25/functions/{function_name}/event-invoke-config") $qp)
  let req_body = {"MaximumRetryAttempts": $maximum_retry_attempts, "MaximumEventAgeInSeconds": $maximum_event_age_in_seconds, "DestinationConfig": $destination_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Updates the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# POST /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: UpdateFunctionEventInvokeConfig
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
export def "2019-09-25-functions-event-invoke-config update-by-function-name-1" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --maximum-retry-attempts: int # The maximum number of times to retry when the function returns an error.
  --maximum-event-age-in-seconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
]: any -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-25/functions/{function_name}/event-invoke-config") $qp)
  let req_body = {"MaximumRetryAttempts": $maximum_retry_attempts, "MaximumEventAgeInSeconds": $maximum_event_age_in_seconds, "DestinationConfig": $destination_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Deletes a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# operationId: DeleteLayerVersion
export def "2018-10-31-layers-versions delete" [
  layer_name: string
  version_number: int
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
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'VersionNumber' must be non-empty" } }
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name), version_number: (encode-path-segment $version_number)} | format pattern "/2018-10-31/layers/{layer_name}/versions/{version_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html), with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# operationId: GetLayerVersion
export def "2018-10-31-layers-versions get" [
  layer_name: string
  version_number: int
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
]: nothing -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'VersionNumber' must be non-empty" } }
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name), version_number: (encode-path-segment $version_number)} | format pattern "/2018-10-31/layers/{layer_name}/versions/{version_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the provisioned concurrency configuration for a function.
#
# DELETE /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# operationId: DeleteProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency delete-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name.
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-30/functions/{function_name}/provisioned-concurrency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Retrieves the provisioned concurrency configuration for a function's alias or version.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# operationId: GetProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency get-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RequestedProvisionedConcurrentExecutions: record, AvailableProvisionedConcurrentExecutions: record, AllocatedProvisionedConcurrentExecutions: record, Status: record, StatusReason: record, LastModified: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-30/functions/{function_name}/provisioned-concurrency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Adds a provisioned concurrency configuration to a function's alias or version.
#
# PUT /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# operationId: PutProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency update-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  provisioned_concurrent_executions: int # The amount of provisioned concurrency to allocate for the version or alias.
]: any -> record<RequestedProvisionedConcurrentExecutions: record, AvailableProvisionedConcurrentExecutions: record, AllocatedProvisionedConcurrentExecutions: record, Status: record, StatusReason: record, LastModified: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-30/functions/{function_name}/provisioned-concurrency") $qp)
  let req_body = {"ProvisionedConcurrentExecutions": $provisioned_concurrent_executions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Retrieves details about your account's limits (https://docs.aws.amazon.com/lambda/latest/dg/limits.html) and usage in an Amazon Web Services Region.
#
# GET /2016-08-19/account-settings/
# operationId: GetAccountSettings
export def "2016-08-19-account-settings get" [
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
]: nothing -> record<AccountLimit: record<TotalCodeSize: record, CodeSizeUnzipped: record, CodeSizeZipped: record, ConcurrentExecutions: record, UnreservedConcurrentExecutions: record>, AccountUsage: record<TotalCodeSize: record, FunctionCount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2016-08-19/account-settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use PutFunctionConcurrency.
#
# GET /2019-09-30/functions/{FunctionName}/concurrency
# operationId: GetFunctionConcurrency
export def "2019-09-30-functions-concurrency get" [
  function_name: string
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
]: nothing -> record<ReservedConcurrentExecutions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-30/functions/{function_name}/concurrency"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use UpdateFunctionConfiguration. To get all of a function's details, including function-level settings, use GetFunction.
#
# GET /2015-03-31/functions/{FunctionName}/configuration
# operationId: GetFunctionConfiguration
export def "2015-03-31-functions-configuration get" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get details about a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/configuration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Modify the version-specific settings of a Lambda function. When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The LastUpdateStatus, LastUpdateStatusReason, and LastUpdateStatusReasonCode fields in the response from GetFunctionConfiguration indicate when the update is complete and the function is processing events with the new configuration. For more information, see Lambda function states (https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html). These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version. To configure function concurrency, use PutFunctionConcurrency. To grant invoke permissions to an Amazon Web Services account or Amazon Web Service, use AddPermission.
#
# PUT /2015-03-31/functions/{FunctionName}/configuration
# operationId: UpdateFunctionConfiguration
# --VpcConfig shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --Environment shape: {Variables?: any}
# --DeadLetterConfig shape: {TargetArn?: any}
# --TracingConfig shape: {Mode?: any}
# --FileSystemConfigs item shape: {Arn: any, LocalMountPath: any}
# --ImageConfig shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
# --EphemeralStorage shape: {Size?: any}
# --SnapStart shape: {ApplyOn?: any}
export def "2015-03-31-functions-configuration update" [
  function_name: string
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
  --role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see Lambda programming model (https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html).
  --description: string # A description of the function.
  --timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see Lambda execution environment (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).
  --memory-size: int # The amount of memory available to the function (https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console) at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --vpc-config: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see Configuring a Lambda function to access resources in a VPC (https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: any}
  --runtime: string@runtime-completer # The identifier of the function's runtime (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Runtime is required if the deployment package is a .zip file archive. The following list includes deprecated runtimes. For more information, see Runtime deprecation policy (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy).
  --dead-letter-config: record # The dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq) for failed asynchronous invocations. — shape: {TargetArn?: any}
  --kms-key-arn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's environment variables (https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption). When Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html) is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --tracing-config: record # The function's X-Ray (https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html) tracing configuration. To sample and record incoming requests, set Mode to Active. — shape: {Mode?: any}
  --revision-id: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --layers: list<string> # A list of function layers (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --file-system-configs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: any, LocalMountPath: any}
  --image-config: record # Configuration values that override the container image Dockerfile settings. For more information, see Container image settings (https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms). — shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
  --ephemeral-storage: record # The size of the function's /tmp directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: any}
  --snap-start: record # The function's Lambda SnapStart setting. Set ApplyOn to PublishedVersions to create a snapshot of the initialized execution environment when you publish a function version. SnapStart is supported with the java11 runtime. For more information, see Improving startup performance with Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html). — shape: {ApplyOn?: any}
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/configuration"))
  let req_body = {"Role": $role, "Handler": $handler, "Description": $description, "Timeout": $timeout, "MemorySize": $memory_size, "VpcConfig": $vpc_config, "Environment": $environment, "Runtime": $runtime, "DeadLetterConfig": $dead_letter_config, "KMSKeyArn": $kms_key_arn, "TracingConfig": $tracing_config, "RevisionId": $revision_id, "Layers": $layers, "FileSystemConfigs": $file_system_configs, "ImageConfig": $image_config, "EphemeralStorage": $ephemeral_storage, "SnapStart": $snap_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns information about a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html), with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers
# operationId: GetLayerVersionByArn
export def "2018-10-31-layers get-version-by-arn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # The ARN of the layer version.
  --find: string@find-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Arn" $arn "scalar") (serialize-qp "find" $find "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2018-10-31/layers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Arn": $arn, "find": $find} | compact), body: null}
}

# Retrieves the runtime management configuration for a function's version. If the runtime update mode is Manual, this includes the ARN of the runtime version and the runtime update mode. If the runtime update mode is Auto or Function update, this includes the runtime update mode and null is returned for the ARN. For more information, see Runtime updates (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html).
#
# GET /2021-07-20/functions/{FunctionName}/runtime-management-config
# operationId: GetRuntimeManagementConfig
export def "2021-07-20-functions-runtime-management-config get" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version of the function. This can be $LATEST or a published version number. If no value is specified, the configuration for the $LATEST version is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UpdateRuntimeOn: record, RuntimeVersionArn: record, FunctionArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-07-20/functions/{function_name}/runtime-management-config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier} | compact), body: null}
}

# Sets the runtime management configuration for a function's version. For more information, see Runtime updates (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html).
#
# PUT /2021-07-20/functions/{FunctionName}/runtime-management-config
# operationId: PutRuntimeManagementConfig
export def "2021-07-20-functions-runtime-management-config update" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version of the function. This can be $LATEST or a published version number. If no value is specified, the configuration for the $LATEST version is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_runtime_on: string@update-runtime-on-completer # Specify the runtime update mode. Auto (default) - Automatically update to the most recent and secure runtime version using a Two-phase runtime version rollout (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-two-phase). This is the best choice for most customers to ensure they always benefit from runtime updates. Function update - Lambda updates the runtime of your function to the most recent and secure runtime version when you update your function. This approach synchronizes runtime updates with function deployments, giving you control over when runtime updates are applied and allowing you to detect and mitigate rare runtime update incompatibilities early. When using this setting, you need to regularly update your functions to keep their runtime up-to-date. Manual - You specify a runtime version in your function configuration. The function will use this runtime version indefinitely. In the rare case where a new runtime version is incompatible with an existing function, this allows you to roll back your function to an earlier runtime version. For more information, see Roll back a runtime version (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-rollback).
  --runtime-version-arn: string # The ARN of the runtime version you want the function to use. This is only required if you're using the Manual runtime update mode.
]: any -> record<UpdateRuntimeOn: record, FunctionArn: record, RuntimeVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-07-20/functions/{function_name}/runtime-management-config") $qp)
  let req_body = {"UpdateRuntimeOn": $update_runtime_on, "RuntimeVersionArn": $runtime_version_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set InvocationType to Event. For synchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html), details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the execution log (https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html) and trace (https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html). When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see Error handling and automatic retries in Lambda (https://docs.aws.amazon.com/lambda/latest/dg/invocation-retries.html). For asynchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html), Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-dlq). The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, quota (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html) errors, or issues with your function's code and configuration. For example, Lambda returns TooManyRequestsException if running the function would cause you to exceed a concurrency limit at either the account level (ConcurrentInvocationLimitExceeded) or function level (ReservedFunctionConcurrentInvocationLimitExceeded). For functions with a long timeout, your client might disconnect during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings. This operation requires permission for the lambda:InvokeFunction (https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html) action. For details on how to set up permissions for cross-account invocations, see Granting function access to other accounts (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke).
#
# POST /2015-03-31/functions/{FunctionName}/invocations
# operationId: Invoke
export def "2015-03-31-functions-invocations create-invoke" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to invoke a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-invocation-type: string@x-amz-invocation-type-completer # Choose from the following options. RequestResponse (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data. Event – Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if one is configured). The API response only includes a status code. DryRun – Validate parameter values and verify that the user or role has permission to invoke the function.
  --x-amz-log-type: string@x-amz-log-type-completer # Set to Tail to include the execution log in the response. Applies to synchronously invoked functions only.
  --x-amz-client-context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --payload: string # The JSON that you want to provide to your Lambda function as input. You can enter the JSON directly. For example, --payload '{ "key": "value" }'. You can also specify a file path. For example, --payload file://payload.json. (format: password)
]: any -> record<StatusCode: record, Payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/invocations") $qp)
  let req_body = {"Payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Invocation-Type": $x_amz_invocation_type, "X-Amz-Log-Type": $x_amz_log_type, "X-Amz-Client-Context": $x_amz_client_context} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# For asynchronous function invocation, use Invoke. Invokes a function asynchronously.
#
# POST /2014-11-13/functions/{FunctionName}/invoke-async/
# DEPRECATED
# operationId: InvokeAsync
@deprecated
export def "2014-11-13-functions-invoke-async create" [
  function_name: string
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
  invoke_args: string # The JSON that you want to provide to your Lambda function as input.
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2014-11-13/functions/{function_name}/invoke-async/"))
  let req_body = {"InvokeArgs": $invoke_args} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Configure your Lambda functions to stream response payloads back to clients. For more information, see Configuring a Lambda function to stream responses (https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html). This operation requires permission for the lambda:InvokeFunction (https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html) action. For details on how to set up permissions for cross-account invocations, see Granting function access to other accounts (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke).
#
# POST /2021-11-15/functions/{FunctionName}/response-streaming-invocations
# operationId: InvokeWithResponseStream
export def "2021-11-15-functions-response-streaming-invocations create-invoke-with-stream" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-invocation-type: string@x-amz-invocation-type-completer-1 # Use one of the following options: RequestResponse (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API operation response includes the function response and additional data. DryRun – Validate parameter values and verify that the IAM user or role has permission to invoke the function.
  --x-amz-log-type: string@x-amz-log-type-completer # Set to Tail to include the execution log in the response. Applies to synchronously invoked functions only.
  --x-amz-client-context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --payload: string # The JSON that you want to provide to your Lambda function as input. You can enter the JSON directly. For example, --payload '{ "key": "value" }'. You can also specify a file path. For example, --payload file://payload.json. (format: password)
]: any -> record<StatusCode: record, EventStream: record<PayloadChunk: record<Payload: record>, InvokeComplete: record<ErrorCode: record, ErrorDetails: record, LogResult: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-11-15/functions/{function_name}/response-streaming-invocations") $qp)
  let req_body = {"Payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Invocation-Type": $x_amz_invocation_type, "X-Amz-Log-Type": $x_amz_log_type, "X-Amz-Client-Context": $x_amz_client_context} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Qualifier": $qualifier} | compact), body: $req_body}
}

# Retrieves a list of configurations for asynchronous invocation for a function. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config/list
# operationId: ListFunctionEventInvokeConfigs
export def "2019-09-25-functions-event-invoke-config-list list" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of configurations to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<FunctionEventInvokeConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-25/functions/{function_name}/event-invoke-config/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Returns a list of Lambda function URLs for the specified function.
#
# GET /2021-10-31/functions/{FunctionName}/urls
# operationId: ListFunctionUrlConfigs
export def "2021-10-31-functions-urls list-configs" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of function URLs to return in the response. Note that ListFunctionUrlConfigs returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<FunctionUrlConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2021-10-31/functions/{function_name}/urls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call. Set FunctionVersion to ALL to include all published versions of each function in addition to the unpublished version. The ListFunctions operation returns a subset of the FunctionConfiguration fields. To get the additional fields (State, StateReasonCode, StateReason, LastUpdateStatus, LastUpdateStatusReason, LastUpdateStatusReasonCode, RuntimeVersionConfig) for a function or version, use GetFunction.
#
# GET /2015-03-31/functions/
# operationId: ListFunctions
export def "2015-03-31-functions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --master-region: string # For Lambda@Edge functions, the Amazon Web Services Region of the master function. For example, us-east-1 filters the list of functions to include only Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set FunctionVersion to ALL.
  --function-version: string@function-version-completer # Set to ALL to include entries for all published versions of each function.
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of functions to return in the response. Note that ListFunctions returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, Functions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MasterRegion" $master_region "scalar") (serialize-qp "FunctionVersion" $function_version "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-03-31/functions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MasterRegion": $master_region, "FunctionVersion": $function_version, "Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# List the functions that use the specified code signing configuration. You can use this method prior to deleting a code signing configuration, to verify that no functions are using it.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}/functions
# operationId: ListFunctionsByCodeSigningConfig
export def "2020-04-22-code-signing-configs-functions list" [
  code_signing_config_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Maximum number of items to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, FunctionArns: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code_signing_config_arn | is-empty) { error make --unspanned { msg: "path parameter 'CodeSigningConfigArn' must be non-empty" } }
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code_signing_config_arn: (encode-path-segment $code_signing_config_arn)} | format pattern "/2020-04-22/code-signing-configs/{code_signing_config_arn}/functions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Lists the versions of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Versions that have been deleted aren't listed. Specify a runtime identifier (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) to list only versions that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layer versions that are compatible with that architecture.
#
# GET /2018-10-31/layers/{LayerName}/versions
# operationId: ListLayerVersions
export def "2018-10-31-layers-versions list" [
  layer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compatible-runtime: string@compatible-runtime-completer # A runtime identifier. For example, go1.x.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of versions to return.
  --compatible-architecture: string@compatible-architecture-completer # The compatible instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, LayerVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  let qp = [(serialize-qp "CompatibleRuntime" $compatible_runtime "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "CompatibleArchitecture" $compatible_architecture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name)} | format pattern "/2018-10-31/layers/{layer_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"CompatibleRuntime": $compatible_runtime, "Marker": $marker, "MaxItems": $max_items, "CompatibleArchitecture": $compatible_architecture} | compact), body: null}
}

# Creates an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) from a ZIP archive. Each time you call PublishLayerVersion with the same layer name, a new version is created. Add layers to your function with CreateFunction or UpdateFunctionConfiguration.
#
# POST /2018-10-31/layers/{LayerName}/versions
# operationId: PublishLayerVersion
# --Content shape: {S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ZipFile?: any}
export def "2018-10-31-layers-versions publish" [
  layer_name: string
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
  --description: string # The description of the version.
  content: record # A ZIP archive that contains the contents of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). You can specify either an Amazon S3 location, or upload a layer archive directly. — shape: {S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ZipFile?: any}
  --compatible-runtimes: list<string> # A list of compatible function runtimes (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Used for filtering with ListLayers and ListLayerVersions.
  --license-info: string # The layer's software license. It can be any of the following: An SPDX license identifier (https://spdx.org/licenses/). For example, MIT. The URL of a license hosted on the internet. For example, https://opensource.org/licenses/MIT. The full text of the license.
  --compatible-architectures: list<string> # A list of compatible instruction set architectures (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
]: any -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name)} | format pattern "/2018-10-31/layers/{layer_name}/versions"))
  let req_body = {"Description": $description, "Content": $content, "CompatibleRuntimes": $compatible_runtimes, "LicenseInfo": $license_info, "CompatibleArchitectures": $compatible_architectures} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists Lambda layers (https://docs.aws.amazon.com/lambda/latest/dg/invocation-layers.html) and shows information about the latest version of each. Specify a runtime identifier (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) to list only layers that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layers that are compatible with that instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
#
# GET /2018-10-31/layers
# operationId: ListLayers
export def "2018-10-31-layers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compatible-runtime: string@compatible-runtime-completer # A runtime identifier. For example, go1.x.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of layers to return.
  --compatible-architecture: string@compatible-architecture-completer # The compatible instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, Layers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CompatibleRuntime" $compatible_runtime "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "CompatibleArchitecture" $compatible_architecture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2018-10-31/layers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"CompatibleRuntime": $compatible_runtime, "Marker": $marker, "MaxItems": $max_items, "CompatibleArchitecture": $compatible_architecture} | compact), body: null}
}

# Retrieves a list of provisioned concurrency configurations for a function.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# operationId: ListProvisionedConcurrencyConfigs
export def "2019-09-30-functions-provisioned-concurrency list-configs" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Specify a number to limit the number of configurations returned.
  --list: string@list-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ProvisionedConcurrencyConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "List" $list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2019-09-30/functions/{function_name}/provisioned-concurrency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items, "List": $list} | compact), body: null}
}

# Returns a function's tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html). You can also view tags with GetFunction.
#
# GET /2017-03-31/tags/{ARN}
# operationId: ListTags
export def "2017-03-31-tags list" [
  arn: string
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
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'ARN' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/2017-03-31/tags/{arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) to a function.
#
# POST /2017-03-31/tags/{ARN}
# operationId: TagResource
export def "2017-03-31-tags tag-resource" [
  arn: string
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
  tags: record # A list of tags to apply to the function.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'ARN' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/2017-03-31/tags/{arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of versions (https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html), with the version-specific configuration of each. Lambda returns up to 50 versions per call.
#
# GET /2015-03-31/functions/{FunctionName}/versions
# operationId: ListVersionsByFunction
export def "2015-03-31-functions-versions list" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of versions to return. Note that ListVersionsByFunction returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextMarker: record, Versions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let qp = [(serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxItems" $max_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Marker": $marker, "MaxItems": $max_items} | compact), body: null}
}

# Creates a version (https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html) from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change. Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use UpdateFunctionCode or UpdateFunctionConfiguration to update the function before publishing a version. Clients can invoke versions directly or with an alias. To create an alias, use CreateAlias.
#
# POST /2015-03-31/functions/{FunctionName}/versions
# operationId: PublishVersion
export def "2015-03-31-functions-versions publish" [
  function_name: string
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
  --code-sha256: string # Only publish a version if the hash value matches the value that's specified. Use this option to avoid publishing a version if the function code has changed since you last updated it. You can get the hash for the version that you uploaded from the output of UpdateFunctionCode.
  --description: string # A description for the version to override the description in the function configuration.
  --revision-id: string # Only update the function if the revision ID matches the ID that's specified. Use this option to avoid publishing a version if the function configuration has changed since you last updated it.
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/versions"))
  let req_body = {"CodeSha256": $code_sha256, "Description": $description, "RevisionId": $revision_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a statement from the permissions policy for a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). For more information, see AddLayerVersionPermission.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}
# operationId: RemoveLayerVersionPermission
export def "2018-10-31-layers-versions-policy delete-permission" [
  layer_name: string
  version_number: int
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision-id: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
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
  if ($layer_name | is-empty) { error make --unspanned { msg: "path parameter 'LayerName' must be non-empty" } }
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'VersionNumber' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'StatementId' must be non-empty" } }
  let qp = [(serialize-qp "RevisionId" $revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({layer_name: (encode-path-segment $layer_name), version_number: (encode-path-segment $version_number), statement_id: (encode-path-segment $statement_id)} | format pattern "/2018-10-31/layers/{layer_name}/versions/{version_number}/policy/{statement_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RevisionId": $revision_id} | compact), body: null}
}

# Revokes function-use permission from an Amazon Web Service or another Amazon Web Services account. You can get the ID of the statement from the output of GetPolicy.
#
# DELETE /2015-03-31/functions/{FunctionName}/policy/{StatementId}
# operationId: RemovePermission
export def "2015-03-31-functions-policy delete-permission" [
  function_name: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to remove permissions from a published version of the function.
  --revision-id: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
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
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'StatementId' must be non-empty" } }
  let qp = [(serialize-qp "Qualifier" $qualifier "scalar") (serialize-qp "RevisionId" $revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name), statement_id: (encode-path-segment $statement_id)} | format pattern "/2015-03-31/functions/{function_name}/policy/{statement_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Qualifier": $qualifier, "RevisionId": $revision_id} | compact), body: null}
}

# Removes tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) from a function.
#
# DELETE /2017-03-31/tags/{ARN}
# operationId: UntagResource
export def "2017-03-31-tags untag-resource" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # A list of tag keys to remove from the function.
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
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'ARN' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/2017-03-31/tags/{arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Updates a Lambda function's code. If code signing is enabled for the function, the code package must be signed by a trusted publisher. For more information, see Configuring code signing for Lambda (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html). If the function's package type is Image, then you must specify the code package in ImageUri as the URI of a container image (https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) in the Amazon ECR registry. If the function's package type is Zip, then you must specify the deployment package as a .zip file archive (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip). Enter the Amazon S3 bucket and key of the code .zip file location. You can also provide the function code inline using the ZipFile field. The code in the deployment package must be compatible with the target instruction set architecture of the function (x86-64 or arm64). The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version. For a function defined as a container image, Lambda resolves the image tag to an image digest. In Amazon ECR, if you update the image tag to a new image, Lambda does not automatically update the function.
#
# PUT /2015-03-31/functions/{FunctionName}/code
# operationId: UpdateFunctionCode
export def "2015-03-31-functions-code update" [
  function_name: string
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
  --zip-file: string # The base64-encoded contents of the deployment package. Amazon Web Services SDK and CLI clients handle the encoding for you. Use only with a function defined with a .zip file archive deployment package. (format: password)
  --s3-bucket: string # An Amazon S3 bucket in the same Amazon Web Services Region as your function. The bucket can be in a different Amazon Web Services account. Use only with a function defined with a .zip file archive deployment package.
  --s3-key: string # The Amazon S3 key of the deployment package. Use only with a function defined with a .zip file archive deployment package.
  --s3-object-version: string # For versioned objects, the version of the deployment package object to use.
  --image-uri: string # URI of a container image in the Amazon ECR registry. Do not use for a function defined with a .zip file archive.
  --publish: oneof<nothing, bool> # Set to true to publish a new version of the function after updating the code. This has the same effect as calling PublishVersion separately.
  --body-dry-run: oneof<nothing, bool> # Set to true to validate the request parameters and access permissions without modifying the function code.
  --revision-id: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --architectures: list<string> # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is x86_64.
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($function_name | is-empty) { error make --unspanned { msg: "path parameter 'FunctionName' must be non-empty" } }
  let full_url = (build-url $base ({function_name: (encode-path-segment $function_name)} | format pattern "/2015-03-31/functions/{function_name}/code"))
  let req_body = {"ZipFile": $zip_file, "S3Bucket": $s3_bucket, "S3Key": $s3_key, "S3ObjectVersion": $s3_object_version, "ImageUri": $image_uri, "Publish": $publish, "DryRun": $body_dry_run, "RevisionId": $revision_id, "Architectures": $architectures} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
