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

def base-url-completer [] { ["http://serverlessrepo.us-east-1.amazonaws.com" "http://serverlessrepo.us-east-2.amazonaws.com" "http://serverlessrepo.us-west-1.amazonaws.com" "http://serverlessrepo.us-west-2.amazonaws.com" "http://serverlessrepo.us-gov-west-1.amazonaws.com" "http://serverlessrepo.us-gov-east-1.amazonaws.com" "http://serverlessrepo.ca-central-1.amazonaws.com" "http://serverlessrepo.eu-north-1.amazonaws.com" "http://serverlessrepo.eu-west-1.amazonaws.com" "http://serverlessrepo.eu-west-2.amazonaws.com" "http://serverlessrepo.eu-west-3.amazonaws.com" "http://serverlessrepo.eu-central-1.amazonaws.com" "http://serverlessrepo.eu-south-1.amazonaws.com" "http://serverlessrepo.af-south-1.amazonaws.com" "http://serverlessrepo.ap-northeast-1.amazonaws.com" "http://serverlessrepo.ap-northeast-2.amazonaws.com" "http://serverlessrepo.ap-northeast-3.amazonaws.com" "http://serverlessrepo.ap-southeast-1.amazonaws.com" "http://serverlessrepo.ap-southeast-2.amazonaws.com" "http://serverlessrepo.ap-east-1.amazonaws.com" "http://serverlessrepo.ap-south-1.amazonaws.com" "http://serverlessrepo.sa-east-1.amazonaws.com" "http://serverlessrepo.me-south-1.amazonaws.com" "https://serverlessrepo.us-east-1.amazonaws.com" "https://serverlessrepo.us-east-2.amazonaws.com" "https://serverlessrepo.us-west-1.amazonaws.com" "https://serverlessrepo.us-west-2.amazonaws.com" "https://serverlessrepo.us-gov-west-1.amazonaws.com" "https://serverlessrepo.us-gov-east-1.amazonaws.com" "https://serverlessrepo.ca-central-1.amazonaws.com" "https://serverlessrepo.eu-north-1.amazonaws.com" "https://serverlessrepo.eu-west-1.amazonaws.com" "https://serverlessrepo.eu-west-2.amazonaws.com" "https://serverlessrepo.eu-west-3.amazonaws.com" "https://serverlessrepo.eu-central-1.amazonaws.com" "https://serverlessrepo.eu-south-1.amazonaws.com" "https://serverlessrepo.af-south-1.amazonaws.com" "https://serverlessrepo.ap-northeast-1.amazonaws.com" "https://serverlessrepo.ap-northeast-2.amazonaws.com" "https://serverlessrepo.ap-northeast-3.amazonaws.com" "https://serverlessrepo.ap-southeast-1.amazonaws.com" "https://serverlessrepo.ap-southeast-2.amazonaws.com" "https://serverlessrepo.ap-east-1.amazonaws.com" "https://serverlessrepo.ap-south-1.amazonaws.com" "https://serverlessrepo.sa-east-1.amazonaws.com" "https://serverlessrepo.me-south-1.amazonaws.com" "http://serverlessrepo.cn-north-1.amazonaws.com.cn" "http://serverlessrepo.cn-northwest-1.amazonaws.com.cn" "https://serverlessrepo.cn-north-1.amazonaws.com.cn" "https://serverlessrepo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications create" } } | get name | first)
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
export def "applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  author: string # The name of the author publishing the app.Minimum length=1. Maximum length=127.Pattern "^[a-z0-9](([a-z0-9]|-(?!-))*[a-z0-9])?$";
  description: string # The description of the application.Minimum length=1. Maximum length=256
  --home-page-url: string # A URL with more information about the application, for example the location of your GitHub repository for the application.
  --labels: list<string> # Labels to improve discovery of apps in search results.Minimum length=1. Maximum length=127. Maximum number of labels: 10Pattern: "^[a-zA-Z0-9+\\-_:\\/@]+$";
  --license-body: string # A local text file that contains the license of the app that matches the spdxLicenseID value of your application. The file has the format file://<path>/<filename>.Maximum size 5 MBYou can specify only one of licenseBody and licenseUrl; otherwise, an error results.
  --license-url: string # A link to the S3 object that contains the license of the app that matches the spdxLicenseID value of your application.Maximum size 5 MBYou can specify only one of licenseBody and licenseUrl; otherwise, an error results.
  name: string # The name of the application that you want to publish.Minimum length=1. Maximum length=140Pattern: "[a-zA-Z0-9\\-]+";
  --readme-body: string # A local text readme file in Markdown language that contains a more detailed description of the application and how it works. The file has the format file://<path>/<filename>.Maximum size 5 MBYou can specify only one of readmeBody and readmeUrl; otherwise, an error results.
  --readme-url: string # A link to the S3 object in Markdown language that contains a more detailed description of the application and how it works.Maximum size 5 MBYou can specify only one of readmeBody and readmeUrl; otherwise, an error results.
  --semantic-version: string # The semantic version of the application: https://semver.org/ (https://semver.org/)
  --source-code-archive-url: string # A link to the S3 object that contains the ZIP archive of the source code for this version of your application.Maximum size 50 MB
  --source-code-url: string # A link to a public repository for the source code of your application, for example the URL of a specific GitHub commit.
  --spdx-license-id: string # A valid identifier from https://spdx.org/licenses/ (https://spdx.org/licenses/).
  --template-body: string # The local raw packaged AWS SAM template file of your application. The file has the format file://<path>/<filename>.You can specify only one of templateBody and templateUrl; otherwise an error results.
  --template-url: string # A link to the S3 object containing the packaged AWS SAM template of your application.You can specify only one of templateBody and templateUrl; otherwise an error results.
]: any -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applications")
  let req_body = {"author": $author, "description": $description, "homePageUrl": $home_page_url, "labels": $labels, "licenseBody": $license_body, "licenseUrl": $license_url, "name": $name, "readmeBody": $readme_body, "readmeUrl": $readme_url, "semanticVersion": $semantic_version, "sourceCodeArchiveUrl": $source_code_archive_url, "sourceCodeUrl": $source_code_url, "spdxLicenseId": $spdx_license_id, "templateBody": $template_body, "templateUrl": $template_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists applications owned by the requester.
#
# GET /applications
# operationId: ListApplications
export def "applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # The total number of items to return.
  --next-token: string # A token to specify where to start paginating.
  --max-items: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Applications: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $max_items "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an application version.
#
# PUT /applications/{applicationId}/versions/{semanticVersion}
# operationId: CreateApplicationVersion
export def "applications-versions create" [
  application_id: string
  semantic_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --source-code-archive-url: string # A link to the S3 object that contains the ZIP archive of the source code for this version of your application.Maximum size 50 MB
  --source-code-url: string # A link to a public repository for the source code of your application, for example the URL of a specific GitHub commit.
  --template-body: string # The raw packaged AWS SAM template of your application.
  --template-url: string # A link to the packaged AWS SAM template of your application.
]: any -> record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), semantic_version: (encode-path-segment $semantic_version)} | format pattern "/applications/{application_id}/versions/{semantic_version}"))
  let req_body = {"sourceCodeArchiveUrl": $source_code_archive_url, "sourceCodeUrl": $source_code_url, "templateBody": $template_body, "templateUrl": $template_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an AWS CloudFormation change set for the given application.
#
# POST /applications/{applicationId}/changesets
# operationId: CreateCloudFormationChangeSet
# --parameterOverrides item shape: {Name: any, Value: any}
# --rollbackConfiguration shape: {MonitoringTimeInMinutes?: any, RollbackTriggers?: any}
# --tags item shape: {Key: any, Value: any}
export def "applications-changesets create-cloud-formation-change-update" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --capabilities: list<string> # A list of values that you must specify before you can deploy certain applications. Some applications might include resources that can affect permissions in your AWS account, for example, by creating new AWS Identity and Access Management (IAM) users. For those applications, you must explicitly acknowledge their capabilities by specifying this parameter.The only valid values are CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_RESOURCE_POLICY, and CAPABILITY_AUTO_EXPAND.The following resources require you to specify CAPABILITY_IAM or CAPABILITY_NAMED_IAM: AWS::IAM::Group (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-iam-group.html), AWS::IAM::InstanceProfile (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-instanceprofile.html), AWS::IAM::Policy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html), and AWS::IAM::Role (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html). If the application contains IAM resources, you can specify either CAPABILITY_IAM or CAPABILITY_NAMED_IAM. If the application contains IAM resources with custom names, you must specify CAPABILITY_NAMED_IAM.The following resources require you to specify CAPABILITY_RESOURCE_POLICY: AWS::Lambda::Permission (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-permission.html), AWS::IAM:Policy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html), AWS::ApplicationAutoScaling::ScalingPolicy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-applicationautoscaling-scalingpolicy.html), AWS::S3::BucketPolicy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-policy.html), AWS::SQS::QueuePolicy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-policy.html), and AWS::SNS:TopicPolicy (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-policy.html).Applications that contain one or more nested applications require you to specify CAPABILITY_AUTO_EXPAND.If your application template contains any of the above resources, we recommend that you review all permissions associated with the application before deploying. If you don't specify this parameter for an application that requires capabilities, the call will fail.
  --change-set-name: string # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --client-token: string # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --description: string # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --notification-arns: list<string> # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --parameter-overrides: list # A list of parameter values for the parameters of the application. — item shape: {Name: any, Value: any}
  --resource-types: list<string> # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --rollback-configuration: record # This property corresponds to the AWS CloudFormation RollbackConfiguration (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/RollbackConfiguration) Data Type. — shape: {MonitoringTimeInMinutes?: any, RollbackTriggers?: any}
  --semantic-version: string # The semantic version of the application: https://semver.org/ (https://semver.org/)
  stack_name: string # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API.
  --tags: list # This property corresponds to the parameter of the same name for the AWS CloudFormation CreateChangeSet (https://docs.aws.amazon.com/goto/WebAPI/cloudformation-2010-05-15/CreateChangeSet) API. — item shape: {Key: any, Value: any}
  --template-id: string # The UUID returned by CreateCloudFormationTemplate.Pattern: [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}
]: any -> record<ApplicationId: record, ChangeSetId: record, SemanticVersion: record, StackId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/changesets"))
  let req_body = {"capabilities": $capabilities, "changeSetName": $change_set_name, "clientToken": $client_token, "description": $description, "notificationArns": $notification_arns, "parameterOverrides": $parameter_overrides, "resourceTypes": $resource_types, "rollbackConfiguration": $rollback_configuration, "semanticVersion": $semantic_version, "stackName": $stack_name, "tags": $tags, "templateId": $template_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an AWS CloudFormation template.
#
# POST /applications/{applicationId}/templates
# operationId: CreateCloudFormationTemplate
export def "applications-templates create-cloud-formation" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --semantic-version: string # The semantic version of the application: https://semver.org/ (https://semver.org/)
]: any -> record<ApplicationId: record, CreationTime: record, ExpirationTime: record, SemanticVersion: record, Status: record, TemplateId: record, TemplateUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/templates"))
  let req_body = {"semanticVersion": $semantic_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified application.
#
# DELETE /applications/{applicationId}
# operationId: DeleteApplication
export def "applications delete" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified application.
#
# GET /applications/{applicationId}
# operationId: GetApplication
export def "applications get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --semantic-version: string # The semantic version of the application to get.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "semanticVersion" $semantic_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified application.
#
# PATCH /applications/{applicationId}
# operationId: UpdateApplication
export def "applications update" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --author: string # The name of the author publishing the app.Minimum length=1. Maximum length=127.Pattern "^[a-z0-9](([a-z0-9]|-(?!-))*[a-z0-9])?$";
  --description: string # The description of the application.Minimum length=1. Maximum length=256
  --home-page-url: string # A URL with more information about the application, for example the location of your GitHub repository for the application.
  --labels: list<string> # Labels to improve discovery of apps in search results.Minimum length=1. Maximum length=127. Maximum number of labels: 10Pattern: "^[a-zA-Z0-9+\\-_:\\/@]+$";
  --readme-body: string # A text readme file in Markdown language that contains a more detailed description of the application and how it works.Maximum size 5 MB
  --readme-url: string # A link to the readme file in Markdown language that contains a more detailed description of the application and how it works.Maximum size 5 MB
]: any -> record<ApplicationId: record, Author: record, CreationTime: record, Description: record, HomePageUrl: record, IsVerifiedAuthor: record, Labels: record, LicenseUrl: record, Name: record, ReadmeUrl: record, SpdxLicenseId: record, VerifiedAuthorUrl: record, Version: record<ApplicationId: record, CreationTime: record, ParameterDefinitions: record, RequiredCapabilities: record, ResourcesSupported: record, SemanticVersion: record, SourceCodeArchiveUrl: record, SourceCodeUrl: record, TemplateUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}"))
  let req_body = {"author": $author, "description": $description, "homePageUrl": $home_page_url, "labels": $labels, "readmeBody": $readme_body, "readmeUrl": $readme_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the policy for the application.
#
# GET /applications/{applicationId}/policy
# operationId: GetApplicationPolicy
export def "applications-policy get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Statements: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/policy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the permission policy for an application. For the list of actions supported for this operation, see Application Permissions (https://docs.aws.amazon.com/serverlessrepo/latest/devguide/access-control-resource-based.html#application-permissions) .
#
# PUT /applications/{applicationId}/policy
# operationId: PutApplicationPolicy
# --statements item shape: {Actions: any, PrincipalOrgIDs?: any, Principals: any, StatementId?: any}
export def "applications-policy update" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statements: list # An array of policy statements applied to the application. — item shape: {Actions: any, PrincipalOrgIDs?: any, Principals: any, StatementId?: any}
]: any -> record<Statements: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/policy"))
  let req_body = {"statements": $statements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the specified AWS CloudFormation template.
#
# GET /applications/{applicationId}/templates/{templateId}
# operationId: GetCloudFormationTemplate
export def "applications-templates get-cloud-formation" [
  application_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ApplicationId: record, CreationTime: record, ExpirationTime: record, SemanticVersion: record, Status: record, TemplateId: record, TemplateUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), template_id: (encode-path-segment $template_id)} | format pattern "/applications/{application_id}/templates/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the list of applications nested in the containing application.
#
# GET /applications/{applicationId}/dependencies
# operationId: ListApplicationDependencies
export def "applications-dependencies list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # The total number of items to return.
  --next-token: string # A token to specify where to start paginating.
  --semantic-version: string # The semantic version of the application to get.
  --max-items: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Dependencies: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $max_items "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "semanticVersion" $semantic_version "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/dependencies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists versions for the specified application.
#
# GET /applications/{applicationId}/versions
# operationId: ListApplicationVersions
export def "applications-versions list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # The total number of items to return.
  --next-token: string # A token to specify where to start paginating.
  --max-items: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Versions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxItems" $max_items "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unshares an application from an AWS Organization.This operation can be called only from the organization's master account.
#
# POST /applications/{applicationId}/unshare
# operationId: UnshareApplication
export def "applications-unshare create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  organization_id: string # The AWS Organization ID to unshare the application from.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}/unshare"))
  let req_body = {"organizationId": $organization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
