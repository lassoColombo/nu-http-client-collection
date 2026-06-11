# Auto-generated client for AWS Lambda v2015-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lambda/2015-03-31/openapi.json
# Auth: --token flag or $env.AWS_LAMBDA_TOKEN

const BASE_URL = "http://lambda.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_LAMBDA_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://lambda.us-east-1.amazonaws.com" "http://lambda.us-east-2.amazonaws.com" "http://lambda.us-west-1.amazonaws.com" "http://lambda.us-west-2.amazonaws.com" "http://lambda.us-gov-west-1.amazonaws.com" "http://lambda.us-gov-east-1.amazonaws.com" "http://lambda.ca-central-1.amazonaws.com" "http://lambda.eu-north-1.amazonaws.com" "http://lambda.eu-west-1.amazonaws.com" "http://lambda.eu-west-2.amazonaws.com" "http://lambda.eu-west-3.amazonaws.com" "http://lambda.eu-central-1.amazonaws.com" "http://lambda.eu-south-1.amazonaws.com" "http://lambda.af-south-1.amazonaws.com" "http://lambda.ap-northeast-1.amazonaws.com" "http://lambda.ap-northeast-2.amazonaws.com" "http://lambda.ap-northeast-3.amazonaws.com" "http://lambda.ap-southeast-1.amazonaws.com" "http://lambda.ap-southeast-2.amazonaws.com" "http://lambda.ap-east-1.amazonaws.com" "http://lambda.ap-south-1.amazonaws.com" "http://lambda.sa-east-1.amazonaws.com" "http://lambda.me-south-1.amazonaws.com" "https://lambda.us-east-1.amazonaws.com" "https://lambda.us-east-2.amazonaws.com" "https://lambda.us-west-1.amazonaws.com" "https://lambda.us-west-2.amazonaws.com" "https://lambda.us-gov-west-1.amazonaws.com" "https://lambda.us-gov-east-1.amazonaws.com" "https://lambda.ca-central-1.amazonaws.com" "https://lambda.eu-north-1.amazonaws.com" "https://lambda.eu-west-1.amazonaws.com" "https://lambda.eu-west-2.amazonaws.com" "https://lambda.eu-west-3.amazonaws.com" "https://lambda.eu-central-1.amazonaws.com" "https://lambda.eu-south-1.amazonaws.com" "https://lambda.af-south-1.amazonaws.com" "https://lambda.ap-northeast-1.amazonaws.com" "https://lambda.ap-northeast-2.amazonaws.com" "https://lambda.ap-northeast-3.amazonaws.com" "https://lambda.ap-southeast-1.amazonaws.com" "https://lambda.ap-southeast-2.amazonaws.com" "https://lambda.ap-east-1.amazonaws.com" "https://lambda.ap-south-1.amazonaws.com" "https://lambda.sa-east-1.amazonaws.com" "https://lambda.me-south-1.amazonaws.com" "http://lambda.cn-north-1.amazonaws.com.cn" "http://lambda.cn-northwest-1.amazonaws.com.cn" "https://lambda.cn-north-1.amazonaws.com.cn" "https://lambda.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def FunctionUrlAuthType-completer [] { ["AWS_IAM" "NONE"] }
def StartingPosition-completer [] { ["AT_TIMESTAMP" "LATEST" "TRIM_HORIZON"] }
def Runtime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def PackageType-completer [] { ["Image" "Zip"] }
def AuthType-completer [] { ["AWS_IAM" "NONE"] }
def InvokeMode-completer [] { ["BUFFERED" "RESPONSE_STREAM"] }
def find-completer [] { ["LayerVersion"] }
def UpdateRuntimeOn-completer [] { ["Auto" "FunctionUpdate" "Manual"] }
def X-Amz-Invocation-Type-completer [] { ["DryRun" "Event" "RequestResponse"] }
def X-Amz-Log-Type-completer [] { ["None" "Tail"] }
def X-Amz-Invocation-Type-completer-1 [] { ["DryRun" "RequestResponse"] }
def FunctionVersion-completer [] { ["ALL"] }
def CompatibleRuntime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def CompatibleArchitecture-completer [] { ["arm64" "x86_64"] }
def List-completer [] { ["ALL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2018-10-31-layers-versions-policy AddLayerVersionPermission" } } | get name | first)
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

# <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all accounts in an organization, or all Amazon Web Services accounts. </p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
#
# POST /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# operationId: AddLayerVersionPermission
export def "2018-10-31-layers-versions-policy AddLayerVersionPermission" [
  LayerName: string
  VersionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RevisionId: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  StatementId: string # An identifier that distinguishes the policy from others on the same layer version.
  Action: string # The API action that grants access to the layer. For example, <code>lambda:GetLayerVersion</code>.
  Principal: string # An account ID, or <code>*</code> to grant layer usage permission to all accounts in an organization, or all Amazon Web Services accounts (if <code>organizationId</code> is not specified). For the last case, make sure that you really do want all Amazon Web Services accounts to have usage permission to this layer. 
  --OrganizationId: string # With the principal set to <code>*</code>, grant permission to all accounts in the specified organization.
]: any -> record<Statement: record, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RevisionId" $RevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions/($VersionNumber)/policy" $qp)
  let body = {StatementId: $StatementId, Action: $Action, Principal: $Principal, OrganizationId: $OrganizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# operationId: GetLayerVersionPolicy
export def "2018-10-31-layers-versions-policy GetLayerVersionPolicy" [
  LayerName: string
  VersionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Policy: record, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions/($VersionNumber)/policy")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Grants an Amazon Web Service, Amazon Web Services account, or Amazon Web Services organization permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function. Note: Lambda does not support adding policies to version $LATEST.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. To grant permission to an organization defined in Organizations, specify the organization ID as the <code>PrincipalOrgID</code>. For Amazon Web Services, the principal is a domain-style identifier that the service defines, such as <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For Amazon Web Services, you can also specify the ARN of the associated resource as the <code>SourceArn</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This operation adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Using resource-based policies for Lambda</a>.</p>
#
# POST /2015-03-31/functions/{FunctionName}/policy
# operationId: AddPermission
export def "2015-03-31-functions-policy AddPermission" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to add permissions to a published version of the function.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  StatementId: string # A statement identifier that differentiates the statement from others in the same policy.
  Action: string # The action that the principal can use on the function. For example, <code>lambda:InvokeFunction</code> or <code>lambda:GetFunction</code>.
  Principal: string # The Amazon Web Service or Amazon Web Services account that invokes the function. If you specify a service, use <code>SourceArn</code> or <code>SourceAccount</code> to limit who can invoke the function through that service.
  --SourceArn: string # <p>For Amazon Web Services, the ARN of the Amazon Web Services resource that invokes the function. For example, an Amazon S3 bucket or Amazon SNS topic.</p> <p>Note that Lambda configures the comparison using the <code>StringLike</code> operator.</p>
  --SourceAccount: string # For Amazon Web Service, the ID of the Amazon Web Services account that owns the resource. Use this together with <code>SourceArn</code> to ensure that the specified account owns the resource. It is possible for an Amazon S3 bucket to be deleted by its owner and recreated by another account.
  --EventSourceToken: string # For Alexa Smart Home functions, a token that the invoker must supply.
  --RevisionId: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --PrincipalOrgID: string # The identifier for your organization in Organizations. Use this to grant permissions to all the Amazon Web Services accounts under this organization.
  --FunctionUrlAuthType: string@FunctionUrlAuthType-completer # The type of authentication that your function URL uses. Set to <code>AWS_IAM</code> if you want to restrict access to authenticated users only. Set to <code>NONE</code> if you want to bypass IAM authentication to create a public endpoint. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html">Security and auth model for Lambda function URLs</a>.
]: any -> record<Statement: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/policy" $qp)
  let body = {StatementId: $StatementId, Action: $Action, Principal: $Principal, SourceArn: $SourceArn, SourceAccount: $SourceAccount, EventSourceToken: $EventSourceToken, RevisionId: $RevisionId, PrincipalOrgID: $PrincipalOrgID, FunctionUrlAuthType: $FunctionUrlAuthType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
#
# GET /2015-03-31/functions/{FunctionName}/policy
# operationId: GetPolicy
export def "2015-03-31-functions-policy GetPolicy" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to get the policy for that resource.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Policy: record, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/policy" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
#
# POST /2015-03-31/functions/{FunctionName}/aliases
# operationId: CreateAlias
# --RoutingConfig shape: {AdditionalVersionWeights?: any}
export def "2015-03-31-functions-aliases CreateAlias" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Name: string # The name of the alias.
  FunctionVersion: string # The function version that the alias invokes.
  --Description: string # A description of the alias.
  --RoutingConfig: record # The <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html">traffic-shifting</a> configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: any}
]: any -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/aliases")
  let body = {Name: $Name, FunctionVersion: $FunctionVersion, Description: $Description, RoutingConfig: $RoutingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html">aliases</a> for a Lambda function.
#
# GET /2015-03-31/functions/{FunctionName}/aliases
# operationId: ListAliases
export def "2015-03-31-functions-aliases ListAliases" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FunctionVersion: string # Specify a function version to only list aliases that invoke that version.
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # Limit the number of aliases returned.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, Aliases: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FunctionVersion" $FunctionVersion "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/aliases" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a code signing configuration. A <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html">code signing configuration</a> defines a list of allowed signing profiles and defines the code-signing validation policy (action to be taken if deployment validation checks fail). 
#
# POST /2020-04-22/code-signing-configs/
# operationId: CreateCodeSigningConfig
# --AllowedPublishers shape: {SigningProfileVersionArns?: any}
# --CodeSigningPolicies shape: {UntrustedArtifactOnDeployment?: any}
export def "2020-04-22-code-signing-configs CreateCodeSigningConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Description: string # Descriptive name for this code signing configuration.
  AllowedPublishers: record # List of signing profiles that can sign a code package.  — shape: {SigningProfileVersionArns?: any}
  --CodeSigningPolicies: record # Code signing configuration <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies">policies</a> specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: any}
]: any -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2020-04-22/code-signing-configs/")
  let body = {Description: $Description, AllowedPublishers: $AllowedPublishers, CodeSigningPolicies: $CodeSigningPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuring-codesigning.html">code signing configurations</a>. A request returns up to 10,000 configurations per call. You can use the <code>MaxItems</code> parameter to return fewer configurations per call. 
#
# GET /2020-04-22/code-signing-configs/
# operationId: ListCodeSigningConfigs
export def "2020-04-22-code-signing-configs ListCodeSigningConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # Maximum number of items to return.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, CodeSigningConfigs: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-04-22/code-signing-configs/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates a mapping between an event source and an Lambda function. Lambda reads items from the event source and invokes the function.</p> <p>For details about how to configure different event sources, see the following topics. </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping"> Amazon DynamoDB Streams</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping"> Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource"> Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping"> Amazon MQ and RabbitMQ</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html"> Amazon MSK</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html"> Apache Kafka</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html"> Amazon DocumentDB</a> </p> </li> </ul> <p>The following error handling options are available only for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> – If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> – Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires</p> </li> <li> <p> <code>MaximumRetryAttempts</code> – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.</p> </li> <li> <p> <code>ParallelizationFactor</code> – Process multiple batches from each shard concurrently.</p> </li> </ul> <p>For information about which configuration parameters apply to each event source, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params"> Amazon DynamoDB Streams</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params"> Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params"> Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params"> Amazon MQ and RabbitMQ</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms"> Amazon MSK</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms"> Apache Kafka</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration"> Amazon DocumentDB</a> </p> </li> </ul>
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
export def "2015-03-31-event-source-mappings CreateEventSourceMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --EventSourceArn: string # <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> – The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> – The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> – The ARN of the queue.</p> </li> <li> <p> <b>Amazon Managed Streaming for Apache Kafka</b> – The ARN of the cluster.</p> </li> <li> <p> <b>Amazon MQ</b> – The ARN of the broker.</p> </li> <li> <p> <b>Amazon DocumentDB</b> – The ARN of the DocumentDB change stream.</p> </li> </ul>
  FunctionName: string # <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> – <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> – <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  --Enabled: string@bool-completer # <p>When true, the event source mapping is active. When false, Lambda pauses polling and invocation.</p> <p>Default: True</p>
  --BatchSize: int # <p>The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB).</p> <ul> <li> <p> <b>Amazon Kinesis</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10.</p> </li> <li> <p> <b>Amazon Managed Streaming for Apache Kafka</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Self-managed Apache Kafka</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon MQ (ActiveMQ and RabbitMQ)</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>DocumentDB</b> – Default 100. Max 10,000.</p> </li> </ul>
  --FilterCriteria: record #  An object that contains the filters for an event source.  — shape: {Filters?: any}
  --MaximumBatchingWindowInSeconds: int # <p>The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure <code>MaximumBatchingWindowInSeconds</code> to any value from 0 seconds to 300 seconds in increments of seconds.</p> <p>For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change <code>MaximumBatchingWindowInSeconds</code> in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping.</p> <p>Related setting: For streams and Amazon SQS event sources, when you set <code>BatchSize</code> to a value greater than 10, you must set <code>MaximumBatchingWindowInSeconds</code> to at least 1.</p>
  --ParallelizationFactor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --StartingPosition: string@StartingPosition-completer # The position in a stream from which to start reading. Required for Amazon Kinesis, Amazon DynamoDB, and Amazon MSK Streams sources. <code>AT_TIMESTAMP</code> is supported only for Amazon Kinesis streams and Amazon DocumentDB.
  --StartingPositionTimestamp: string # With <code>StartingPosition</code> set to <code>AT_TIMESTAMP</code>, the time from which to start reading. (format: date-time)
  --DestinationConfig: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
  --MaximumRecordAgeInSeconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --BisectBatchOnFunctionError: string@bool-completer # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --MaximumRetryAttempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --TumblingWindowInSeconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --Topics: list # The name of the Kafka topic.
  --Queues: list #  (MQ) The name of the Amazon MQ broker destination queue to consume. 
  --SourceAccessConfigurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: any, URI?: any}
  --SelfManagedEventSource: record # The self-managed Apache Kafka cluster for your event source. — shape: {Endpoints?: any}
  --FunctionResponseTypes: list # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --AmazonManagedKafkaEventSourceConfig: record # Specific configuration settings for an Amazon Managed Streaming for Apache Kafka (Amazon MSK) event source. — shape: {ConsumerGroupId?: any}
  --SelfManagedKafkaEventSourceConfig: record # Specific configuration settings for a self-managed Apache Kafka event source. — shape: {ConsumerGroupId?: any}
  --ScalingConfig: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: any}
  --DocumentDBEventSourceConfig: record #  Specific configuration settings for a DocumentDB event source.  — shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
]: any -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-03-31/event-source-mappings/")
  let body = {EventSourceArn: $EventSourceArn, FunctionName: $FunctionName, Enabled: $Enabled, BatchSize: $BatchSize, FilterCriteria: $FilterCriteria, MaximumBatchingWindowInSeconds: $MaximumBatchingWindowInSeconds, ParallelizationFactor: $ParallelizationFactor, StartingPosition: $StartingPosition, StartingPositionTimestamp: $StartingPositionTimestamp, DestinationConfig: $DestinationConfig, MaximumRecordAgeInSeconds: $MaximumRecordAgeInSeconds, BisectBatchOnFunctionError: $BisectBatchOnFunctionError, MaximumRetryAttempts: $MaximumRetryAttempts, TumblingWindowInSeconds: $TumblingWindowInSeconds, Topics: $Topics, Queues: $Queues, SourceAccessConfigurations: $SourceAccessConfigurations, SelfManagedEventSource: $SelfManagedEventSource, FunctionResponseTypes: $FunctionResponseTypes, AmazonManagedKafkaEventSourceConfig: $AmazonManagedKafkaEventSourceConfig, SelfManagedKafkaEventSourceConfig: $SelfManagedKafkaEventSourceConfig, ScalingConfig: $ScalingConfig, DocumentDBEventSourceConfig: $DocumentDBEventSourceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists event source mappings. Specify an <code>EventSourceArn</code> to show only event source mappings for a single event source.
#
# GET /2015-03-31/event-source-mappings/
# operationId: ListEventSourceMappings
export def "2015-03-31-event-source-mappings ListEventSourceMappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --EventSourceArn: string # <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> – The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> – The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> – The ARN of the queue.</p> </li> <li> <p> <b>Amazon Managed Streaming for Apache Kafka</b> – The ARN of the cluster.</p> </li> <li> <p> <b>Amazon MQ</b> – The ARN of the broker.</p> </li> <li> <p> <b>Amazon DocumentDB</b> – The ARN of the DocumentDB change stream.</p> </li> </ul>
  --FunctionName: string # <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> – <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> – <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  --Marker: string # A pagination token returned by a previous call.
  --MaxItems: int # The maximum number of event source mappings to return. Note that ListEventSourceMappings returns a maximum of 100 items in each response, even if you set the number higher.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, EventSourceMappings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EventSourceArn" $EventSourceArn "scalar") (serialize-qp "FunctionName" $FunctionName "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-03-31/event-source-mappings/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package is a .zip file archive or container image that contains your function code. The execution role grants the function permission to use Amazon Web Services, such as Amazon CloudWatch Logs for log streaming and X-Ray for request tracing.</p> <p>If the deployment package is a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html">container image</a>, then you set the package type to <code>Image</code>. For a container image, the code property must include the URI of a container image in the Amazon ECR registry. You do not need to specify the handler and runtime properties.</p> <p>If the deployment package is a <a href="https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip">.zip file archive</a>, then you set the package type to <code>Zip</code>. For a .zip file archive, the code property specifies the location of the .zip file. You must also specify the handler and runtime properties. The code in the deployment package must be compatible with the target instruction set architecture of the function (<code>x86-64</code> or <code>arm64</code>). If you do not specify the architecture, then the default value is <code>x86-64</code>.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Lambda function states</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>You can use code signing if your deployment package is a .zip file archive. To enable code signing for this function, specify the ARN of a code-signing configuration. When a user attempts to deploy a code package with <a>UpdateFunctionCode</a>, Lambda checks that the code package has a valid signature from a trusted publisher. The code-signing configuration includes set of signing profiles, which define the trusted publishers for this function.</p> <p>If another Amazon Web Services account or an Amazon Web Service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based Identity and Access Management (IAM) policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other Amazon Web Services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Lambda functions</a>.</p>
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
export def "2015-03-31-functions CreateFunction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  FunctionName: string # <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> – <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> – <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  --Runtime: string@Runtime-completer # <p>The identifier of the function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime</a>. Runtime is required if the deployment package is a .zip file archive.</p> <p>The following list includes deprecated runtimes. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy">Runtime deprecation policy</a>.</p>
  Role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --Handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html">Lambda programming model</a>.
  Code: record # The code for the Lambda function. You can either specify an object in Amazon S3, upload a .zip file archive deployment package directly, or specify the URI of a container image. — shape: {ZipFile?: any, S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ImageUri?: any}
  --Description: string # A description of the function.
  --Timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html">Lambda execution environment</a>.
  --MemorySize: int # The amount of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console">memory available to the function</a> at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --Publish: string@bool-completer # Set to true to publish the first version of the function during creation.
  --VpcConfig: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html">Configuring a Lambda function to access resources in a VPC</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --PackageType: string@PackageType-completer # The type of deployment package. Set to <code>Image</code> for container image and set to <code>Zip</code> for .zip file archive.
  --DeadLetterConfig: record # The <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a> for failed asynchronous invocations. — shape: {TargetArn?: any}
  --Environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: any}
  --KMSKeyArn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption">environment variables</a>. When <a href="https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html">Lambda SnapStart</a> is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --TracingConfig: record # The function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html">X-Ray</a> tracing configuration. To sample and record incoming requests, set <code>Mode</code> to <code>Active</code>. — shape: {Mode?: any}
  --Tags: record # A list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to apply to the function.
  --Layers: list # A list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">function layers</a> to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --FileSystemConfigs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: any, LocalMountPath: any}
  --ImageConfig: record # Configuration values that override the container image Dockerfile settings. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms">Container image settings</a>. — shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
  --CodeSigningConfigArn: string # To enable code signing for this function, specify the ARN of a code-signing configuration. A code-signing configuration includes a set of signing profiles, which define the trusted publishers for this function.
  --Architectures: list # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is <code>x86_64</code>.
  --EphemeralStorage: record # The size of the function's <code>/tmp</code> directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: any}
  --SnapStart: record # <p>The function's Lambda SnapStart setting. Set <code>ApplyOn</code> to <code>PublishedVersions</code> to create a snapshot of the initialized execution environment when you publish a function version.</p> <p>SnapStart is supported with the <code>java11</code> runtime. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html">Improving startup performance with Lambda SnapStart</a>.</p> — shape: {ApplyOn?: any}
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-03-31/functions")
  let body = {FunctionName: $FunctionName, Runtime: $Runtime, Role: $Role, Handler: $Handler, Code: $Code, Description: $Description, Timeout: $Timeout, MemorySize: $MemorySize, Publish: $Publish, VpcConfig: $VpcConfig, PackageType: $PackageType, DeadLetterConfig: $DeadLetterConfig, Environment: $Environment, KMSKeyArn: $KMSKeyArn, TracingConfig: $TracingConfig, Tags: $Tags, Layers: $Layers, FileSystemConfigs: $FileSystemConfigs, ImageConfig: $ImageConfig, CodeSigningConfigArn: $CodeSigningConfigArn, Architectures: $Architectures, EphemeralStorage: $EphemeralStorage, SnapStart: $SnapStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Lambda function URL with the specified configuration parameters. A function URL is a dedicated HTTP(S) endpoint that you can use to invoke your function.
#
# POST /2021-10-31/functions/{FunctionName}/url
# operationId: CreateFunctionUrlConfig
# --Cors shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "2021-10-31-functions-url CreateFunctionUrlConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  AuthType: string@AuthType-completer # The type of authentication that your function URL uses. Set to <code>AWS_IAM</code> if you want to restrict access to authenticated users only. Set to <code>NONE</code> if you want to bypass IAM authentication to create a public endpoint. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html">Security and auth model for Lambda function URLs</a>.
  --Cors: record # The <a href="https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS">cross-origin resource sharing (CORS)</a> settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --InvokeMode: string@InvokeMode-completer # <p>Use one of the following options:</p> <ul> <li> <p> <code>BUFFERED</code> – This is the default option. Lambda invokes your function using the <code>Invoke</code> API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB.</p> </li> <li> <p> <code>RESPONSE_STREAM</code> – Your function streams payload results as they become available. Lambda invokes your function using the <code>InvokeWithResponseStream</code> API operation. The maximum response payload size is 20 MB, however, you can <a href="https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html">request a quota increase</a>.</p> </li> </ul>
]: any -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, InvokeMode: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-10-31/functions/($FunctionName)/url" $qp)
  let body = {AuthType: $AuthType, Cors: $Cors, InvokeMode: $InvokeMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Lambda function URL. When you delete a function URL, you can't recover it. Creating a new function URL results in a different URL address.
#
# DELETE /2021-10-31/functions/{FunctionName}/url
# operationId: DeleteFunctionUrlConfig
export def "2021-10-31-functions-url DeleteFunctionUrlConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-10-31/functions/($FunctionName)/url" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details about a Lambda function URL.
#
# GET /2021-10-31/functions/{FunctionName}/url
# operationId: GetFunctionUrlConfig
export def "2021-10-31-functions-url GetFunctionUrlConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, LastModifiedTime: record, InvokeMode: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-10-31/functions/($FunctionName)/url" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the configuration for a Lambda function URL.
#
# PUT /2021-10-31/functions/{FunctionName}/url
# operationId: UpdateFunctionUrlConfig
# --Cors shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
export def "2021-10-31-functions-url UpdateFunctionUrlConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --AuthType: string@AuthType-completer # The type of authentication that your function URL uses. Set to <code>AWS_IAM</code> if you want to restrict access to authenticated users only. Set to <code>NONE</code> if you want to bypass IAM authentication to create a public endpoint. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html">Security and auth model for Lambda function URLs</a>.
  --Cors: record # The <a href="https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS">cross-origin resource sharing (CORS)</a> settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: any, AllowHeaders?: any, AllowMethods?: any, AllowOrigins?: any, ExposeHeaders?: any, MaxAge?: any}
  --InvokeMode: string@InvokeMode-completer # <p>Use one of the following options:</p> <ul> <li> <p> <code>BUFFERED</code> – This is the default option. Lambda invokes your function using the <code>Invoke</code> API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB.</p> </li> <li> <p> <code>RESPONSE_STREAM</code> – Your function streams payload results as they become available. Lambda invokes your function using the <code>InvokeWithResponseStream</code> API operation. The maximum response payload size is 20 MB, however, you can <a href="https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html">request a quota increase</a>.</p> </li> </ul>
]: any -> record<FunctionUrl: record, FunctionArn: record, AuthType: record, Cors: record<AllowCredentials: record, AllowHeaders: record, AllowMethods: record, AllowOrigins: record, ExposeHeaders: record, MaxAge: record>, CreationTime: record, LastModifiedTime: record, InvokeMode: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-10-31/functions/($FunctionName)/url" $qp)
  let body = {AuthType: $AuthType, Cors: $Cors, InvokeMode: $InvokeMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html">alias</a>.
#
# DELETE /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: DeleteAlias
export def "2015-03-31-functions-aliases DeleteAlias" [
  FunctionName: string
  Name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/aliases/($Name)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html">alias</a>.
#
# GET /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: GetAlias
export def "2015-03-31-functions-aliases GetAlias" [
  FunctionName: string
  Name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/aliases/($Name)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html">alias</a>.
#
# PUT /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: UpdateAlias
# --RoutingConfig shape: {AdditionalVersionWeights?: any}
export def "2015-03-31-functions-aliases UpdateAlias" [
  FunctionName: string
  Name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --FunctionVersion: string # The function version that the alias invokes.
  --Description: string # A description of the alias.
  --RoutingConfig: record # The <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html">traffic-shifting</a> configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: any}
  --RevisionId: string # Only update the alias if the revision ID matches the ID that's specified. Use this option to avoid modifying an alias that has changed since you last read it.
]: any -> record<AliasArn: record, Name: record, FunctionVersion: record, Description: record, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/aliases/($Name)")
  let body = {FunctionVersion: $FunctionVersion, Description: $Description, RoutingConfig: $RoutingConfig, RevisionId: $RevisionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the code signing configuration. You can delete the code signing configuration only if no function is using it. 
#
# DELETE /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: DeleteCodeSigningConfig
export def "2020-04-22-code-signing-configs DeleteCodeSigningConfig" [
  CodeSigningConfigArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-04-22/code-signing-configs/($CodeSigningConfigArn)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about the specified code signing configuration.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: GetCodeSigningConfig
export def "2020-04-22-code-signing-configs GetCodeSigningConfig" [
  CodeSigningConfigArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-04-22/code-signing-configs/($CodeSigningConfigArn)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the code signing configuration. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function. 
#
# PUT /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# operationId: UpdateCodeSigningConfig
# --AllowedPublishers shape: {SigningProfileVersionArns?: any}
# --CodeSigningPolicies shape: {UntrustedArtifactOnDeployment?: any}
export def "2020-04-22-code-signing-configs UpdateCodeSigningConfig" [
  CodeSigningConfigArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Description: string # Descriptive name for this code signing configuration.
  --AllowedPublishers: record # List of signing profiles that can sign a code package.  — shape: {SigningProfileVersionArns?: any}
  --CodeSigningPolicies: record # Code signing configuration <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies">policies</a> specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: any}
]: any -> record<CodeSigningConfig: record<CodeSigningConfigId: record, CodeSigningConfigArn: record, Description: record, AllowedPublishers: record<SigningProfileVersionArns: record>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: record>, LastModified: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-04-22/code-signing-configs/($CodeSigningConfigArn)")
  let body = {Description: $Description, AllowedPublishers: $AllowedPublishers, CodeSigningPolicies: $CodeSigningPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
#
# DELETE /2015-03-31/event-source-mappings/{UUID}
# operationId: DeleteEventSourceMapping
export def "2015-03-31-event-source-mappings DeleteEventSourceMapping" [
  UUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/event-source-mappings/($UUID)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
#
# GET /2015-03-31/event-source-mappings/{UUID}
# operationId: GetEventSourceMapping
export def "2015-03-31-event-source-mappings GetEventSourceMapping" [
  UUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/event-source-mappings/($UUID)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Updates an event source mapping. You can change the function that Lambda invokes, or pause invocation and resume later from the same location.</p> <p>For details about how to configure different event sources, see the following topics. </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping"> Amazon DynamoDB Streams</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping"> Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource"> Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping"> Amazon MQ and RabbitMQ</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html"> Amazon MSK</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html"> Apache Kafka</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html"> Amazon DocumentDB</a> </p> </li> </ul> <p>The following error handling options are available only for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> – If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> – Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires</p> </li> <li> <p> <code>MaximumRetryAttempts</code> – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.</p> </li> <li> <p> <code>ParallelizationFactor</code> – Process multiple batches from each shard concurrently.</p> </li> </ul> <p>For information about which configuration parameters apply to each event source, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params"> Amazon DynamoDB Streams</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params"> Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params"> Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params"> Amazon MQ and RabbitMQ</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms"> Amazon MSK</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms"> Apache Kafka</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration"> Amazon DocumentDB</a> </p> </li> </ul>
#
# PUT /2015-03-31/event-source-mappings/{UUID}
# operationId: UpdateEventSourceMapping
# --FilterCriteria shape: {Filters?: any}
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
# --SourceAccessConfigurations item shape: {Type?: any, URI?: any}
# --ScalingConfig shape: {MaximumConcurrency?: any}
# --DocumentDBEventSourceConfig shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
export def "2015-03-31-event-source-mappings UpdateEventSourceMapping" [
  UUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --FunctionName: string # <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> – <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> – <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> – <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  --Enabled: string@bool-completer # <p>When true, the event source mapping is active. When false, Lambda pauses polling and invocation.</p> <p>Default: True</p>
  --BatchSize: int # <p>The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB).</p> <ul> <li> <p> <b>Amazon Kinesis</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10.</p> </li> <li> <p> <b>Amazon Managed Streaming for Apache Kafka</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Self-managed Apache Kafka</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>Amazon MQ (ActiveMQ and RabbitMQ)</b> – Default 100. Max 10,000.</p> </li> <li> <p> <b>DocumentDB</b> – Default 100. Max 10,000.</p> </li> </ul>
  --FilterCriteria: record #  An object that contains the filters for an event source.  — shape: {Filters?: any}
  --MaximumBatchingWindowInSeconds: int # <p>The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure <code>MaximumBatchingWindowInSeconds</code> to any value from 0 seconds to 300 seconds in increments of seconds.</p> <p>For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change <code>MaximumBatchingWindowInSeconds</code> in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping.</p> <p>Related setting: For streams and Amazon SQS event sources, when you set <code>BatchSize</code> to a value greater than 10, you must set <code>MaximumBatchingWindowInSeconds</code> to at least 1.</p>
  --DestinationConfig: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
  --MaximumRecordAgeInSeconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --BisectBatchOnFunctionError: string@bool-completer # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --MaximumRetryAttempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --ParallelizationFactor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --SourceAccessConfigurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: any, URI?: any}
  --TumblingWindowInSeconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --FunctionResponseTypes: list # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --ScalingConfig: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: any}
  --DocumentDBEventSourceConfig: record #  Specific configuration settings for a DocumentDB event source.  — shape: {DatabaseName?: any, CollectionName?: any, FullDocument?: any}
]: any -> record<UUID: record, StartingPosition: record, StartingPositionTimestamp: record, BatchSize: record, MaximumBatchingWindowInSeconds: record, ParallelizationFactor: record, EventSourceArn: record, FilterCriteria: record<Filters: record>, FunctionArn: record, LastModified: record, LastProcessingResult: record, State: record, StateTransitionReason: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>, Topics: record, Queues: record, SourceAccessConfigurations: record, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: record, BisectBatchOnFunctionError: record, MaximumRetryAttempts: record, TumblingWindowInSeconds: record, FunctionResponseTypes: record, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: record>, ScalingConfig: record<MaximumConcurrency: record>, DocumentDBEventSourceConfig: record<DatabaseName: record, CollectionName: record, FullDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/event-source-mappings/($UUID)")
  let body = {FunctionName: $FunctionName, Enabled: $Enabled, BatchSize: $BatchSize, FilterCriteria: $FilterCriteria, MaximumBatchingWindowInSeconds: $MaximumBatchingWindowInSeconds, DestinationConfig: $DestinationConfig, MaximumRecordAgeInSeconds: $MaximumRecordAgeInSeconds, BisectBatchOnFunctionError: $BisectBatchOnFunctionError, MaximumRetryAttempts: $MaximumRetryAttempts, ParallelizationFactor: $ParallelizationFactor, SourceAccessConfigurations: $SourceAccessConfigurations, TumblingWindowInSeconds: $TumblingWindowInSeconds, FunctionResponseTypes: $FunctionResponseTypes, ScalingConfig: $ScalingConfig, DocumentDBEventSourceConfig: $DocumentDBEventSourceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For Amazon Web Services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
#
# DELETE /2015-03-31/functions/{FunctionName}
# operationId: DeleteFunction
export def "2015-03-31-functions DeleteFunction" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version to delete. You can't delete a version that an alias references.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
#
# GET /2015-03-31/functions/{FunctionName}
# operationId: GetFunction
export def "2015-03-31-functions GetFunction" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to get details about a published version of the function.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Configuration: record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record, Error: record>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record>>, Code: record<RepositoryType: record, Location: record, ImageUri: record, ResolvedImageUri: record>, Tags: record, Concurrency: record<ReservedConcurrentExecutions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes the code signing configuration from the function.
#
# DELETE /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: DeleteFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config DeleteFunctionCodeSigningConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-06-30/functions/($FunctionName)/code-signing-config")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the code signing configuration for the specified function.
#
# GET /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: GetFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config GetFunctionCodeSigningConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CodeSigningConfigArn: record, FunctionName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-06-30/functions/($FunctionName)/code-signing-config")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the code signing configuration for the function. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function. 
#
# PUT /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: PutFunctionCodeSigningConfig
export def "2020-06-30-functions-code-signing-config PutFunctionCodeSigningConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  CodeSigningConfigArn: string # The The Amazon Resource Name (ARN) of the code signing configuration.
]: any -> record<CodeSigningConfigArn: record, FunctionName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2020-06-30/functions/($FunctionName)/code-signing-config")
  let body = {CodeSigningConfigArn: $CodeSigningConfigArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a concurrent execution limit from a function.
#
# DELETE /2017-10-31/functions/{FunctionName}/concurrency
# operationId: DeleteFunctionConcurrency
export def "2017-10-31-functions-concurrency DeleteFunctionConcurrency" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2017-10-31/functions/($FunctionName)/concurrency")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-scaling.html">Lambda function scaling</a>.</p>
#
# PUT /2017-10-31/functions/{FunctionName}/concurrency
# operationId: PutFunctionConcurrency
export def "2017-10-31-functions-concurrency PutFunctionConcurrency" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ReservedConcurrentExecutions: int # The number of simultaneous executions to reserve for the function.
]: any -> record<ReservedConcurrentExecutions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2017-10-31/functions/($FunctionName)/concurrency")
  let body = {ReservedConcurrentExecutions: $ReservedConcurrentExecutions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
#
# DELETE /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: DeleteFunctionEventInvokeConfig
export def "2019-09-25-functions-event-invoke-config DeleteFunctionEventInvokeConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # A version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-25/functions/($FunctionName)/event-invoke-config" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: GetFunctionEventInvokeConfig
export def "2019-09-25-functions-event-invoke-config GetFunctionEventInvokeConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # A version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-25/functions/($FunctionName)/event-invoke-config" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>UpdateFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
#
# PUT /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: PutFunctionEventInvokeConfig
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
export def "2019-09-25-functions-event-invoke-config PutFunctionEventInvokeConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # A version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --MaximumRetryAttempts: int # The maximum number of times to retry when the function returns an error.
  --MaximumEventAgeInSeconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --DestinationConfig: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
]: any -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-25/functions/($FunctionName)/event-invoke-config" $qp)
  let body = {MaximumRetryAttempts: $MaximumRetryAttempts, MaximumEventAgeInSeconds: $MaximumEventAgeInSeconds, DestinationConfig: $DestinationConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
#
# POST /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: UpdateFunctionEventInvokeConfig
# --DestinationConfig shape: {OnSuccess?: any, OnFailure?: any}
export def "2019-09-25-functions-event-invoke-config UpdateFunctionEventInvokeConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # A version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --MaximumRetryAttempts: int # The maximum number of times to retry when the function returns an error.
  --MaximumEventAgeInSeconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --DestinationConfig: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: any, OnFailure?: any}
]: any -> record<LastModified: record, FunctionArn: record, MaximumRetryAttempts: record, MaximumEventAgeInSeconds: record, DestinationConfig: record<OnSuccess: record<Destination: record>, OnFailure: record<Destination: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-25/functions/($FunctionName)/event-invoke-config" $qp)
  let body = {MaximumRetryAttempts: $MaximumRetryAttempts, MaximumEventAgeInSeconds: $MaximumEventAgeInSeconds, DestinationConfig: $DestinationConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# operationId: DeleteLayerVersion
export def "2018-10-31-layers-versions DeleteLayerVersion" [
  LayerName: string
  VersionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions/($VersionNumber)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# operationId: GetLayerVersion
export def "2018-10-31-layers-versions GetLayerVersion" [
  LayerName: string
  VersionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions/($VersionNumber)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the provisioned concurrency configuration for a function.
#
# DELETE /2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier
# operationId: DeleteProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency-qualifier DeleteProvisionedConcurrencyConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-30/functions/($FunctionName)/provisioned-concurrency#Qualifier" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the provisioned concurrency configuration for a function's alias or version.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier
# operationId: GetProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency-qualifier GetProvisionedConcurrencyConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<RequestedProvisionedConcurrentExecutions: record, AvailableProvisionedConcurrentExecutions: record, AllocatedProvisionedConcurrentExecutions: record, Status: record, StatusReason: record, LastModified: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-30/functions/($FunctionName)/provisioned-concurrency#Qualifier" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a provisioned concurrency configuration to a function's alias or version.
#
# PUT /2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier
# operationId: PutProvisionedConcurrencyConfig
export def "2019-09-30-functions-provisioned-concurrency-qualifier PutProvisionedConcurrencyConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The version number or alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ProvisionedConcurrentExecutions: int # The amount of provisioned concurrency to allocate for the version or alias.
]: any -> record<RequestedProvisionedConcurrentExecutions: record, AvailableProvisionedConcurrentExecutions: record, AllocatedProvisionedConcurrentExecutions: record, Status: record, StatusReason: record, LastModified: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-30/functions/($FunctionName)/provisioned-concurrency#Qualifier" $qp)
  let body = {ProvisionedConcurrentExecutions: $ProvisionedConcurrentExecutions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an Amazon Web Services Region.
#
# GET /2016-08-19/account-settings/
# operationId: GetAccountSettings
export def "2016-08-19-account-settings GetAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<AccountLimit: record<TotalCodeSize: record, CodeSizeUnzipped: record, CodeSizeZipped: record, ConcurrentExecutions: record, UnreservedConcurrentExecutions: record>, AccountUsage: record<TotalCodeSize: record, FunctionCount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2016-08-19/account-settings/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
#
# GET /2019-09-30/functions/{FunctionName}/concurrency
# operationId: GetFunctionConcurrency
export def "2019-09-30-functions-concurrency GetFunctionConcurrency" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ReservedConcurrentExecutions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2019-09-30/functions/($FunctionName)/concurrency")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
#
# GET /2015-03-31/functions/{FunctionName}/configuration
# operationId: GetFunctionConfiguration
export def "2015-03-31-functions-configuration GetFunctionConfiguration" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to get details about a published version of the function.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/configuration" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Lambda function states</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an Amazon Web Services account or Amazon Web Service, use <a>AddPermission</a>.</p>
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
export def "2015-03-31-functions-configuration UpdateFunctionConfiguration" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --Handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html">Lambda programming model</a>.
  --Description: string # A description of the function.
  --Timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html">Lambda execution environment</a>.
  --MemorySize: int # The amount of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console">memory available to the function</a> at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --VpcConfig: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html">Configuring a Lambda function to access resources in a VPC</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --Environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: any}
  --Runtime: string@Runtime-completer # <p>The identifier of the function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime</a>. Runtime is required if the deployment package is a .zip file archive.</p> <p>The following list includes deprecated runtimes. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy">Runtime deprecation policy</a>.</p>
  --DeadLetterConfig: record # The <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a> for failed asynchronous invocations. — shape: {TargetArn?: any}
  --KMSKeyArn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption">environment variables</a>. When <a href="https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html">Lambda SnapStart</a> is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --TracingConfig: record # The function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html">X-Ray</a> tracing configuration. To sample and record incoming requests, set <code>Mode</code> to <code>Active</code>. — shape: {Mode?: any}
  --RevisionId: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --Layers: list # A list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">function layers</a> to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --FileSystemConfigs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: any, LocalMountPath: any}
  --ImageConfig: record # Configuration values that override the container image Dockerfile settings. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms">Container image settings</a>. — shape: {EntryPoint?: any, Command?: any, WorkingDirectory?: any}
  --EphemeralStorage: record # The size of the function's <code>/tmp</code> directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: any}
  --SnapStart: record # <p>The function's Lambda SnapStart setting. Set <code>ApplyOn</code> to <code>PublishedVersions</code> to create a snapshot of the initialized execution environment when you publish a function version.</p> <p>SnapStart is supported with the <code>java11</code> runtime. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html">Improving startup performance with Lambda SnapStart</a>.</p> — shape: {ApplyOn?: any}
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/configuration")
  let body = {Role: $Role, Handler: $Handler, Description: $Description, Timeout: $Timeout, MemorySize: $MemorySize, VpcConfig: $VpcConfig, Environment: $Environment, Runtime: $Runtime, DeadLetterConfig: $DeadLetterConfig, KMSKeyArn: $KMSKeyArn, TracingConfig: $TracingConfig, RevisionId: $RevisionId, Layers: $Layers, FileSystemConfigs: $FileSystemConfigs, ImageConfig: $ImageConfig, EphemeralStorage: $EphemeralStorage, SnapStart: $SnapStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers#find=LayerVersion&Arn
# operationId: GetLayerVersionByArn
export def "2018-10-31-layersfind-layer-version-arn GetLayerVersionByArn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Arn: string # The ARN of the layer version.
  --find: string@find-completer
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Arn" $Arn "scalar") (serialize-qp "find" $find "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2018-10-31/layers#find=LayerVersion&Arn" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the runtime management configuration for a function's version. If the runtime update mode is <b>Manual</b>, this includes the ARN of the runtime version and the runtime update mode. If the runtime update mode is <b>Auto</b> or <b>Function update</b>, this includes the runtime update mode and <code>null</code> is returned for the ARN. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html">Runtime updates</a>.
#
# GET /2021-07-20/functions/{FunctionName}/runtime-management-config
# operationId: GetRuntimeManagementConfig
export def "2021-07-20-functions-runtime-management-config GetRuntimeManagementConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version of the function. This can be <code>$LATEST</code> or a published version number. If no value is specified, the configuration for the <code>$LATEST</code> version is returned.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UpdateRuntimeOn: record, RuntimeVersionArn: record, FunctionArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-07-20/functions/($FunctionName)/runtime-management-config" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the runtime management configuration for a function's version. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html">Runtime updates</a>.
#
# PUT /2021-07-20/functions/{FunctionName}/runtime-management-config
# operationId: PutRuntimeManagementConfig
export def "2021-07-20-functions-runtime-management-config PutRuntimeManagementConfig" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version of the function. This can be <code>$LATEST</code> or a published version number. If no value is specified, the configuration for the <code>$LATEST</code> version is returned.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  UpdateRuntimeOn: string@UpdateRuntimeOn-completer # <p>Specify the runtime update mode.</p> <ul> <li> <p> <b>Auto (default)</b> - Automatically update to the most recent and secure runtime version using a <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-two-phase">Two-phase runtime version rollout</a>. This is the best choice for most customers to ensure they always benefit from runtime updates.</p> </li> <li> <p> <b>Function update</b> - Lambda updates the runtime of your function to the most recent and secure runtime version when you update your function. This approach synchronizes runtime updates with function deployments, giving you control over when runtime updates are applied and allowing you to detect and mitigate rare runtime update incompatibilities early. When using this setting, you need to regularly update your functions to keep their runtime up-to-date.</p> </li> <li> <p> <b>Manual</b> - You specify a runtime version in your function configuration. The function will use this runtime version indefinitely. In the rare case where a new runtime version is incompatible with an existing function, this allows you to roll back your function to an earlier runtime version. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-rollback">Roll back a runtime version</a>.</p> </li> </ul>
  --RuntimeVersionArn: string # <p>The ARN of the runtime version you want the function to use.</p> <note> <p>This is only required if you're using the <b>Manual</b> runtime update mode.</p> </note>
]: any -> record<UpdateRuntimeOn: record, FunctionArn: record, RuntimeVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-07-20/functions/($FunctionName)/runtime-management-config" $qp)
  let body = {UpdateRuntimeOn: $UpdateRuntimeOn, RuntimeVersionArn: $RuntimeVersionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-retries.html">Error handling and automatic retries in Lambda</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html">quota</a> errors, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if running the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might disconnect during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html">lambda:InvokeFunction</a> action. For details on how to set up permissions for cross-account invocations, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke">Granting function access to other accounts</a>.</p>
#
# POST /2015-03-31/functions/{FunctionName}/invocations
# operationId: Invoke
export def "2015-03-31-functions-invocations Invoke" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to invoke a published version of the function.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Invocation-Type: string@X-Amz-Invocation-Type-completer # <p>Choose from the following options.</p> <ul> <li> <p> <code>RequestResponse</code> (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data.</p> </li> <li> <p> <code>Event</code> – Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if one is configured). The API response only includes a status code.</p> </li> <li> <p> <code>DryRun</code> – Validate parameter values and verify that the user or role has permission to invoke the function.</p> </li> </ul>
  --X-Amz-Log-Type: string@X-Amz-Log-Type-completer # Set to <code>Tail</code> to include the execution log in the response. Applies to synchronously invoked functions only.
  --X-Amz-Client-Context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --Payload: string # <p>The JSON that you want to provide to your Lambda function as input.</p> <p>You can enter the JSON directly. For example, <code>--payload '{ "key": "value" }'</code>. You can also specify a file path. For example, <code>--payload file://payload.json</code>.</p> (format: password)
]: any -> record<StatusCode: record, Payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/invocations" $qp)
  let body = {Payload: $Payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Invocation-Type": $X_Amz_Invocation_Type, "X-Amz-Log-Type": $X_Amz_Log_Type, "X-Amz-Client-Context": $X_Amz_Client_Context} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
#
# POST /2014-11-13/functions/{FunctionName}/invoke-async/
# DEPRECATED
# operationId: InvokeAsync
@deprecated
export def "2014-11-13-functions-invoke-async InvokeAsync" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  InvokeArgs: string # The JSON that you want to provide to your Lambda function as input.
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2014-11-13/functions/($FunctionName)/invoke-async/")
  let body = {InvokeArgs: $InvokeArgs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Configure your Lambda functions to stream response payloads back to clients. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html">Configuring a Lambda function to stream responses</a>.</p> <p>This operation requires permission for the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html">lambda:InvokeFunction</a> action. For details on how to set up permissions for cross-account invocations, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke">Granting function access to other accounts</a>.</p>
#
# POST /2021-11-15/functions/{FunctionName}/response-streaming-invocations
# operationId: InvokeWithResponseStream
export def "2021-11-15-functions-response-streaming-invocations InvokeWithResponseStream" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Invocation-Type: string@X-Amz-Invocation-Type-completer-1 # <p>Use one of the following options:</p> <ul> <li> <p> <code>RequestResponse</code> (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API operation response includes the function response and additional data.</p> </li> <li> <p> <code>DryRun</code> – Validate parameter values and verify that the IAM user or role has permission to invoke the function.</p> </li> </ul>
  --X-Amz-Log-Type: string@X-Amz-Log-Type-completer # Set to <code>Tail</code> to include the execution log in the response. Applies to synchronously invoked functions only.
  --X-Amz-Client-Context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --Payload: string # <p>The JSON that you want to provide to your Lambda function as input.</p> <p>You can enter the JSON directly. For example, <code>--payload '{ "key": "value" }'</code>. You can also specify a file path. For example, <code>--payload file://payload.json</code>.</p> (format: password)
]: any -> record<StatusCode: record, EventStream: record<PayloadChunk: record<Payload: record>, InvokeComplete: record<ErrorCode: record, ErrorDetails: record, LogResult: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-11-15/functions/($FunctionName)/response-streaming-invocations" $qp)
  let body = {Payload: $Payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Invocation-Type": $X_Amz_Invocation_Type, "X-Amz-Log-Type": $X_Amz_Log_Type, "X-Amz-Client-Context": $X_Amz_Client_Context} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config/list
# operationId: ListFunctionEventInvokeConfigs
export def "2019-09-25-functions-event-invoke-config-list ListFunctionEventInvokeConfigs" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # The maximum number of configurations to return.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<FunctionEventInvokeConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-25/functions/($FunctionName)/event-invoke-config/list" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of Lambda function URLs for the specified function.
#
# GET /2021-10-31/functions/{FunctionName}/urls
# operationId: ListFunctionUrlConfigs
export def "2021-10-31-functions-urls ListFunctionUrlConfigs" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # The maximum number of function URLs to return in the response. Note that <code>ListFunctionUrlConfigs</code> returns a maximum of 50 items in each response, even if you set the number higher.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<FunctionUrlConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2021-10-31/functions/($FunctionName)/urls" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version.</p> <note> <p>The <code>ListFunctions</code> operation returns a subset of the <a>FunctionConfiguration</a> fields. To get the additional fields (State, StateReasonCode, StateReason, LastUpdateStatus, LastUpdateStatusReason, LastUpdateStatusReasonCode, RuntimeVersionConfig) for a function or version, use <a>GetFunction</a>.</p> </note>
#
# GET /2015-03-31/functions/
# operationId: ListFunctions
export def "2015-03-31-functions ListFunctions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MasterRegion: string # For Lambda@Edge functions, the Amazon Web Services Region of the master function. For example, <code>us-east-1</code> filters the list of functions to include only Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  --FunctionVersion: string@FunctionVersion-completer # Set to <code>ALL</code> to include entries for all published versions of each function.
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # The maximum number of functions to return in the response. Note that <code>ListFunctions</code> returns a maximum of 50 items in each response, even if you set the number higher.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, Functions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MasterRegion" $MasterRegion "scalar") (serialize-qp "FunctionVersion" $FunctionVersion "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-03-31/functions/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the functions that use the specified code signing configuration. You can use this method prior to deleting a code signing configuration, to verify that no functions are using it.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}/functions
# operationId: ListFunctionsByCodeSigningConfig
export def "2020-04-22-code-signing-configs-functions ListFunctionsByCodeSigningConfig" [
  CodeSigningConfigArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # Maximum number of items to return.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, FunctionArns: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2020-04-22/code-signing-configs/($CodeSigningConfigArn)/functions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layer versions that are compatible with that architecture.
#
# GET /2018-10-31/layers/{LayerName}/versions
# operationId: ListLayerVersions
export def "2018-10-31-layers-versions ListLayerVersions" [
  LayerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CompatibleRuntime: string@CompatibleRuntime-completer # A runtime identifier. For example, <code>go1.x</code>.
  --Marker: string # A pagination token returned by a previous call.
  --MaxItems: int # The maximum number of versions to return.
  --CompatibleArchitecture: string@CompatibleArchitecture-completer # The compatible <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html">instruction set architecture</a>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, LayerVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CompatibleRuntime" $CompatibleRuntime "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "CompatibleArchitecture" $CompatibleArchitecture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
#
# POST /2018-10-31/layers/{LayerName}/versions
# operationId: PublishLayerVersion
# --Content shape: {S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ZipFile?: any}
export def "2018-10-31-layers-versions PublishLayerVersion" [
  LayerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Description: string # The description of the version.
  Content: record # A ZIP archive that contains the contents of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. You can specify either an Amazon S3 location, or upload a layer archive directly. — shape: {S3Bucket?: any, S3Key?: any, S3ObjectVersion?: any, ZipFile?: any}
  --CompatibleRuntimes: list # A list of compatible <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">function runtimes</a>. Used for filtering with <a>ListLayers</a> and <a>ListLayerVersions</a>.
  --LicenseInfo: string # <p>The layer's software license. It can be any of the following:</p> <ul> <li> <p>An <a href="https://spdx.org/licenses/">SPDX license identifier</a>. For example, <code>MIT</code>.</p> </li> <li> <p>The URL of a license hosted on the internet. For example, <code>https://opensource.org/licenses/MIT</code>.</p> </li> <li> <p>The full text of the license.</p> </li> </ul>
  --CompatibleArchitectures: list # A list of compatible <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html">instruction set architectures</a>.
]: any -> record<Content: record<Location: record, CodeSha256: record, CodeSize: record, SigningProfileVersionArn: record, SigningJobArn: record>, LayerArn: record, LayerVersionArn: record, Description: record, CreatedDate: record, Version: record, CompatibleRuntimes: record, LicenseInfo: record, CompatibleArchitectures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions")
  let body = {Description: $Description, Content: $Content, CompatibleRuntimes: $CompatibleRuntimes, LicenseInfo: $LicenseInfo, CompatibleArchitectures: $CompatibleArchitectures} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-layers.html">Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layers that are compatible with that <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html">instruction set architecture</a>.
#
# GET /2018-10-31/layers
# operationId: ListLayers
export def "2018-10-31-layers ListLayers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CompatibleRuntime: string@CompatibleRuntime-completer # A runtime identifier. For example, <code>go1.x</code>.
  --Marker: string # A pagination token returned by a previous call.
  --MaxItems: int # The maximum number of layers to return.
  --CompatibleArchitecture: string@CompatibleArchitecture-completer # The compatible <a href="https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html">instruction set architecture</a>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, Layers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CompatibleRuntime" $CompatibleRuntime "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "CompatibleArchitecture" $CompatibleArchitecture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2018-10-31/layers" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of provisioned concurrency configurations for a function.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL
# operationId: ListProvisionedConcurrencyConfigs
export def "2019-09-30-functions-provisioned-concurrency-list-all ListProvisionedConcurrencyConfigs" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # Specify a number to limit the number of configurations returned.
  --List: string@List-completer
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ProvisionedConcurrencyConfigs: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "List" $List "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2019-09-30/functions/($FunctionName)/provisioned-concurrency#List=ALL" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
#
# GET /2017-03-31/tags/{ARN}
# operationId: ListTags
export def "2017-03-31-tags ListTags" [
  ARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2017-03-31/tags/($ARN)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
#
# POST /2017-03-31/tags/{ARN}
# operationId: TagResource
export def "2017-03-31-tags TagResource" [
  ARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Tags: record # A list of tags to apply to the function.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2017-03-31/tags/($ARN)")
  let body = {Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
#
# GET /2015-03-31/functions/{FunctionName}/versions
# operationId: ListVersionsByFunction
export def "2015-03-31-functions-versions ListVersionsByFunction" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --MaxItems: int # The maximum number of versions to return. Note that <code>ListVersionsByFunction</code> returns a maximum of 50 items in each response, even if you set the number higher.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextMarker: record, Versions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Marker" $Marker "scalar") (serialize-qp "MaxItems" $MaxItems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
#
# POST /2015-03-31/functions/{FunctionName}/versions
# operationId: PublishVersion
export def "2015-03-31-functions-versions PublishVersion" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --CodeSha256: string # Only publish a version if the hash value matches the value that's specified. Use this option to avoid publishing a version if the function code has changed since you last updated it. You can get the hash for the version that you uploaded from the output of <a>UpdateFunctionCode</a>.
  --Description: string # A description for the version to override the description in the function configuration.
  --RevisionId: string # Only update the function if the revision ID matches the ID that's specified. Use this option to avoid publishing a version if the function configuration has changed since you last updated it.
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/versions")
  let body = {CodeSha256: $CodeSha256, Description: $Description, RevisionId: $RevisionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}
# operationId: RemoveLayerVersionPermission
export def "2018-10-31-layers-versions-policy RemoveLayerVersionPermission" [
  LayerName: string
  VersionNumber: int
  StatementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RevisionId: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RevisionId" $RevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2018-10-31/layers/($LayerName)/versions/($VersionNumber)/policy/($StatementId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes function-use permission from an Amazon Web Service or another Amazon Web Services account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
#
# DELETE /2015-03-31/functions/{FunctionName}/policy/{StatementId}
# operationId: RemovePermission
export def "2015-03-31-functions-policy RemovePermission" [
  FunctionName: string
  StatementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Qualifier: string # Specify a version or alias to remove permissions from a published version of the function.
  --RevisionId: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Qualifier" $Qualifier "scalar") (serialize-qp "RevisionId" $RevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/policy/($StatementId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
#
# DELETE /2017-03-31/tags/{ARN}#tagKeys
# operationId: UntagResource
export def "2017-03-31-tags UntagResource" [
  ARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagKeys: list # A list of tag keys to remove from the function.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/2017-03-31/tags/($ARN)#tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Updates a Lambda function's code. If code signing is enabled for the function, the code package must be signed by a trusted publisher. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html">Configuring code signing for Lambda</a>.</p> <p>If the function's package type is <code>Image</code>, then you must specify the code package in <code>ImageUri</code> as the URI of a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html">container image</a> in the Amazon ECR registry.</p> <p>If the function's package type is <code>Zip</code>, then you must specify the deployment package as a <a href="https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip">.zip file archive</a>. Enter the Amazon S3 bucket and key of the code .zip file location. You can also provide the function code inline using the <code>ZipFile</code> field.</p> <p>The code in the deployment package must be compatible with the target instruction set architecture of the function (<code>x86-64</code> or <code>arm64</code>).</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p> <note> <p>For a function defined as a container image, Lambda resolves the image tag to an image digest. In Amazon ECR, if you update the image tag to a new image, Lambda does not automatically update the function.</p> </note>
#
# PUT /2015-03-31/functions/{FunctionName}/code
# operationId: UpdateFunctionCode
export def "2015-03-31-functions-code UpdateFunctionCode" [
  FunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --ZipFile: string # The base64-encoded contents of the deployment package. Amazon Web Services SDK and CLI clients handle the encoding for you. Use only with a function defined with a .zip file archive deployment package. (format: password)
  --S3Bucket: string # An Amazon S3 bucket in the same Amazon Web Services Region as your function. The bucket can be in a different Amazon Web Services account. Use only with a function defined with a .zip file archive deployment package.
  --S3Key: string # The Amazon S3 key of the deployment package. Use only with a function defined with a .zip file archive deployment package.
  --S3ObjectVersion: string # For versioned objects, the version of the deployment package object to use.
  --ImageUri: string # URI of a container image in the Amazon ECR registry. Do not use for a function defined with a .zip file archive.
  --Publish: string@bool-completer # Set to true to publish a new version of the function after updating the code. This has the same effect as calling <a>PublishVersion</a> separately.
  --DryRun: string@bool-completer # Set to true to validate the request parameters and access permissions without modifying the function code.
  --RevisionId: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --Architectures: list # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is <code>x86_64</code>.
]: any -> record<FunctionName: record, FunctionArn: record, Runtime: record, Role: record, Handler: record, CodeSize: record, Description: record, Timeout: record, MemorySize: record, LastModified: record, CodeSha256: record, Version: record, VpcConfig: record<SubnetIds: record, SecurityGroupIds: record, VpcId: record>, DeadLetterConfig: record<TargetArn: record>, Environment: record<Variables: record, Error: record<ErrorCode: record, Message: record>>, KMSKeyArn: record, TracingConfig: record<Mode: record>, MasterArn: record, RevisionId: record, Layers: record, State: record, StateReason: record, StateReasonCode: record, LastUpdateStatus: record, LastUpdateStatusReason: record, LastUpdateStatusReasonCode: record, FileSystemConfigs: record, PackageType: record, ImageConfigResponse: record<ImageConfig: record<EntryPoint: record, Command: record, WorkingDirectory: record>, Error: record<ErrorCode: record, Message: record>>, SigningProfileVersionArn: record, SigningJobArn: record, Architectures: record, EphemeralStorage: record<Size: record>, SnapStart: record<ApplyOn: record, OptimizationStatus: record>, RuntimeVersionConfig: record<RuntimeVersionArn: record, Error: record<ErrorCode: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-03-31/functions/($FunctionName)/code")
  let body = {ZipFile: $ZipFile, S3Bucket: $S3Bucket, S3Key: $S3Key, S3ObjectVersion: $S3ObjectVersion, ImageUri: $ImageUri, Publish: $Publish, DryRun: $DryRun, RevisionId: $RevisionId, Architectures: $Architectures} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
