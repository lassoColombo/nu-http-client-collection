# Auto-generated client for AWSServerlessApplicationRepository v2017-09-08
# Source: https://api.apis.guru/v2/specs/amazonaws.com/serverlessrepo/2017-09-08/openapi.json
# Auth: --token flag or $env.AWSSERVERLESSAPPLICATIONREPOSITORY_TOKEN

const BASE_URL = "http://serverlessrepo.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWSSERVERLESSAPPLICATIONREPOSITORY_TOKEN | default "" }
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
def base-url-completer [] { ["http://serverlessrepo.us-east-1.amazonaws.com" "http://serverlessrepo.us-east-2.amazonaws.com" "http://serverlessrepo.us-west-1.amazonaws.com" "http://serverlessrepo.us-west-2.amazonaws.com" "http://serverlessrepo.us-gov-west-1.amazonaws.com" "http://serverlessrepo.us-gov-east-1.amazonaws.com" "http://serverlessrepo.ca-central-1.amazonaws.com" "http://serverlessrepo.eu-north-1.amazonaws.com" "http://serverlessrepo.eu-west-1.amazonaws.com" "http://serverlessrepo.eu-west-2.amazonaws.com" "http://serverlessrepo.eu-west-3.amazonaws.com" "http://serverlessrepo.eu-central-1.amazonaws.com" "http://serverlessrepo.eu-south-1.amazonaws.com" "http://serverlessrepo.af-south-1.amazonaws.com" "http://serverlessrepo.ap-northeast-1.amazonaws.com" "http://serverlessrepo.ap-northeast-2.amazonaws.com" "http://serverlessrepo.ap-northeast-3.amazonaws.com" "http://serverlessrepo.ap-southeast-1.amazonaws.com" "http://serverlessrepo.ap-southeast-2.amazonaws.com" "http://serverlessrepo.ap-east-1.amazonaws.com" "http://serverlessrepo.ap-south-1.amazonaws.com" "http://serverlessrepo.sa-east-1.amazonaws.com" "http://serverlessrepo.me-south-1.amazonaws.com" "https://serverlessrepo.us-east-1.amazonaws.com" "https://serverlessrepo.us-east-2.amazonaws.com" "https://serverlessrepo.us-west-1.amazonaws.com" "https://serverlessrepo.us-west-2.amazonaws.com" "https://serverlessrepo.us-gov-west-1.amazonaws.com" "https://serverlessrepo.us-gov-east-1.amazonaws.com" "https://serverlessrepo.ca-central-1.amazonaws.com" "https://serverlessrepo.eu-north-1.amazonaws.com" "https://serverlessrepo.eu-west-1.amazonaws.com" "https://serverlessrepo.eu-west-2.amazonaws.com" "https://serverlessrepo.eu-west-3.amazonaws.com" "https://serverlessrepo.eu-central-1.amazonaws.com" "https://serverlessrepo.eu-south-1.amazonaws.com" "https://serverlessrepo.af-south-1.amazonaws.com" "https://serverlessrepo.ap-northeast-1.amazonaws.com" "https://serverlessrepo.ap-northeast-2.amazonaws.com" "https://serverlessrepo.ap-northeast-3.amazonaws.com" "https://serverlessrepo.ap-southeast-1.amazonaws.com" "https://serverlessrepo.ap-southeast-2.amazonaws.com" "https://serverlessrepo.ap-east-1.amazonaws.com" "https://serverlessrepo.ap-south-1.amazonaws.com" "https://serverlessrepo.sa-east-1.amazonaws.com" "https://serverlessrepo.me-south-1.amazonaws.com" "http://serverlessrepo.cn-north-1.amazonaws.com.cn" "http://serverlessrepo.cn-northwest-1.amazonaws.com.cn" "https://serverlessrepo.cn-north-1.amazonaws.com.cn" "https://serverlessrepo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications CreateApplication" } } | get name | first)
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

# Creates an application, optionally including an AWS SAM file to create the first application version in the same call.
#
# POST /applications
# operationId: CreateApplication
export def "applications CreateApplication" [
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
  author: string # <p>The name of the author publishing the app.</p><p>Minimum length=1. Maximum length=127.</p><p>Pattern "^[a-z0-9](([a-z0-9]|-(?!-))*[a-z0-9])?$";</p>
  description: string # <p>The description of the application.</p><p>Minimum length=1. Maximum length=256</p>
  --homePageUrl: string # A URL with more information about the application, for example the location of your GitHub repository for the application.
  --labels: list # <p>Labels to improve discovery of apps in search results.</p><p>Minimum length=1. Maximum length=127. Maximum number of labels: 10</p><p>Pattern: "^[a-zA-Z0-9+\\-_:\\/@]+$";</p>
  --licenseBody: string # <p>A local text file that contains the license of the app that matches the spdxLicenseID value of your application.  The file has the format file://&lt;path>/&lt;filename>.</p><p>Maximum size 5 MB</p><p>You can specify only one of licenseBody and licenseUrl; otherwise, an error results.</p>
  --licenseUrl: string # <p>A link to the S3 object that contains the license of the app that matches the spdxLicenseID value of your application.</p><p>Maximum size 5 MB</p><p>You can specify only one of licenseBody and licenseUrl; otherwise, an error results.</p>
  name: string # <p>The name of the application that you want to publish.</p><p>Minimum length=1. Maximum length=140</p><p>Pattern: "[a-zA-Z0-9\\-]+";</p>
  --readmeBody: string # <p>A local text readme file in Markdown language that contains a more detailed description of the application and how it works.  The file has the format file://&lt;path>/&lt;filename>.</p><p>Maximum size 5 MB</p><p>You can specify only one of readmeBody and readmeUrl; otherwise, an error results.</p>
  --readmeUrl: string # <p>A link to the S3 object in Markdown language that contains a more detailed description of the application and how it works.</p><p>Maximum size 5 MB</p><p>You can specify only one of readmeBody and readmeUrl; otherwise, an error results.</p>
  --semanticVersion: string # <p>The semantic version of the application:</p><p>  <a href="https://semver.org/">https://semver.org/</a>  </p>
  --sourceCodeArchiveUrl: string # <p>A link to the S3 object that contains the ZIP archive of the source code for this version of your application.</p><p>Maximum size 50 MB</p>
  --sourceCodeUrl: string # A link to a public repository for the source code of your application, for example the URL of a specific GitHub commit.
  --spdxLicenseId: string # A valid identifier from <a href="https://spdx.org/licenses/">https://spdx.org/licenses/</a>.
  --templateBody: string # <p>The local raw packaged AWS SAM template file of your application.  The file has the format file://&lt;path>/&lt;filename>.</p><p>You can specify only one of templateBody and templateUrl; otherwise an error results.</p>
  --templateUrl: string # <p>A link to the S3 object containing the packaged AWS SAM template of your application.</p><p>You can specify only one of templateBody and templateUrl; otherwise an error results.</p>
]: any -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applications")
  let body = {author: $author, description: $description, homePageUrl: $homePageUrl, labels: $labels, licenseBody: $licenseBody, licenseUrl: $licenseUrl, name: $name, readmeBody: $readmeBody, readmeUrl: $readmeUrl, semanticVersion: $semanticVersion, sourceCodeArchiveUrl: $sourceCodeArchiveUrl, sourceCodeUrl: $sourceCodeUrl, spdxLicenseId: $spdxLicenseId, templateBody: $templateBody, templateUrl: $templateUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists applications owned by the requester.
#
# GET /applications
# operationId: ListApplications
export def "applications ListApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxItems: int # The total number of items to return.
  --nextToken: string # A token to specify where to start paginating.
  --MaxItems: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Applications: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an application version.
#
# PUT /applications/{applicationId}/versions/{semanticVersion}
# operationId: CreateApplicationVersion
export def "applications-versions CreateApplicationVersion" [
  applicationId: string
  semanticVersion: string
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
  --sourceCodeArchiveUrl: string # <p>A link to the S3 object that contains the ZIP archive of the source code for this version of your application.</p><p>Maximum size 50 MB</p>
  --sourceCodeUrl: string # A link to a public repository for the source code of your application, for example the URL of a specific GitHub commit.
  --templateBody: string # The raw packaged AWS SAM template of your application.
  --templateUrl: string # A link to the packaged AWS SAM template of your application.
]: any -> record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/versions/($semanticVersion)")
  let body = {sourceCodeArchiveUrl: $sourceCodeArchiveUrl, sourceCodeUrl: $sourceCodeUrl, templateBody: $templateBody, templateUrl: $templateUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an AWS CloudFormation change set for the given application.
#
# POST /applications/{applicationId}/changesets
# operationId: CreateCloudFormationChangeSet
# --parameterOverrides item shape: {Name: any, Value: any}
# --rollbackConfiguration shape: {MonitoringTimeInMinutes?: any, RollbackTriggers?: any}
# --tags item shape: {Key: any, Value: any}
export def "applications-changesets CreateCloudFormationChangeSet" [
  applicationId: string
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
  --capabilities: list # <p>A list of values that you must specify before you can deploy certain applications.  Some applications might include resources that can affect permissions in your AWS  account, for example, by creating new AWS Identity and Access Management (IAM) users.  For those applications, you must explicitly acknowledge their capabilities by  specifying this parameter.</p><p>The only valid values are CAPABILITY_IAM, CAPABILITY_NAMED_IAM,  CAPABILITY_RESOURCE_POLICY, and CAPABILITY_AUTO_EXPAND.</p><p>The following resources require you to specify CAPABILITY_IAM or  CAPABILITY_NAMED_IAM:  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-iam-group.html">AWS::IAM::Group</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-instanceprofile.html">AWS::IAM::InstanceProfile</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html">AWS::IAM::Policy</a>, and  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html">AWS::IAM::Role</a>.  If the application contains IAM resources, you can specify either CAPABILITY_IAM  or CAPABILITY_NAMED_IAM. If the application contains IAM resources  with custom names, you must specify CAPABILITY_NAMED_IAM.</p><p>The following resources require you to specify CAPABILITY_RESOURCE_POLICY:  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-permission.html">AWS::Lambda::Permission</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html">AWS::IAM:Policy</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-applicationautoscaling-scalingpolicy.html">AWS::ApplicationAutoScaling::ScalingPolicy</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-policy.html">AWS::S3::BucketPolicy</a>,  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-policy.html">AWS::SQS::QueuePolicy</a>, and  <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-policy.html">AWS::SNS:TopicPolicy</a>.</p><p>Applications that contain one or more nested applications require you to specify  CAPABILITY_AUTO_EXPAND.</p><p>If your application template contains any of the above resources, we recommend that you review  all permissions associated with the application before deploying. If you don't specify  this parameter for an application that requires capabilities, the call will fail.</p>
  --changeSetName: string # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --clientToken: string # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --description: string # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --notificationArns: list # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --parameterOverrides: list # A list of parameter values for the parameters of the application. — item shape: {Name: any, Value: any}
  --resourceTypes: list # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --rollbackConfiguration: record # This property corresponds to the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/RollbackConfiguration">RollbackConfiguration</a>  </i> Data Type. — shape: {MonitoringTimeInMinutes?: any, RollbackTriggers?: any}
  --semanticVersion: string # <p>The semantic version of the application:</p><p>  <a href="https://semver.org/">https://semver.org/</a>  </p>
  stackName: string # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API.
  --tags: list # This property corresponds to the parameter of the same name for the <i>AWS CloudFormation <a href="https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet">CreateChangeSet</a>  </i> API. — item shape: {Key: any, Value: any}
  --templateId: string # <p>The UUID returned by CreateCloudFormationTemplate.</p><p>Pattern: [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}</p>
]: any -> record<ApplicationId: record, ChangeSetId: record, SemanticVersion: record, StackId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/changesets")
  let body = {capabilities: $capabilities, changeSetName: $changeSetName, clientToken: $clientToken, description: $description, notificationArns: $notificationArns, parameterOverrides: $parameterOverrides, resourceTypes: $resourceTypes, rollbackConfiguration: $rollbackConfiguration, semanticVersion: $semanticVersion, stackName: $stackName, tags: $tags, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an AWS CloudFormation template.
#
# POST /applications/{applicationId}/templates
# operationId: CreateCloudFormationTemplate
export def "applications-templates CreateCloudFormationTemplate" [
  applicationId: string
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
  --semanticVersion: string # <p>The semantic version of the application:</p><p>  <a href="https://semver.org/">https://semver.org/</a>  </p>
]: any -> record<ApplicationId: record, CreationTime: record, ExpirationTime: record, SemanticVersion: record, Status: record, TemplateId: record, TemplateUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/templates")
  let body = {semanticVersion: $semanticVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the specified application.
#
# DELETE /applications/{applicationId}
# operationId: DeleteApplication
export def "applications DeleteApplication" [
  applicationId: string
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
  let full_url = (build-url $base $"/applications/($applicationId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified application.
#
# GET /applications/{applicationId}
# operationId: GetApplication
export def "applications GetApplication" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --semanticVersion: string # The semantic version of the application to get.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "semanticVersion" $semanticVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($applicationId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the specified application.
#
# PATCH /applications/{applicationId}
# operationId: UpdateApplication
export def "applications UpdateApplication" [
  applicationId: string
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
  --author: string # <p>The name of the author publishing the app.</p><p>Minimum length=1. Maximum length=127.</p><p>Pattern "^[a-z0-9](([a-z0-9]|-(?!-))*[a-z0-9])?$";</p>
  --description: string # <p>The description of the application.</p><p>Minimum length=1. Maximum length=256</p>
  --homePageUrl: string # A URL with more information about the application, for example the location of your GitHub repository for the application.
  --labels: list # <p>Labels to improve discovery of apps in search results.</p><p>Minimum length=1. Maximum length=127. Maximum number of labels: 10</p><p>Pattern: "^[a-zA-Z0-9+\\-_:\\/@]+$";</p>
  --readmeBody: string # <p>A text readme file in Markdown language that contains a more detailed description of the application and how it works.</p><p>Maximum size 5 MB</p>
  --readmeUrl: string # <p>A link to the readme file in Markdown language that contains a more detailed description of the application and how it works.</p><p>Maximum size 5 MB</p>
]: any -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)")
  let body = {author: $author, description: $description, homePageUrl: $homePageUrl, labels: $labels, readmeBody: $readmeBody, readmeUrl: $readmeUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the policy for the application.
#
# GET /applications/{applicationId}/policy
# operationId: GetApplicationPolicy
export def "applications-policy GetApplicationPolicy" [
  applicationId: string
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
]: nothing -> record<Statements: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/policy")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the permission policy for an application. For the list of actions supported for this operation, see  <a href="https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions">Application   Permissions</a>  .
#
# PUT /applications/{applicationId}/policy
# operationId: PutApplicationPolicy
# --statements item shape: {Actions: any, PrincipalOrgIDs?: any, Principals: any, StatementId?: any}
export def "applications-policy PutApplicationPolicy" [
  applicationId: string
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
  statements: list # An array of policy statements applied to the application. — item shape: {Actions: any, PrincipalOrgIDs?: any, Principals: any, StatementId?: any}
]: any -> record<Statements: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/policy")
  let body = {statements: $statements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the specified AWS CloudFormation template.
#
# GET /applications/{applicationId}/templates/{templateId}
# operationId: GetCloudFormationTemplate
export def "applications-templates GetCloudFormationTemplate" [
  applicationId: string
  templateId: string
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
]: nothing -> record<ApplicationId: record, CreationTime: record, ExpirationTime: record, SemanticVersion: record, Status: record, TemplateId: record, TemplateUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/templates/($templateId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of applications nested in the containing application.
#
# GET /applications/{applicationId}/dependencies
# operationId: ListApplicationDependencies
export def "applications-dependencies ListApplicationDependencies" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxItems: int # The total number of items to return.
  --nextToken: string # A token to specify where to start paginating.
  --semanticVersion: string # The semantic version of the application to get.
  --MaxItems: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Dependencies: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "semanticVersion" $semanticVersion "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($applicationId)/dependencies" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists versions for the specified application.
#
# GET /applications/{applicationId}/versions
# operationId: ListApplicationVersions
export def "applications-versions ListApplicationVersions" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxItems: int # The total number of items to return.
  --nextToken: string # A token to specify where to start paginating.
  --MaxItems: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, Versions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxItems" $MaxItems "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($applicationId)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Unshares an application from an AWS Organization.</p><p>This operation can be called only from the organization's master account.</p>
#
# POST /applications/{applicationId}/unshare
# operationId: UnshareApplication
export def "applications-unshare UnshareApplication" [
  applicationId: string
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
  organizationId: string # The AWS Organization ID to unshare the application from.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($applicationId)/unshare")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
