# Auto-generated client for AWS Amplify v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/amplify/2017-07-25/openapi.json
# Auth: --token flag or $env.AWS_AMPLIFY_TOKEN

const BASE_URL = "http://amplify.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_AMPLIFY_TOKEN | default "" }
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

def base-url-completer [] { ["http://amplify.us-east-1.amazonaws.com" "http://amplify.us-east-2.amazonaws.com" "http://amplify.us-west-1.amazonaws.com" "http://amplify.us-west-2.amazonaws.com" "http://amplify.us-gov-west-1.amazonaws.com" "http://amplify.us-gov-east-1.amazonaws.com" "http://amplify.ca-central-1.amazonaws.com" "http://amplify.eu-north-1.amazonaws.com" "http://amplify.eu-west-1.amazonaws.com" "http://amplify.eu-west-2.amazonaws.com" "http://amplify.eu-west-3.amazonaws.com" "http://amplify.eu-central-1.amazonaws.com" "http://amplify.eu-south-1.amazonaws.com" "http://amplify.af-south-1.amazonaws.com" "http://amplify.ap-northeast-1.amazonaws.com" "http://amplify.ap-northeast-2.amazonaws.com" "http://amplify.ap-northeast-3.amazonaws.com" "http://amplify.ap-southeast-1.amazonaws.com" "http://amplify.ap-southeast-2.amazonaws.com" "http://amplify.ap-east-1.amazonaws.com" "http://amplify.ap-south-1.amazonaws.com" "http://amplify.sa-east-1.amazonaws.com" "http://amplify.me-south-1.amazonaws.com" "https://amplify.us-east-1.amazonaws.com" "https://amplify.us-east-2.amazonaws.com" "https://amplify.us-west-1.amazonaws.com" "https://amplify.us-west-2.amazonaws.com" "https://amplify.us-gov-west-1.amazonaws.com" "https://amplify.us-gov-east-1.amazonaws.com" "https://amplify.ca-central-1.amazonaws.com" "https://amplify.eu-north-1.amazonaws.com" "https://amplify.eu-west-1.amazonaws.com" "https://amplify.eu-west-2.amazonaws.com" "https://amplify.eu-west-3.amazonaws.com" "https://amplify.eu-central-1.amazonaws.com" "https://amplify.eu-south-1.amazonaws.com" "https://amplify.af-south-1.amazonaws.com" "https://amplify.ap-northeast-1.amazonaws.com" "https://amplify.ap-northeast-2.amazonaws.com" "https://amplify.ap-northeast-3.amazonaws.com" "https://amplify.ap-southeast-1.amazonaws.com" "https://amplify.ap-southeast-2.amazonaws.com" "https://amplify.ap-east-1.amazonaws.com" "https://amplify.ap-south-1.amazonaws.com" "https://amplify.sa-east-1.amazonaws.com" "https://amplify.me-south-1.amazonaws.com" "http://amplify.cn-north-1.amazonaws.com.cn" "http://amplify.cn-northwest-1.amazonaws.com.cn" "https://amplify.cn-north-1.amazonaws.com.cn" "https://amplify.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def platform-completer [] { ["WEB" "WEB_COMPUTE" "WEB_DYNAMIC"] }
def stage-completer [] { ["BETA" "DEVELOPMENT" "EXPERIMENTAL" "PRODUCTION" "PULL_REQUEST"] }
def job-type-completer [] { ["MANUAL" "RELEASE" "RETRY" "WEB_HOOK"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps create" } } | get name | first)
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

# Creates a new Amplify app.
#
# POST /apps
# operationId: CreateApp
# --customRules item shape: {source: any, target: any, status?: any, condition?: any}
# --autoBranchCreationConfig shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
export def "apps create" [
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
  name: string # The name for an Amplify app.
  --description: string # The description for an Amplify app.
  --repository: string # The repository for an Amplify app.
  --platform: string@platform-completer # The platform for the Amplify app. For a static app, set the platform type to WEB. For a dynamic server-side rendered (SSR) app, set the platform type to WEB_COMPUTE. For an app requiring Amplify Hosting's original SSR support only, set the platform type to WEB_DYNAMIC.
  --iam-service-role-arn: string # The AWS Identity and Access Management (IAM) service role for an Amplify app.
  --oauth-token: string # The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored. Use oauthToken for repository providers other than GitHub, such as Bitbucket or CodeCommit. To authorize access to GitHub as your repository provider, use accessToken. You must specify either oauthToken or accessToken when you create a new app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --access-token: string # The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored. Use accessToken for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use oauthToken. You must specify either accessToken or oauthToken when you create a new app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --environment-variables: record # The environment variables map for an Amplify app.
  --enable-branch-auto-build: oneof<nothing, bool> # Enables the auto building of branches for an Amplify app.
  --enable-branch-auto-deletion: oneof<nothing, bool> # Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository.
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for an Amplify app. This will apply to all branches that are part of this app.
  --basic-auth-credentials: string # The credentials for basic authorization for an Amplify app. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --custom-rules: list # The custom rewrite and redirect rules for an Amplify app. — item shape: {source: any, target: any, status?: any, condition?: any}
  --tags: record # The tag for an Amplify app.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --custom-headers: string # The custom HTTP headers for an Amplify app.
  --enable-auto-branch-creation: oneof<nothing, bool> # Enables automated branch creation for an Amplify app.
  --auto-branch-creation-patterns: list<string> # The automated branch creation glob patterns for an Amplify app.
  --auto-branch-creation-config: record # Describes the automated branch creation configuration. — shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
]: any -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps")
  let req_body = {"name": $name, "description": $description, "repository": $repository, "platform": $platform, "iamServiceRoleArn": $iam_service_role_arn, "oauthToken": $oauth_token, "accessToken": $access_token, "environmentVariables": $environment_variables, "enableBranchAutoBuild": $enable_branch_auto_build, "enableBranchAutoDeletion": $enable_branch_auto_deletion, "enableBasicAuth": $enable_basic_auth, "basicAuthCredentials": $basic_auth_credentials, "customRules": $custom_rules, "tags": $tags, "buildSpec": $build_spec, "customHeaders": $custom_headers, "enableAutoBranchCreation": $enable_auto_branch_creation, "autoBranchCreationPatterns": $auto_branch_creation_patterns, "autoBranchCreationConfig": $auto_branch_creation_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of the existing Amplify apps.
#
# GET /apps
# operationId: ListApps
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. If non-null, the pagination token is returned in a result. Pass its value in another request to retrieve more entries.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<apps: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new backend environment for an Amplify app.
#
# POST /apps/{appId}/backendenvironments
# operationId: CreateBackendEnvironment
export def "apps-backendenvironments create-backend-environment" [
  app_id: string
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
  environment_name: string # The name for the backend environment.
  --stack-name: string # The AWS CloudFormation stack name of a backend environment.
  --deployment-artifacts: string # The name of deployment artifacts.
]: any -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/backendenvironments"))
  let req_body = {"environmentName": $environment_name, "stackName": $stack_name, "deploymentArtifacts": $deployment_artifacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the backend environments for an Amplify app.
#
# GET /apps/{appId}/backendenvironments
# operationId: ListBackendEnvironments
export def "apps-backendenvironments list-backend-environments" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-name: string # The name of the backend environment
  --next-token: string # A pagination token. Set to null to start listing backend environments from the start. If a non-null pagination token is returned in a result, pass its value in here to list more backend environments.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<backendEnvironments: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environmentName" $environment_name "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/backendenvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new branch for an Amplify app.
#
# POST /apps/{appId}/branches
# operationId: CreateBranch
export def "apps-branches create-branch" [
  app_id: string
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
  branch_name: string # The name for the branch.
  --description: string # The description for the branch.
  --stage: string@stage-completer # Describes the current stage for the branch.
  --framework: string # The framework for the branch.
  --enable-notification: oneof<nothing, bool> # Enables notifications for the branch.
  --enable-auto-build: oneof<nothing, bool> # Enables auto building for the branch.
  --environment-variables: record # The environment variables for the branch.
  --basic-auth-credentials: string # The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for the branch.
  --enable-performance-mode: oneof<nothing, bool> # Enables performance mode for the branch. Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out.
  --tags: record # The tag for the branch.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --ttl: string # The content Time to Live (TTL) for the website in seconds.
  --display-name: string # The display name for a branch. This is used as the default domain prefix.
  --enable-pull-request-preview: oneof<nothing, bool> # Enables pull request previews for this branch.
  --pull-request-environment-name: string # The Amplify environment name for the pull request.
  --backend-environment-arn: string # The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app.
]: any -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/branches"))
  let req_body = {"branchName": $branch_name, "description": $description, "stage": $stage, "framework": $framework, "enableNotification": $enable_notification, "enableAutoBuild": $enable_auto_build, "environmentVariables": $environment_variables, "basicAuthCredentials": $basic_auth_credentials, "enableBasicAuth": $enable_basic_auth, "enablePerformanceMode": $enable_performance_mode, "tags": $tags, "buildSpec": $build_spec, "ttl": $ttl, "displayName": $display_name, "enablePullRequestPreview": $enable_pull_request_preview, "pullRequestEnvironmentName": $pull_request_environment_name, "backendEnvironmentArn": $backend_environment_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the branches of an Amplify app.
#
# GET /apps/{appId}/branches
# operationId: ListBranches
export def "apps-branches list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing branches from the start. If a non-null pagination token is returned in a result, pass its value in here to list more branches.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<branches: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/branches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a deployment for a manually deployed Amplify app. Manually deployed apps are not connected to a repository.
#
# POST /apps/{appId}/branches/{branchName}/deployments
# operationId: CreateDeployment
export def "apps-branches-deployments create" [
  app_id: string
  branch_name: string
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
  --file-map: record # An optional file map that contains the file name as the key and the file content md5 hash as the value. If this argument is provided, the service will generate a unique upload URL per file. Otherwise, the service will only generate a single upload URL for the zipped files.
]: any -> record<jobId: record, fileUploadUrls: record, zipUploadUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}/deployments"))
  let req_body = {"fileMap": $file_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new domain association for an Amplify app. This action associates a custom domain with the Amplify app
#
# POST /apps/{appId}/domains
# operationId: CreateDomainAssociation
# --subDomainSettings item shape: {prefix: any, branchName: any}
export def "apps-domains create-association" [
  app_id: string
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
  domain_name: string # The domain name for the domain association.
  --enable-auto-sub-domain: oneof<nothing, bool> # Enables the automated creation of subdomains for branches.
  sub_domain_settings: list # The setting for the subdomain. — item shape: {prefix: any, branchName: any}
  --auto-sub-domain-creation-patterns: list<string> # Sets the branch patterns for automatic subdomain creation.
  --auto-sub-domain-iam-role: string # The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains.
]: any -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/domains"))
  let req_body = {"domainName": $domain_name, "enableAutoSubDomain": $enable_auto_sub_domain, "subDomainSettings": $sub_domain_settings, "autoSubDomainCreationPatterns": $auto_sub_domain_creation_patterns, "autoSubDomainIAMRole": $auto_sub_domain_iam_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the domain associations for an Amplify app.
#
# GET /apps/{appId}/domains
# operationId: ListDomainAssociations
export def "apps-domains list-associations" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing apps from the start. If non-null, a pagination token is returned in a result. Pass its value in here to list more projects.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<domainAssociations: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/domains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new webhook on an Amplify app.
#
# POST /apps/{appId}/webhooks
# operationId: CreateWebhook
export def "apps-webhooks create" [
  app_id: string
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
  branch_name: string # The name for a branch that is part of an Amplify app.
  --description: string # The description for a webhook.
]: any -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/webhooks"))
  let req_body = {"branchName": $branch_name, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of webhooks for an Amplify app.
#
# GET /apps/{appId}/webhooks
# operationId: ListWebhooks
export def "apps-webhooks list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing webhooks from the start. If non-null,the pagination token is returned in a result. Pass its value in here to list more webhooks.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<webhooks: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Amplify app specified by an app ID.
#
# DELETE /apps/{appId}
# operationId: DeleteApp
export def "apps delete" [
  app_id: string
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
]: nothing -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an existing Amplify app by appID.
#
# GET /apps/{appId}
# operationId: GetApp
export def "apps get" [
  app_id: string
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
]: nothing -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Amplify app.
#
# POST /apps/{appId}
# operationId: UpdateApp
# --customRules item shape: {source: any, target: any, status?: any, condition?: any}
# --autoBranchCreationConfig shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
export def "apps update" [
  app_id: string
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
  --name: string # The name for an Amplify app.
  --description: string # The description for an Amplify app.
  --platform: string@platform-completer # The platform for the Amplify app. For a static app, set the platform type to WEB. For a dynamic server-side rendered (SSR) app, set the platform type to WEB_COMPUTE. For an app requiring Amplify Hosting's original SSR support only, set the platform type to WEB_DYNAMIC.
  --iam-service-role-arn: string # The AWS Identity and Access Management (IAM) service role for an Amplify app.
  --environment-variables: record # The environment variables for an Amplify app.
  --enable-branch-auto-build: oneof<nothing, bool> # Enables branch auto-building for an Amplify app.
  --enable-branch-auto-deletion: oneof<nothing, bool> # Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository.
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for an Amplify app.
  --basic-auth-credentials: string # The basic authorization credentials for an Amplify app. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --custom-rules: list # The custom redirect and rewrite rules for an Amplify app. — item shape: {source: any, target: any, status?: any, condition?: any}
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --custom-headers: string # The custom HTTP headers for an Amplify app.
  --enable-auto-branch-creation: oneof<nothing, bool> # Enables automated branch creation for an Amplify app.
  --auto-branch-creation-patterns: list<string> # Describes the automated branch creation glob patterns for an Amplify app.
  --auto-branch-creation-config: record # Describes the automated branch creation configuration. — shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
  --repository: string # The name of the repository for an Amplify app
  --oauth-token: string # The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored. Use oauthToken for repository providers other than GitHub, such as Bitbucket or CodeCommit. To authorize access to GitHub as your repository provider, use accessToken. You must specify either oauthToken or accessToken when you update an app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --access-token: string # The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored. Use accessToken for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use oauthToken. You must specify either accessToken or oauthToken when you update an app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
]: any -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let req_body = {"name": $name, "description": $description, "platform": $platform, "iamServiceRoleArn": $iam_service_role_arn, "environmentVariables": $environment_variables, "enableBranchAutoBuild": $enable_branch_auto_build, "enableBranchAutoDeletion": $enable_branch_auto_deletion, "enableBasicAuth": $enable_basic_auth, "basicAuthCredentials": $basic_auth_credentials, "customRules": $custom_rules, "buildSpec": $build_spec, "customHeaders": $custom_headers, "enableAutoBranchCreation": $enable_auto_branch_creation, "autoBranchCreationPatterns": $auto_branch_creation_patterns, "autoBranchCreationConfig": $auto_branch_creation_config, "repository": $repository, "oauthToken": $oauth_token, "accessToken": $access_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a backend environment for an Amplify app.
#
# DELETE /apps/{appId}/backendenvironments/{environmentName}
# operationId: DeleteBackendEnvironment
export def "apps-backendenvironments delete-backend-environment" [
  app_id: string
  environment_name: string
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
]: nothing -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), environment_name: (encode-path-segment $environment_name)} | format pattern "/apps/{app_id}/backendenvironments/{environment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a backend environment for an Amplify app.
#
# GET /apps/{appId}/backendenvironments/{environmentName}
# operationId: GetBackendEnvironment
export def "apps-backendenvironments get-backend-environment" [
  app_id: string
  environment_name: string
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
]: nothing -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), environment_name: (encode-path-segment $environment_name)} | format pattern "/apps/{app_id}/backendenvironments/{environment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a branch for an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}
# operationId: DeleteBranch
export def "apps-branches delete-branch" [
  app_id: string
  branch_name: string
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
]: nothing -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a branch for an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}
# operationId: GetBranch
export def "apps-branches get-branch" [
  app_id: string
  branch_name: string
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
]: nothing -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a branch for an Amplify app.
#
# POST /apps/{appId}/branches/{branchName}
# operationId: UpdateBranch
export def "apps-branches update-branch" [
  app_id: string
  branch_name: string
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
  --description: string # The description for the branch.
  --framework: string # The framework for the branch.
  --stage: string@stage-completer # Describes the current stage for the branch.
  --enable-notification: oneof<nothing, bool> # Enables notifications for the branch.
  --enable-auto-build: oneof<nothing, bool> # Enables auto building for the branch.
  --environment-variables: record # The environment variables for the branch.
  --basic-auth-credentials: string # The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for the branch.
  --enable-performance-mode: oneof<nothing, bool> # Enables performance mode for the branch. Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --ttl: string # The content Time to Live (TTL) for the website in seconds.
  --display-name: string # The display name for a branch. This is used as the default domain prefix.
  --enable-pull-request-preview: oneof<nothing, bool> # Enables pull request previews for this branch.
  --pull-request-environment-name: string # The Amplify environment name for the pull request.
  --backend-environment-arn: string # The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app.
]: any -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}"))
  let req_body = {"description": $description, "framework": $framework, "stage": $stage, "enableNotification": $enable_notification, "enableAutoBuild": $enable_auto_build, "environmentVariables": $environment_variables, "basicAuthCredentials": $basic_auth_credentials, "enableBasicAuth": $enable_basic_auth, "enablePerformanceMode": $enable_performance_mode, "buildSpec": $build_spec, "ttl": $ttl, "displayName": $display_name, "enablePullRequestPreview": $enable_pull_request_preview, "pullRequestEnvironmentName": $pull_request_environment_name, "backendEnvironmentArn": $backend_environment_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a domain association for an Amplify app.
#
# DELETE /apps/{appId}/domains/{domainName}
# operationId: DeleteDomainAssociation
export def "apps-domains delete-association" [
  app_id: string
  domain_name: string
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
]: nothing -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/apps/{app_id}/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the domain information for an Amplify app.
#
# GET /apps/{appId}/domains/{domainName}
# operationId: GetDomainAssociation
export def "apps-domains get-association" [
  app_id: string
  domain_name: string
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
]: nothing -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/apps/{app_id}/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new domain association for an Amplify app.
#
# POST /apps/{appId}/domains/{domainName}
# operationId: UpdateDomainAssociation
# --subDomainSettings item shape: {prefix: any, branchName: any}
export def "apps-domains update-association" [
  app_id: string
  domain_name: string
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
  --enable-auto-sub-domain: oneof<nothing, bool> # Enables the automated creation of subdomains for branches.
  --sub-domain-settings: list # Describes the settings for the subdomain. — item shape: {prefix: any, branchName: any}
  --auto-sub-domain-creation-patterns: list<string> # Sets the branch patterns for automatic subdomain creation.
  --auto-sub-domain-iam-role: string # The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains.
]: any -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/apps/{app_id}/domains/{domain_name}"))
  let req_body = {"enableAutoSubDomain": $enable_auto_sub_domain, "subDomainSettings": $sub_domain_settings, "autoSubDomainCreationPatterns": $auto_sub_domain_creation_patterns, "autoSubDomainIAMRole": $auto_sub_domain_iam_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a job for a branch of an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}
# operationId: DeleteJob
export def "apps-branches-jobs delete" [
  app_id: string
  branch_name: string
  job_id: string
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
]: nothing -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name), job_id: (encode-path-segment $job_id)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a job for a branch of an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}
# operationId: GetJob
export def "apps-branches-jobs get" [
  app_id: string
  branch_name: string
  job_id: string
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
]: nothing -> record<job: record<summary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>, steps: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name), job_id: (encode-path-segment $job_id)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a webhook.
#
# DELETE /webhooks/{webhookId}
# operationId: DeleteWebhook
export def "webhooks delete" [
  webhook_id: string
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
]: nothing -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the webhook information that corresponds to a specified webhook ID.
#
# GET /webhooks/{webhookId}
# operationId: GetWebhook
export def "webhooks get" [
  webhook_id: string
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
]: nothing -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a webhook.
#
# POST /webhooks/{webhookId}
# operationId: UpdateWebhook
export def "webhooks update" [
  webhook_id: string
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
  --branch-name: string # The name for a branch that is part of an Amplify app.
  --description: string # The description for a webhook.
]: any -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/webhooks/{webhook_id}"))
  let req_body = {"branchName": $branch_name, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the website access logs for a specific time range using a presigned URL.
#
# POST /apps/{appId}/accesslogs
# operationId: GenerateAccessLogs
export def "apps-accesslogs generate-access-logs" [
  app_id: string
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
  --start-time: string # The time at which the logs should start. The time range specified is inclusive of the start time. (format: date-time)
  --end-time: string # The time at which the logs should end. The time range specified is inclusive of the end time. (format: date-time)
  domain_name: string # The name of the domain.
]: any -> record<logUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accesslogs"))
  let req_body = {"startTime": $start_time, "endTime": $end_time, "domainName": $domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the artifact info that corresponds to an artifact id.
#
# GET /artifacts/{artifactId}
# operationId: GetArtifactUrl
export def "artifacts get-url" [
  artifact_id: string
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
]: nothing -> record<artifactId: record, artifactUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({artifact_id: (encode-path-segment $artifact_id)} | format pattern "/artifacts/{artifact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of artifacts for a specified app, branch, and job.
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts
# operationId: ListArtifacts
export def "apps-branches-jobs-artifacts list" [
  app_id: string
  branch_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing artifacts from start. If a non-null pagination token is returned in a result, pass its value in here to list more artifacts.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<artifacts: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name), job_id: (encode-path-segment $job_id)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs/{job_id}/artifacts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the jobs for a branch of an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}/jobs
# operationId: ListJobs
export def "apps-branches-jobs list" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing steps from the start. If a non-null pagination token is returned in a result, pass its value in here to list more steps.
  --max-results: int # The maximum number of records to list in a single response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<jobSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a new job for a branch of an Amplify app.
#
# POST /apps/{appId}/branches/{branchName}/jobs
# operationId: StartJob
export def "apps-branches-jobs start" [
  app_id: string
  branch_name: string
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
  --job-id: string # The unique ID for an existing job. This is required if the value of jobType is RETRY.
  job_type: string@job-type-completer # Describes the type for the job. The job type RELEASE starts a new job with the latest change from the specified branch. This value is available only for apps that are connected to a repository. The job type RETRY retries an existing job. If the job type value is RETRY, the jobId is also required.
  --job-reason: string # A descriptive reason for starting this job.
  --commit-id: string # The commit ID from a third-party repository provider for the job.
  --commit-message: string # The commit message from a third-party repository provider for the job.
  --commit-time: string # The commit date and time for the job. (format: date-time)
]: any -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs"))
  let req_body = {"jobId": $job_id, "jobType": $job_type, "jobReason": $job_reason, "commitId": $commit_id, "commitMessage": $commit_message, "commitTime": $commit_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of tags for a specified Amazon Resource Name (ARN).
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tags the resource with a tag key and value.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
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
  tags: record # The tags used to tag the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a deployment for a manually deployed app. Manually deployed apps are not connected to a repository.
#
# POST /apps/{appId}/branches/{branchName}/deployments/start
# operationId: StartDeployment
export def "apps-branches-deployments-start start" [
  app_id: string
  branch_name: string
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
  --job-id: string # The job ID for this deployment, generated by the create deployment request.
  --source-url: string # The source URL for this deployment, used when calling start deployment without create deployment. The source URL can be any HTTP GET URL that is publicly accessible and downloads a single .zip file.
]: any -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/apps/{app_id}/branches/{branch_name}/deployments/start"))
  let req_body = {"jobId": $job_id, "sourceUrl": $source_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a job that is in progress for a branch of an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}/stop
# operationId: StopJob
export def "apps-branches-jobs-stop stop" [
  app_id: string
  branch_name: string
  job_id: string
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
]: nothing -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), branch_name: (encode-path-segment $branch_name), job_id: (encode-path-segment $job_id)} | format pattern "/apps/{app_id}/branches/{branch_name}/jobs/{job_id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Untags a resource with a specified Amazon Resource Name (ARN).
#
# DELETE /tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The tag keys to use to untag a resource.
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
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
