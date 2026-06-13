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
def jobType-completer [] { ["MANUAL" "RELEASE" "RETRY" "WEB_HOOK"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps CreateApp" } } | get name | first)
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

#  Creates a new Amplify app. 
#
# POST /apps
# operationId: CreateApp
# --customRules item shape: {source: any, target: any, status?: any, condition?: any}
# --autoBranchCreationConfig shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
export def "apps CreateApp" [
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
  name: string #  The name for an Amplify app. 
  --description: string #  The description for an Amplify app. 
  --repository: string #  The repository for an Amplify app. 
  --platform: string@platform-completer #  The platform for the Amplify app. For a static app, set the platform type to <code>WEB</code>. For a dynamic server-side rendered (SSR) app, set the platform type to <code>WEB_COMPUTE</code>. For an app requiring Amplify Hosting's original SSR support only, set the platform type to <code>WEB_DYNAMIC</code>.
  --iamServiceRoleArn: string #  The AWS Identity and Access Management (IAM) service role for an Amplify app. 
  --oauthToken: string # <p>The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored.</p> <p>Use <code>oauthToken</code> for repository providers other than GitHub, such as Bitbucket or CodeCommit. To authorize access to GitHub as your repository provider, use <code>accessToken</code>.</p> <p>You must specify either <code>oauthToken</code> or <code>accessToken</code> when you create a new app.</p> <p>Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see <a href="https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth">Migrating an existing OAuth app to the Amplify GitHub App</a> in the <i>Amplify User Guide</i> .</p> (format: password)
  --accessToken: string # <p>The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored.</p> <p>Use <code>accessToken</code> for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use <code>oauthToken</code>.</p> <p>You must specify either <code>accessToken</code> or <code>oauthToken</code> when you create a new app.</p> <p>Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see <a href="https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth">Migrating an existing OAuth app to the Amplify GitHub App</a> in the <i>Amplify User Guide</i> .</p> (format: password)
  --environmentVariables: record #  The environment variables map for an Amplify app. 
  --enableBranchAutoBuild: oneof<nothing, bool> #  Enables the auto building of branches for an Amplify app. 
  --enableBranchAutoDeletion: oneof<nothing, bool> #  Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository. 
  --enableBasicAuth: oneof<nothing, bool> #  Enables basic authorization for an Amplify app. This will apply to all branches that are part of this app. 
  --basicAuthCredentials: string #  The credentials for basic authorization for an Amplify app. You must base64-encode the authorization credentials and provide them in the format <code>user:password</code>. (format: password)
  --customRules: list #  The custom rewrite and redirect rules for an Amplify app.  — item shape: {source: any, target: any, status?: any, condition?: any}
  --tags: record #  The tag for an Amplify app. 
  --buildSpec: string #  The build specification (build spec) file for an Amplify app build.  (format: password)
  --customHeaders: string # The custom HTTP headers for an Amplify app.
  --enableAutoBranchCreation: oneof<nothing, bool> #  Enables automated branch creation for an Amplify app. 
  --autoBranchCreationPatterns: list #  The automated branch creation glob patterns for an Amplify app. 
  --autoBranchCreationConfig: record #  Describes the automated branch creation configuration.  — shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
]: any -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps")
  let body = {name: $name, description: $description, repository: $repository, platform: $platform, iamServiceRoleArn: $iamServiceRoleArn, oauthToken: $oauthToken, accessToken: $accessToken, environmentVariables: $environmentVariables, enableBranchAutoBuild: $enableBranchAutoBuild, enableBranchAutoDeletion: $enableBranchAutoDeletion, enableBasicAuth: $enableBasicAuth, basicAuthCredentials: $basicAuthCredentials, customRules: $customRules, tags: $tags, buildSpec: $buildSpec, customHeaders: $customHeaders, enableAutoBranchCreation: $enableAutoBranchCreation, autoBranchCreationPatterns: $autoBranchCreationPatterns, autoBranchCreationConfig: $autoBranchCreationConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns a list of the existing Amplify apps. 
#
# GET /apps
# operationId: ListApps
export def "apps ListApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. If non-null, the pagination token is returned in a result. Pass its value in another request to retrieve more entries. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<apps: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Creates a new backend environment for an Amplify app. 
#
# POST /apps/{appId}/backendenvironments
# operationId: CreateBackendEnvironment
export def "apps-backendenvironments CreateBackendEnvironment" [
  appId: string
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
  environmentName: string #  The name for the backend environment. 
  --stackName: string #  The AWS CloudFormation stack name of a backend environment. 
  --deploymentArtifacts: string #  The name of deployment artifacts. 
]: any -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/backendenvironments")
  let body = {environmentName: $environmentName, stackName: $stackName, deploymentArtifacts: $deploymentArtifacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Lists the backend environments for an Amplify app. 
#
# GET /apps/{appId}/backendenvironments
# operationId: ListBackendEnvironments
export def "apps-backendenvironments ListBackendEnvironments" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentName: string #  The name of the backend environment 
  --nextToken: string #  A pagination token. Set to null to start listing backend environments from the start. If a non-null pagination token is returned in a result, pass its value in here to list more backend environments. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<backendEnvironments: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environmentName" $environmentName "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/backendenvironments" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Creates a new branch for an Amplify app. 
#
# POST /apps/{appId}/branches
# operationId: CreateBranch
export def "apps-branches CreateBranch" [
  appId: string
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
  branchName: string #  The name for the branch. 
  --description: string #  The description for the branch. 
  --stage: string@stage-completer #  Describes the current stage for the branch. 
  --framework: string #  The framework for the branch. 
  --enableNotification: oneof<nothing, bool> #  Enables notifications for the branch. 
  --enableAutoBuild: oneof<nothing, bool> #  Enables auto building for the branch. 
  --environmentVariables: record #  The environment variables for the branch. 
  --basicAuthCredentials: string #  The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format <code>user:password</code>. (format: password)
  --enableBasicAuth: oneof<nothing, bool> #  Enables basic authorization for the branch. 
  --enablePerformanceMode: oneof<nothing, bool> # <p>Enables performance mode for the branch.</p> <p>Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out. </p>
  --tags: record #  The tag for the branch. 
  --buildSpec: string #  The build specification (build spec) file for an Amplify app build.  (format: password)
  --ttl: string #  The content Time to Live (TTL) for the website in seconds. 
  --displayName: string #  The display name for a branch. This is used as the default domain prefix. 
  --enablePullRequestPreview: oneof<nothing, bool> #  Enables pull request previews for this branch. 
  --pullRequestEnvironmentName: string #  The Amplify environment name for the pull request. 
  --backendEnvironmentArn: string #  The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app. 
]: any -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches")
  let body = {branchName: $branchName, description: $description, stage: $stage, framework: $framework, enableNotification: $enableNotification, enableAutoBuild: $enableAutoBuild, environmentVariables: $environmentVariables, basicAuthCredentials: $basicAuthCredentials, enableBasicAuth: $enableBasicAuth, enablePerformanceMode: $enablePerformanceMode, tags: $tags, buildSpec: $buildSpec, ttl: $ttl, displayName: $displayName, enablePullRequestPreview: $enablePullRequestPreview, pullRequestEnvironmentName: $pullRequestEnvironmentName, backendEnvironmentArn: $backendEnvironmentArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Lists the branches of an Amplify app. 
#
# GET /apps/{appId}/branches
# operationId: ListBranches
export def "apps-branches ListBranches" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. Set to null to start listing branches from the start. If a non-null pagination token is returned in a result, pass its value in here to list more branches. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<branches: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/branches" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Creates a deployment for a manually deployed Amplify app. Manually deployed apps are not connected to a repository. 
#
# POST /apps/{appId}/branches/{branchName}/deployments
# operationId: CreateDeployment
export def "apps-branches-deployments CreateDeployment" [
  appId: string
  branchName: string
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
  --fileMap: record #  An optional file map that contains the file name as the key and the file content md5 hash as the value. If this argument is provided, the service will generate a unique upload URL per file. Otherwise, the service will only generate a single upload URL for the zipped files. 
]: any -> record<jobId: record, fileUploadUrls: record, zipUploadUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/deployments")
  let body = {fileMap: $fileMap} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Creates a new domain association for an Amplify app. This action associates a custom domain with the Amplify app 
#
# POST /apps/{appId}/domains
# operationId: CreateDomainAssociation
# --subDomainSettings item shape: {prefix: any, branchName: any}
export def "apps-domains CreateDomainAssociation" [
  appId: string
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
  domainName: string #  The domain name for the domain association. 
  --enableAutoSubDomain: oneof<nothing, bool> #  Enables the automated creation of subdomains for branches. 
  subDomainSettings: list #  The setting for the subdomain.  — item shape: {prefix: any, branchName: any}
  --autoSubDomainCreationPatterns: list #  Sets the branch patterns for automatic subdomain creation. 
  --autoSubDomainIAMRole: string #  The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains. 
]: any -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/domains")
  let body = {domainName: $domainName, enableAutoSubDomain: $enableAutoSubDomain, subDomainSettings: $subDomainSettings, autoSubDomainCreationPatterns: $autoSubDomainCreationPatterns, autoSubDomainIAMRole: $autoSubDomainIAMRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns the domain associations for an Amplify app. 
#
# GET /apps/{appId}/domains
# operationId: ListDomainAssociations
export def "apps-domains ListDomainAssociations" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. Set to null to start listing apps from the start. If non-null, a pagination token is returned in a result. Pass its value in here to list more projects. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<domainAssociations: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/domains" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Creates a new webhook on an Amplify app. 
#
# POST /apps/{appId}/webhooks
# operationId: CreateWebhook
export def "apps-webhooks CreateWebhook" [
  appId: string
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
  branchName: string #  The name for a branch that is part of an Amplify app. 
  --description: string #  The description for a webhook. 
]: any -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/webhooks")
  let body = {branchName: $branchName, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns a list of webhooks for an Amplify app. 
#
# GET /apps/{appId}/webhooks
# operationId: ListWebhooks
export def "apps-webhooks ListWebhooks" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. Set to null to start listing webhooks from the start. If non-null,the pagination token is returned in a result. Pass its value in here to list more webhooks. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<webhooks: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/webhooks" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Deletes an existing Amplify app specified by an app ID. 
#
# DELETE /apps/{appId}
# operationId: DeleteApp
export def "apps DeleteApp" [
  appId: string
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
]: nothing -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns an existing Amplify app by appID. 
#
# GET /apps/{appId}
# operationId: GetApp
export def "apps GetApp" [
  appId: string
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
]: nothing -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Updates an existing Amplify app. 
#
# POST /apps/{appId}
# operationId: UpdateApp
# --customRules item shape: {source: any, target: any, status?: any, condition?: any}
# --autoBranchCreationConfig shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
export def "apps UpdateApp" [
  appId: string
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
  --name: string #  The name for an Amplify app. 
  --description: string #  The description for an Amplify app. 
  --platform: string@platform-completer #  The platform for the Amplify app. For a static app, set the platform type to <code>WEB</code>. For a dynamic server-side rendered (SSR) app, set the platform type to <code>WEB_COMPUTE</code>. For an app requiring Amplify Hosting's original SSR support only, set the platform type to <code>WEB_DYNAMIC</code>.
  --iamServiceRoleArn: string #  The AWS Identity and Access Management (IAM) service role for an Amplify app. 
  --environmentVariables: record #  The environment variables for an Amplify app. 
  --enableBranchAutoBuild: oneof<nothing, bool> #  Enables branch auto-building for an Amplify app. 
  --enableBranchAutoDeletion: oneof<nothing, bool> #  Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository. 
  --enableBasicAuth: oneof<nothing, bool> #  Enables basic authorization for an Amplify app. 
  --basicAuthCredentials: string #  The basic authorization credentials for an Amplify app. You must base64-encode the authorization credentials and provide them in the format <code>user:password</code>. (format: password)
  --customRules: list #  The custom redirect and rewrite rules for an Amplify app.  — item shape: {source: any, target: any, status?: any, condition?: any}
  --buildSpec: string #  The build specification (build spec) file for an Amplify app build.  (format: password)
  --customHeaders: string # The custom HTTP headers for an Amplify app.
  --enableAutoBranchCreation: oneof<nothing, bool> #  Enables automated branch creation for an Amplify app. 
  --autoBranchCreationPatterns: list #  Describes the automated branch creation glob patterns for an Amplify app. 
  --autoBranchCreationConfig: record #  Describes the automated branch creation configuration.  — shape: {stage?: any, framework?: any, enableAutoBuild?: any, environmentVariables?: any, basicAuthCredentials?: any, enableBasicAuth?: any, enablePerformanceMode?: any, buildSpec?: any, enablePullRequestPreview?: any, pullRequestEnvironmentName?: any}
  --repository: string #  The name of the repository for an Amplify app 
  --oauthToken: string # <p>The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored.</p> <p>Use <code>oauthToken</code> for repository providers other than GitHub, such as Bitbucket or CodeCommit.</p> <p>To authorize access to GitHub as your repository provider, use <code>accessToken</code>.</p> <p>You must specify either <code>oauthToken</code> or <code>accessToken</code> when you update an app.</p> <p>Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see <a href="https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth">Migrating an existing OAuth app to the Amplify GitHub App</a> in the <i>Amplify User Guide</i> .</p> (format: password)
  --accessToken: string # <p>The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored.</p> <p>Use <code>accessToken</code> for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use <code>oauthToken</code>.</p> <p>You must specify either <code>accessToken</code> or <code>oauthToken</code> when you update an app.</p> <p>Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see <a href="https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth">Migrating an existing OAuth app to the Amplify GitHub App</a> in the <i>Amplify User Guide</i> .</p> (format: password)
]: any -> record<app: record<appId: record, appArn: record, name: record, tags: record, description: record, repository: record, platform: record, createTime: record, updateTime: record, iamServiceRoleArn: record, environmentVariables: record, defaultDomain: record, enableBranchAutoBuild: record, enableBranchAutoDeletion: record, enableBasicAuth: record, basicAuthCredentials: record, customRules: record, productionBranch: record<lastDeployTime: record, status: record, thumbnailUrl: record, branchName: record>, buildSpec: record, customHeaders: record, enableAutoBranchCreation: record, autoBranchCreationPatterns: record, autoBranchCreationConfig: record<stage: record, framework: record, enableAutoBuild: record, environmentVariables: record, basicAuthCredentials: record, enableBasicAuth: record, enablePerformanceMode: record, buildSpec: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record>, repositoryCloneMethod: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)")
  let body = {name: $name, description: $description, platform: $platform, iamServiceRoleArn: $iamServiceRoleArn, environmentVariables: $environmentVariables, enableBranchAutoBuild: $enableBranchAutoBuild, enableBranchAutoDeletion: $enableBranchAutoDeletion, enableBasicAuth: $enableBasicAuth, basicAuthCredentials: $basicAuthCredentials, customRules: $customRules, buildSpec: $buildSpec, customHeaders: $customHeaders, enableAutoBranchCreation: $enableAutoBranchCreation, autoBranchCreationPatterns: $autoBranchCreationPatterns, autoBranchCreationConfig: $autoBranchCreationConfig, repository: $repository, oauthToken: $oauthToken, accessToken: $accessToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Deletes a backend environment for an Amplify app. 
#
# DELETE /apps/{appId}/backendenvironments/{environmentName}
# operationId: DeleteBackendEnvironment
export def "apps-backendenvironments DeleteBackendEnvironment" [
  appId: string
  environmentName: string
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
]: nothing -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/backendenvironments/($environmentName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns a backend environment for an Amplify app. 
#
# GET /apps/{appId}/backendenvironments/{environmentName}
# operationId: GetBackendEnvironment
export def "apps-backendenvironments GetBackendEnvironment" [
  appId: string
  environmentName: string
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
]: nothing -> record<backendEnvironment: record<backendEnvironmentArn: record, environmentName: record, stackName: record, deploymentArtifacts: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/backendenvironments/($environmentName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Deletes a branch for an Amplify app. 
#
# DELETE /apps/{appId}/branches/{branchName}
# operationId: DeleteBranch
export def "apps-branches DeleteBranch" [
  appId: string
  branchName: string
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
]: nothing -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns a branch for an Amplify app. 
#
# GET /apps/{appId}/branches/{branchName}
# operationId: GetBranch
export def "apps-branches GetBranch" [
  appId: string
  branchName: string
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
]: nothing -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Updates a branch for an Amplify app. 
#
# POST /apps/{appId}/branches/{branchName}
# operationId: UpdateBranch
export def "apps-branches UpdateBranch" [
  appId: string
  branchName: string
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
  --description: string #  The description for the branch. 
  --framework: string #  The framework for the branch. 
  --stage: string@stage-completer #  Describes the current stage for the branch. 
  --enableNotification: oneof<nothing, bool> #  Enables notifications for the branch. 
  --enableAutoBuild: oneof<nothing, bool> #  Enables auto building for the branch. 
  --environmentVariables: record #  The environment variables for the branch. 
  --basicAuthCredentials: string #  The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format <code>user:password</code>. (format: password)
  --enableBasicAuth: oneof<nothing, bool> #  Enables basic authorization for the branch. 
  --enablePerformanceMode: oneof<nothing, bool> # <p>Enables performance mode for the branch.</p> <p>Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out. </p>
  --buildSpec: string #  The build specification (build spec) file for an Amplify app build.  (format: password)
  --ttl: string #  The content Time to Live (TTL) for the website in seconds. 
  --displayName: string #  The display name for a branch. This is used as the default domain prefix. 
  --enablePullRequestPreview: oneof<nothing, bool> #  Enables pull request previews for this branch. 
  --pullRequestEnvironmentName: string #  The Amplify environment name for the pull request. 
  --backendEnvironmentArn: string #  The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app. 
]: any -> record<branch: record<branchArn: record, branchName: record, description: record, tags: record, stage: record, displayName: record, enableNotification: record, createTime: record, updateTime: record, environmentVariables: record, enableAutoBuild: record, customDomains: record, framework: record, activeJobId: record, totalNumberOfJobs: record, enableBasicAuth: record, enablePerformanceMode: record, thumbnailUrl: record, basicAuthCredentials: record, buildSpec: record, ttl: record, associatedResources: record, enablePullRequestPreview: record, pullRequestEnvironmentName: record, destinationBranch: record, sourceBranch: record, backendEnvironmentArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)")
  let body = {description: $description, framework: $framework, stage: $stage, enableNotification: $enableNotification, enableAutoBuild: $enableAutoBuild, environmentVariables: $environmentVariables, basicAuthCredentials: $basicAuthCredentials, enableBasicAuth: $enableBasicAuth, enablePerformanceMode: $enablePerformanceMode, buildSpec: $buildSpec, ttl: $ttl, displayName: $displayName, enablePullRequestPreview: $enablePullRequestPreview, pullRequestEnvironmentName: $pullRequestEnvironmentName, backendEnvironmentArn: $backendEnvironmentArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Deletes a domain association for an Amplify app. 
#
# DELETE /apps/{appId}/domains/{domainName}
# operationId: DeleteDomainAssociation
export def "apps-domains DeleteDomainAssociation" [
  appId: string
  domainName: string
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
]: nothing -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/domains/($domainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns the domain information for an Amplify app. 
#
# GET /apps/{appId}/domains/{domainName}
# operationId: GetDomainAssociation
export def "apps-domains GetDomainAssociation" [
  appId: string
  domainName: string
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
]: nothing -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/domains/($domainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Creates a new domain association for an Amplify app.
#
# POST /apps/{appId}/domains/{domainName}
# operationId: UpdateDomainAssociation
# --subDomainSettings item shape: {prefix: any, branchName: any}
export def "apps-domains UpdateDomainAssociation" [
  appId: string
  domainName: string
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
  --enableAutoSubDomain: oneof<nothing, bool> #  Enables the automated creation of subdomains for branches. 
  --subDomainSettings: list #  Describes the settings for the subdomain.  — item shape: {prefix: any, branchName: any}
  --autoSubDomainCreationPatterns: list #  Sets the branch patterns for automatic subdomain creation. 
  --autoSubDomainIAMRole: string #  The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains. 
]: any -> record<domainAssociation: record<domainAssociationArn: record, domainName: record, enableAutoSubDomain: record, autoSubDomainCreationPatterns: record, autoSubDomainIAMRole: record, domainStatus: record, statusReason: record, certificateVerificationDNSRecord: record, subDomains: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/domains/($domainName)")
  let body = {enableAutoSubDomain: $enableAutoSubDomain, subDomainSettings: $subDomainSettings, autoSubDomainCreationPatterns: $autoSubDomainCreationPatterns, autoSubDomainIAMRole: $autoSubDomainIAMRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Deletes a job for a branch of an Amplify app. 
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}
# operationId: DeleteJob
export def "apps-branches-jobs DeleteJob" [
  appId: string
  branchName: string
  jobId: string
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
]: nothing -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs/($jobId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns a job for a branch of an Amplify app. 
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}
# operationId: GetJob
export def "apps-branches-jobs GetJob" [
  appId: string
  branchName: string
  jobId: string
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
]: nothing -> record<job: record<summary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>, steps: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs/($jobId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Deletes a webhook. 
#
# DELETE /webhooks/{webhookId}
# operationId: DeleteWebhook
export def "webhooks DeleteWebhook" [
  webhookId: string
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
]: nothing -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns the webhook information that corresponds to a specified webhook ID. 
#
# GET /webhooks/{webhookId}
# operationId: GetWebhook
export def "webhooks GetWebhook" [
  webhookId: string
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
]: nothing -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Updates a webhook. 
#
# POST /webhooks/{webhookId}
# operationId: UpdateWebhook
export def "webhooks UpdateWebhook" [
  webhookId: string
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
  --branchName: string #  The name for a branch that is part of an Amplify app. 
  --description: string #  The description for a webhook. 
]: any -> record<webhook: record<webhookArn: record, webhookId: record, webhookUrl: record, branchName: record, description: record, createTime: record, updateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {branchName: $branchName, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns the website access logs for a specific time range using a presigned URL. 
#
# POST /apps/{appId}/accesslogs
# operationId: GenerateAccessLogs
export def "apps-accesslogs GenerateAccessLogs" [
  appId: string
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
  --startTime: string #  The time at which the logs should start. The time range specified is inclusive of the start time.  (format: date-time)
  --endTime: string #  The time at which the logs should end. The time range specified is inclusive of the end time.  (format: date-time)
  domainName: string #  The name of the domain. 
]: any -> record<logUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/accesslogs")
  let body = {startTime: $startTime, endTime: $endTime, domainName: $domainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns the artifact info that corresponds to an artifact id. 
#
# GET /artifacts/{artifactId}
# operationId: GetArtifactUrl
export def "artifacts GetArtifactUrl" [
  artifactId: string
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
]: nothing -> record<artifactId: record, artifactUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($artifactId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns a list of artifacts for a specified app, branch, and job. 
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts
# operationId: ListArtifacts
export def "apps-branches-jobs-artifacts ListArtifacts" [
  appId: string
  branchName: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. Set to null to start listing artifacts from start. If a non-null pagination token is returned in a result, pass its value in here to list more artifacts. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<artifacts: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs/($jobId)/artifacts" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Lists the jobs for a branch of an Amplify app. 
#
# GET /apps/{appId}/branches/{branchName}/jobs
# operationId: ListJobs
export def "apps-branches-jobs ListJobs" [
  appId: string
  branchName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string #  A pagination token. Set to null to start listing steps from the start. If a non-null pagination token is returned in a result, pass its value in here to list more steps. 
  --maxResults: int #  The maximum number of records to list in a single response. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<jobSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Starts a new job for a branch of an Amplify app. 
#
# POST /apps/{appId}/branches/{branchName}/jobs
# operationId: StartJob
export def "apps-branches-jobs StartJob" [
  appId: string
  branchName: string
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
  --jobId: string #  The unique ID for an existing job. This is required if the value of <code>jobType</code> is <code>RETRY</code>. 
  jobType: string@jobType-completer #  Describes the type for the job. The job type <code>RELEASE</code> starts a new job with the latest change from the specified branch. This value is available only for apps that are connected to a repository. The job type <code>RETRY</code> retries an existing job. If the job type value is <code>RETRY</code>, the <code>jobId</code> is also required. 
  --jobReason: string #  A descriptive reason for starting this job. 
  --commitId: string #  The commit ID from a third-party repository provider for the job. 
  --commitMessage: string #  The commit message from a third-party repository provider for the job. 
  --commitTime: string #  The commit date and time for the job.  (format: date-time)
]: any -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs")
  let body = {jobId: $jobId, jobType: $jobType, jobReason: $jobReason, commitId: $commitId, commitMessage: $commitMessage, commitTime: $commitTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Returns a list of tags for a specified Amazon Resource Name (ARN). 
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags ListTagsForResource" [
  resourceArn: string
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resourceArn)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Tags the resource with a tag key and value. 
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags TagResource" [
  resourceArn: string
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
  tags: record #  The tags used to tag the resource. 
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resourceArn)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Starts a deployment for a manually deployed app. Manually deployed apps are not connected to a repository. 
#
# POST /apps/{appId}/branches/{branchName}/deployments/start
# operationId: StartDeployment
export def "apps-branches-deployments-start StartDeployment" [
  appId: string
  branchName: string
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
  --jobId: string #  The job ID for this deployment, generated by the create deployment request. 
  --sourceUrl: string #  The source URL for this deployment, used when calling start deployment without create deployment. The source URL can be any HTTP GET URL that is publicly accessible and downloads a single .zip file. 
]: any -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/deployments/start")
  let body = {jobId: $jobId, sourceUrl: $sourceUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Stops a job that is in progress for a branch of an Amplify app. 
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}/stop
# operationId: StopJob
export def "apps-branches-jobs-stop StopJob" [
  appId: string
  branchName: string
  jobId: string
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
]: nothing -> record<jobSummary: record<jobArn: record, jobId: record, commitId: record, commitMessage: record, commitTime: record, startTime: record, status: record, endTime: record, jobType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/branches/($branchName)/jobs/($jobId)/stop")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Untags a resource with a specified Amazon Resource Name (ARN). 
#
# DELETE /tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "tags UntagResource" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tagKeys: list #  The tag keys to use to untag a resource. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($resourceArn)#tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
