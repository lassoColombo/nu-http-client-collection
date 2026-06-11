# Auto-generated client for Cloud Build API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/cloudbuild/v1/openapi.json
# Auth: --token flag or $env.CLOUD_BUILD_API_TOKEN

const BASE_URL = "https://cloudbuild.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_BUILD_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://cloudbuild.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def eventType-completer [] { ["EVENT_TYPE_UNSPECIFIED" "MANUAL" "PUBSUB" "REPO" "WEBHOOK"] }
def includeBuildLogs-completer [] { ["INCLUDE_BUILD_LOGS_UNSPECIFIED" "INCLUDE_BUILD_LOGS_WITH_STATUS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "github-dot-com-webhook-receive cloudbuildgithubDotComWebhookreceive" } } | get name | first)
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

# ReceiveGitHubDotComWebhook is called when the API receives a github.com webhook.
#
# POST /v1/githubDotComWebhook:receive
# operationId: cloudbuild.githubDotComWebhook.receive
export def "github-dot-com-webhook-receive cloudbuildgithubDotComWebhookreceive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --webhookKey: string # For GitHub Enterprise webhooks, this key is used to associate the webhook request with the GitHubEnterpriseConfig to use for validation.
  --contentType: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "webhookKey" $webhookKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/githubDotComWebhook:receive" $qp)
  let body = {contentType: $contentType, data: $data, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists previously requested builds. Previously requested builds may still be in-progress, or may have finished successfully or unsuccessfully.
#
# GET /v1/projects/{projectId}/builds
# operationId: cloudbuild.projects.builds.list
export def "projects-builds cloudbuildprojectsbuildslist" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The raw filter text to constrain the results.
  --pageSize: int # Number of results to return in the list.
  --pageToken: string # The page token for the next page of Builds. If unspecified, the first page of results is returned. If the token is rejected for any reason, INVALID_ARGUMENT will be thrown. In this case, the token should be discarded, and pagination should be restarted from the first page of results. See https://google.aip.dev/158 for more.
  --parent: string # The parent of the collection of `Builds`. Format: `projects/{project}/locations/{location}`
]: nothing -> record<builds: table<approval: record, artifacts: record, availableSecrets: record, buildTriggerId: string, createTime: string, failureInfo: record, finishTime: string, id: string, images: list, logUrl: string, logsBucket: string, name: string, options: record, projectId: string, queueTtl: string, results: record, secrets: list, serviceAccount: string, source: record, sourceProvenance: record, startTime: string, status: string, statusDetail: string, steps: list, substitutions: record, tags: list, timeout: string, timing: record, warnings: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a build with the specified configuration. This method returns a long-running `Operation`, which includes the build ID. Pass the build ID to `GetBuild` to determine the build status (such as `SUCCESS` or `FAILURE`).
#
# POST /v1/projects/{projectId}/builds
# operationId: cloudbuild.projects.builds.create
# --approval shape: {config?: record, result?: record}
# --artifacts shape: {images?: list, mavenArtifacts?: list, npmPackages?: list, objects?: record, pythonPackages?: list}
# --availableSecrets shape: {inline?: list, secretManager?: list}
# --failureInfo shape: {detail?: string, type?: "FAILURE_TYPE_UNSPECIFIED"|"PUSH_FAILED"|"PUSH_IMAGE_NOT_FOUND"|"PUSH_NOT_AUTHORIZED"|"LOGGING_FAILURE"|"USER_BUILD_STEP"|"FETCH_SOURCE_FAILED"}
# --options shape: {defaultLogsBucketBehavior?: "DEFAULT_LOGS_BUCKET_BEHAVIOR_UNSPECIFIED"|"REGIONAL_USER_OWNED_BUCKET", diskSizeGb?: string, dynamicSubstitutions?: bool, env?: list, logStreamingOption?: "STREAM_DEFAULT"|"STREAM_ON"|"STREAM_OFF", logging?: "LOGGING_UNSPECIFIED"|"LEGACY"|"GCS_ONLY"|"STACKDRIVER_ONLY"|"CLOUD_LOGGING_ONLY"|"NONE", machineType?: "UNSPECIFIED"|"N1_HIGHCPU_8"|"N1_HIGHCPU_32"|"E2_HIGHCPU_8"|"E2_HIGHCPU_32", pool?: record, requestedVerifyOption?: "NOT_VERIFIED"|"VERIFIED", secretEnv?: list, sourceProvenanceHash?: list, substitutionOption?: "MUST_MATCH"|"ALLOW_LOOSE", volumes?: list, workerPool?: string}
# --results shape: {artifactManifest?: string, artifactTiming?: record, buildStepImages?: list, buildStepOutputs?: list, images?: list, mavenArtifacts?: list, npmPackages?: list, numArtifacts?: string, pythonPackages?: list}
# --secrets item shape: {kmsKeyName?: string, secretEnv?: record}
# --source shape: {gitSource?: record, repoSource?: record, storageSource?: record, storageSourceManifest?: record}
# --sourceProvenance shape: {resolvedRepoSource?: record, resolvedStorageSource?: record, resolvedStorageSourceManifest?: record}
# --steps item shape: {allowExitCodes?: list, allowFailure?: bool, args?: list, dir?: string, entrypoint?: string, env?: list, id?: string, name?: string, pullTiming?: record, script?: string, secretEnv?: list, timeout?: string, timing?: record, volumes?: list, waitFor?: list}
# --warnings item shape: {priority?: "PRIORITY_UNSPECIFIED"|"INFO"|"WARNING"|"ALERT", text?: string}
export def "projects-builds cloudbuildprojectsbuildscreate" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent resource where this build will be created. Format: `projects/{project}/locations/{location}`
  --approval: record # BuildApproval describes a build's approval configuration, state, and result. — shape: {config?: record, result?: record}
  --artifacts: record # Artifacts produced by a build that should be uploaded upon successful completion of all build steps. — shape: {images?: list, mavenArtifacts?: list, npmPackages?: list, objects?: record, pythonPackages?: list}
  --availableSecrets: record # Secrets and secret environment variables. — shape: {inline?: list, secretManager?: list}
  --failureInfo: record # A fatal problem encountered during the execution of the build. — shape: {detail?: string, type?: "FAILURE_TYPE_UNSPECIFIED"|"PUSH_FAILED"|"PUSH_IMAGE_NOT_FOUND"|"PUSH_NOT_AUTHORIZED"|"LOGGING_FAILURE"|"USER_BUILD_STEP"|"FETCH_SOURCE_FAILED"}
  --images: list # A list of images to be pushed upon the successful completion of all build steps. The images are pushed using the builder service account's credentials. The digests of the pushed images will be stored in the `Build` resource's results field. If any of the images fail to be pushed, the build status is marked `FAILURE`.
  --logsBucket: string # Google Cloud Storage bucket where logs should be written (see [Bucket Name Requirements](https://cloud.google.com/storage/docs/bucket-naming#requirements)). Logs file names will be of the format `${logs_bucket}/log-${build_id}.txt`.
  --options: record # Optional arguments to enable specific features of builds. — shape: {defaultLogsBucketBehavior?: "DEFAULT_LOGS_BUCKET_BEHAVIOR_UNSPECIFIED"|"REGIONAL_USER_OWNED_BUCKET", diskSizeGb?: string, dynamicSubstitutions?: bool, env?: list, logStreamingOption?: "STREAM_DEFAULT"|"STREAM_ON"|"STREAM_OFF", logging?: "LOGGING_UNSPECIFIED"|"LEGACY"|"GCS_ONLY"|"STACKDRIVER_ONLY"|"CLOUD_LOGGING_ONLY"|"NONE", machineType?: "UNSPECIFIED"|"N1_HIGHCPU_8"|"N1_HIGHCPU_32"|"E2_HIGHCPU_8"|"E2_HIGHCPU_32", pool?: record, requestedVerifyOption?: "NOT_VERIFIED"|"VERIFIED", secretEnv?: list, sourceProvenanceHash?: list, substitutionOption?: "MUST_MATCH"|"ALLOW_LOOSE", volumes?: list, workerPool?: string}
  --queueTtl: string # TTL in queue for this build. If provided and the build is enqueued longer than this value, the build will expire and the build status will be `EXPIRED`. The TTL starts ticking from create_time. (format: google-duration)
  --results: record # Artifacts created by the build pipeline. — shape: {artifactManifest?: string, artifactTiming?: record, buildStepImages?: list, buildStepOutputs?: list, images?: list, mavenArtifacts?: list, npmPackages?: list, numArtifacts?: string, pythonPackages?: list}
  --secrets: list # Secrets to decrypt using Cloud Key Management Service. Note: Secret Manager is the recommended technique for managing sensitive data with Cloud Build. Use `available_secrets` to configure builds to access secrets from Secret Manager. For instructions, see: https://cloud.google.com/cloud-build/docs/securing-builds/use-secrets — item shape: {kmsKeyName?: string, secretEnv?: record}
  --serviceAccount: string # IAM service account whose credentials will be used at build runtime. Must be of the format `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT}`. ACCOUNT can be email address or uniqueId of the service account. 
  --body-source: record # Location of the source in a supported storage service. — shape: {gitSource?: record, repoSource?: record, storageSource?: record, storageSourceManifest?: record}
  --sourceProvenance: record # Provenance of the source. Ways to find the original source, or verify that some source was used for this build. — shape: {resolvedRepoSource?: record, resolvedStorageSource?: record, resolvedStorageSourceManifest?: record}
  --steps: list # Required. The operations to be performed on the workspace. — item shape: {allowExitCodes?: list, allowFailure?: bool, args?: list, dir?: string, entrypoint?: string, env?: list, id?: string, name?: string, pullTiming?: record, script?: string, secretEnv?: list, timeout?: string, timing?: record, volumes?: list, waitFor?: list}
  --substitutions: record # Substitutions data for `Build` resource.
  --tags: list # Tags for annotation of a `Build`. These are not docker tags.
  --timeout: string # Amount of time that this build should be allowed to run, to second granularity. If this amount of time elapses, work on the build will cease and the build status will be `TIMEOUT`. `timeout` starts ticking from `startTime`. Default time is 60 minutes. (format: google-duration)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/builds" $qp)
  let body = {approval: $approval, artifacts: $artifacts, availableSecrets: $availableSecrets, failureInfo: $failureInfo, images: $images, logsBucket: $logsBucket, options: $options, queueTtl: $queueTtl, results: $results, secrets: $secrets, serviceAccount: $serviceAccount, source: $body_source, sourceProvenance: $sourceProvenance, steps: $steps, substitutions: $substitutions, tags: $tags, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns information about a previously requested build. The `Build` that is returned includes its status (such as `SUCCESS`, `FAILURE`, or `WORKING`), and timing information.
#
# GET /v1/projects/{projectId}/builds/{id}
# operationId: cloudbuild.projects.builds.get
export def "projects-builds cloudbuildprojectsbuildsget" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the `Build` to retrieve. Format: `projects/{project}/locations/{location}/builds/{build}`
]: nothing -> record<approval: record<config: record<approvalRequired: bool>, result: record<approvalTime: string, approverAccount: string, comment: string, decision: string, url: string>, state: string>, artifacts: record<images: list<string>, mavenArtifacts: list<record>, npmPackages: list<record>, objects: record<location: string, paths: list, timing: record>, pythonPackages: list<record>>, availableSecrets: record<inline: list<record>, secretManager: list<record>>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list<string>, logStreamingOption: string, logging: string, machineType: string, pool: record<name: string>, requestedVerifyOption: string, secretEnv: list<string>, sourceProvenanceHash: list<string>, substitutionOption: string, volumes: list<record>, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record<endTime: string, startTime: string>, buildStepImages: list<string>, buildStepOutputs: list<string>, images: list<record>, mavenArtifacts: list<record>, npmPackages: list<record>, numArtifacts: string, pythonPackages: list<record>>, secrets: table<kmsKeyName: string, secretEnv: record>, serviceAccount: string, source: record<gitSource: record<dir: string, revision: string, url: string>, repoSource: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, storageSource: record<bucket: string, generation: string, object: string>, storageSourceManifest: record<bucket: string, generation: string, object: string>>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, resolvedStorageSource: record<bucket: string, generation: string, object: string>, resolvedStorageSourceManifest: record<bucket: string, generation: string, object: string>>, startTime: string, status: string, statusDetail: string, steps: table<allowExitCodes: list, allowFailure: bool, args: list, dir: string, entrypoint: string, env: list, exitCode: int, id: string, name: string, pullTiming: record, script: string, secretEnv: list, status: string, timeout: string, timing: record, volumes: list, waitFor: list>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: table<priority: string, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/builds/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels a build in progress.
#
# POST /v1/projects/{projectId}/builds/{id}:cancel
# operationId: cloudbuild.projects.builds.cancel
export def "projects-builds cloudbuildprojectsbuildscancel" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-id: string # Required. ID of the build.
  --name: string # The name of the `Build` to cancel. Format: `projects/{project}/locations/{location}/builds/{build}`
  --body-projectId: string # Required. ID of the project.
]: any -> record<approval: record<config: record<approvalRequired: bool>, result: record<approvalTime: string, approverAccount: string, comment: string, decision: string, url: string>, state: string>, artifacts: record<images: list<string>, mavenArtifacts: list<record>, npmPackages: list<record>, objects: record<location: string, paths: list, timing: record>, pythonPackages: list<record>>, availableSecrets: record<inline: list<record>, secretManager: list<record>>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list<string>, logStreamingOption: string, logging: string, machineType: string, pool: record<name: string>, requestedVerifyOption: string, secretEnv: list<string>, sourceProvenanceHash: list<string>, substitutionOption: string, volumes: list<record>, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record<endTime: string, startTime: string>, buildStepImages: list<string>, buildStepOutputs: list<string>, images: list<record>, mavenArtifacts: list<record>, npmPackages: list<record>, numArtifacts: string, pythonPackages: list<record>>, secrets: table<kmsKeyName: string, secretEnv: record>, serviceAccount: string, source: record<gitSource: record<dir: string, revision: string, url: string>, repoSource: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, storageSource: record<bucket: string, generation: string, object: string>, storageSourceManifest: record<bucket: string, generation: string, object: string>>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, resolvedStorageSource: record<bucket: string, generation: string, object: string>, resolvedStorageSourceManifest: record<bucket: string, generation: string, object: string>>, startTime: string, status: string, statusDetail: string, steps: table<allowExitCodes: list, allowFailure: bool, args: list, dir: string, entrypoint: string, env: list, exitCode: int, id: string, name: string, pullTiming: record, script: string, secretEnv: list, status: string, timeout: string, timing: record, volumes: list, waitFor: list>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: table<priority: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/builds/($id):cancel" $qp)
  let body = {id: $body_id, name: $name, projectId: $body_projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new build based on the specified build. This method creates a new build using the original build request, which may or may not result in an identical build. For triggered builds: * Triggered builds resolve to a precise revision; therefore a retry of a triggered build will result in a build that uses the same revision. For non-triggered builds that specify `RepoSource`: * If the original build built from the tip of a branch, the retried build will build from the tip of that branch, which may not be the same revision as the original build. * If the original build specified a commit sha or revision ID, the retried build will use the identical source. For builds that specify `StorageSource`: * If the original build pulled source from Google Cloud Storage without specifying the generation of the object, the new build will use the current object, which may be different from the original build source. * If the original build pulled source from Cloud Storage and specified the generation of the object, the new build will attempt to use the same object, which may or may not be available depending on the bucket's lifecycle management settings.
#
# POST /v1/projects/{projectId}/builds/{id}:retry
# operationId: cloudbuild.projects.builds.retry
export def "projects-builds cloudbuildprojectsbuildsretry" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-id: string # Required. Build ID of the original build.
  --name: string # The name of the `Build` to retry. Format: `projects/{project}/locations/{location}/builds/{build}`
  --body-projectId: string # Required. ID of the project.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/builds/($id):retry" $qp)
  let body = {id: $body_id, name: $name, projectId: $body_projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists existing `BuildTrigger`s. This API is experimental.
#
# GET /v1/projects/{projectId}/triggers
# operationId: cloudbuild.projects.triggers.list
export def "projects-triggers cloudbuildprojectstriggerslist" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Number of results to return in the list.
  --pageToken: string # Token to provide to skip to a particular spot in the list.
  --parent: string # The parent of the collection of `Triggers`. Format: `projects/{project}/locations/{location}`
]: nothing -> record<nextPageToken: string, triggers: table<approvalConfig: record, autodetect: bool, bitbucketServerTriggerConfig: record, build: record, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record, github: record, gitlabEnterpriseEventsConfig: record, id: string, ignoredFiles: list, includeBuildLogs: string, includedFiles: list, name: string, pubsubConfig: record, repositoryEventConfig: record, resourceName: string, serviceAccount: string, sourceToBuild: record, substitutions: record, tags: list, triggerTemplate: record, webhookConfig: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new `BuildTrigger`. This API is experimental.
#
# POST /v1/projects/{projectId}/triggers
# operationId: cloudbuild.projects.triggers.create
# --approvalConfig shape: {approvalRequired?: bool}
# --bitbucketServerTriggerConfig shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
# --build shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
# --gitFileSource shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
# --github shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
# --gitlabEnterpriseEventsConfig shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
# --pubsubConfig shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
# --repositoryEventConfig shape: {pullRequest?: record, push?: record, repository?: string}
# --sourceToBuild shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
# --triggerTemplate shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
# --webhookConfig shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
export def "projects-triggers cloudbuildprojectstriggerscreate" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent resource where this trigger will be created. Format: `projects/{project}/locations/{location}`
  --approvalConfig: record # ApprovalConfig describes configuration for manual approval of a build. — shape: {approvalRequired?: bool}
  --autodetect: string@bool-completer # Autodetect build configuration. The following precedence is used (case insensitive): 1. cloudbuild.yaml 2. cloudbuild.yml 3. cloudbuild.json 4. Dockerfile Currently only available for GitHub App Triggers.
  --bitbucketServerTriggerConfig: record # BitbucketServerTriggerConfig describes the configuration of a trigger that creates a build whenever a Bitbucket Server event is received. — shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
  --build: record # A build resource in the Cloud Build API. At a high level, a `Build` describes where to find source code, how to build it (for example, the builder image to run on the source), and where to store the built artifacts. Fields can include the following variables, which will be expanded when the build is created: - $PROJECT_ID: the project ID of the build. - $PROJECT_NUMBER: the project number of the build. - $LOCATION: the location/region of the build. - $BUILD_ID: the autogenerated ID of the build. - $REPO_NAME: the source repository name specified by RepoSource. - $BRANCH_NAME: the branch name specified by RepoSource. - $TAG_NAME: the tag name specified by RepoSource. - $REVISION_ID or $COMMIT_SHA: the commit SHA specified by RepoSource or resolved from the specified branch or tag. - $SHORT_SHA: first 7 characters of $REVISION_ID or $COMMIT_SHA. — shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
  --description: string # Human-readable description of this trigger.
  --disabled: string@bool-completer # If true, the trigger will never automatically execute a build.
  --eventType: string@eventType-completer # EventType allows the user to explicitly set the type of event to which this BuildTrigger should respond. This field will be validated against the rest of the configuration if it is set.
  --filename: string # Path, from the source root, to the build configuration file (i.e. cloudbuild.yaml).
  --filter: string # A Common Expression Language string.
  --gitFileSource: record # GitFileSource describes a file within a (possibly remote) code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
  --github: record # GitHubEventsConfig describes the configuration of a trigger that creates a build whenever a GitHub event is received. — shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
  --gitlabEnterpriseEventsConfig: record # GitLabEventsConfig describes the configuration of a trigger that creates a build whenever a GitLab event is received. — shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
  --ignoredFiles: list # ignored_files and included_files are file glob matches using https://golang.org/pkg/path/filepath/#Match extended with support for "**". If ignored_files and changed files are both empty, then they are not used to determine whether or not to trigger a build. If ignored_files is not empty, then we ignore any files that match any of the ignored_file globs. If the change has no files that are outside of the ignored_files globs, then we do not trigger a build.
  --includeBuildLogs: string@includeBuildLogs-completer # If set to INCLUDE_BUILD_LOGS_WITH_STATUS, log url will be shown on GitHub page when build status is final. Setting this field to INCLUDE_BUILD_LOGS_WITH_STATUS for non GitHub triggers results in INVALID_ARGUMENT error.
  --includedFiles: list # If any of the files altered in the commit pass the ignored_files filter and included_files is empty, then as far as this filter is concerned, we should trigger the build. If any of the files altered in the commit pass the ignored_files filter and included_files is not empty, then we make sure that at least one of those files matches a included_files glob. If not, then we do not trigger a build.
  --name: string # User-assigned name of the trigger. Must be unique within the project. Trigger names must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character.
  --pubsubConfig: record # PubsubConfig describes the configuration of a trigger that creates a build whenever a Pub/Sub message is published. — shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
  --repositoryEventConfig: record # The configuration of a trigger that creates a build whenever an event from Repo API is received. — shape: {pullRequest?: record, push?: record, repository?: string}
  --resourceName: string # The `Trigger` name with format: `projects/{project}/locations/{location}/triggers/{trigger}`, where {trigger} is a unique identifier generated by the service.
  --serviceAccount: string # The service account used for all user-controlled operations including UpdateBuildTrigger, RunBuildTrigger, CreateBuild, and CancelBuild. If no service account is set, then the standard Cloud Build service account ([PROJECT_NUM]@system.gserviceaccount.com) will be used instead. Format: `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT_ID_OR_EMAIL}`
  --sourceToBuild: record # GitRepoSource describes a repo and ref of a code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
  --substitutions: record # Substitutions for Build resource. The keys must match the following regular expression: `^_[A-Z0-9_]+$`.
  --tags: list # Tags for annotation of a `BuildTrigger`
  --triggerTemplate: record # Location of the source in a Google Cloud Source Repository. — shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
  --webhookConfig: record # WebhookConfig describes the configuration of a trigger that creates a build whenever a webhook is sent to a trigger's webhook URL. — shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
]: any -> record<approvalConfig: record<approvalRequired: bool>, autodetect: bool, bitbucketServerTriggerConfig: record<bitbucketServerConfig: record<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, bitbucketServerConfigResource: string, projectKey: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repoSlug: string>, build: record<approval: record<config: record, result: record, state: string>, artifacts: record<images: list, mavenArtifacts: list, npmPackages: list, objects: record, pythonPackages: list>, availableSecrets: record<inline: list, secretManager: list>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list, logStreamingOption: string, logging: string, machineType: string, pool: record, requestedVerifyOption: string, secretEnv: list, sourceProvenanceHash: list, substitutionOption: string, volumes: list, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record, buildStepImages: list, buildStepOutputs: list, images: list, mavenArtifacts: list, npmPackages: list, numArtifacts: string, pythonPackages: list>, secrets: list<record>, serviceAccount: string, source: record<gitSource: record, repoSource: record, storageSource: record, storageSourceManifest: record>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record, resolvedStorageSource: record, resolvedStorageSourceManifest: record>, startTime: string, status: string, statusDetail: string, steps: list<record>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: list<record>>, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, path: string, repoType: string, revision: string, uri: string>, github: record<enterpriseConfigResourceName: string, installationId: string, name: string, owner: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, gitlabEnterpriseEventsConfig: record<gitlabConfig: record<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, gitlabConfigResource: string, projectNamespace: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, id: string, ignoredFiles: list<string>, includeBuildLogs: string, includedFiles: list<string>, name: string, pubsubConfig: record<serviceAccountEmail: string, state: string, subscription: string, topic: string>, repositoryEventConfig: record<pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repository: string, repositoryType: string>, resourceName: string, serviceAccount: string, sourceToBuild: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, ref: string, repoType: string, uri: string>, substitutions: record, tags: list<string>, triggerTemplate: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, webhookConfig: record<secret: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers" $qp)
  let body = {approvalConfig: $approvalConfig, autodetect: $autodetect, bitbucketServerTriggerConfig: $bitbucketServerTriggerConfig, build: $build, description: $description, disabled: $disabled, eventType: $eventType, filename: $filename, filter: $filter, gitFileSource: $gitFileSource, github: $github, gitlabEnterpriseEventsConfig: $gitlabEnterpriseEventsConfig, ignoredFiles: $ignoredFiles, includeBuildLogs: $includeBuildLogs, includedFiles: $includedFiles, name: $name, pubsubConfig: $pubsubConfig, repositoryEventConfig: $repositoryEventConfig, resourceName: $resourceName, serviceAccount: $serviceAccount, sourceToBuild: $sourceToBuild, substitutions: $substitutions, tags: $tags, triggerTemplate: $triggerTemplate, webhookConfig: $webhookConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a `BuildTrigger` by its project ID and trigger ID. This API is experimental.
#
# DELETE /v1/projects/{projectId}/triggers/{triggerId}
# operationId: cloudbuild.projects.triggers.delete
export def "projects-triggers cloudbuildprojectstriggersdelete" [
  projectId: string
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the `Trigger` to delete. Format: `projects/{project}/locations/{location}/triggers/{trigger}`
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers/($triggerId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a `BuildTrigger`. This API is experimental.
#
# GET /v1/projects/{projectId}/triggers/{triggerId}
# operationId: cloudbuild.projects.triggers.get
export def "projects-triggers cloudbuildprojectstriggersget" [
  projectId: string
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the `Trigger` to retrieve. Format: `projects/{project}/locations/{location}/triggers/{trigger}`
]: nothing -> record<approvalConfig: record<approvalRequired: bool>, autodetect: bool, bitbucketServerTriggerConfig: record<bitbucketServerConfig: record<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, bitbucketServerConfigResource: string, projectKey: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repoSlug: string>, build: record<approval: record<config: record, result: record, state: string>, artifacts: record<images: list, mavenArtifacts: list, npmPackages: list, objects: record, pythonPackages: list>, availableSecrets: record<inline: list, secretManager: list>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list, logStreamingOption: string, logging: string, machineType: string, pool: record, requestedVerifyOption: string, secretEnv: list, sourceProvenanceHash: list, substitutionOption: string, volumes: list, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record, buildStepImages: list, buildStepOutputs: list, images: list, mavenArtifacts: list, npmPackages: list, numArtifacts: string, pythonPackages: list>, secrets: list<record>, serviceAccount: string, source: record<gitSource: record, repoSource: record, storageSource: record, storageSourceManifest: record>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record, resolvedStorageSource: record, resolvedStorageSourceManifest: record>, startTime: string, status: string, statusDetail: string, steps: list<record>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: list<record>>, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, path: string, repoType: string, revision: string, uri: string>, github: record<enterpriseConfigResourceName: string, installationId: string, name: string, owner: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, gitlabEnterpriseEventsConfig: record<gitlabConfig: record<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, gitlabConfigResource: string, projectNamespace: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, id: string, ignoredFiles: list<string>, includeBuildLogs: string, includedFiles: list<string>, name: string, pubsubConfig: record<serviceAccountEmail: string, state: string, subscription: string, topic: string>, repositoryEventConfig: record<pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repository: string, repositoryType: string>, resourceName: string, serviceAccount: string, sourceToBuild: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, ref: string, repoType: string, uri: string>, substitutions: record, tags: list<string>, triggerTemplate: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, webhookConfig: record<secret: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers/($triggerId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a `BuildTrigger` by its project ID and trigger ID. This API is experimental.
#
# PATCH /v1/projects/{projectId}/triggers/{triggerId}
# operationId: cloudbuild.projects.triggers.patch
# --approvalConfig shape: {approvalRequired?: bool}
# --bitbucketServerTriggerConfig shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
# --build shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
# --gitFileSource shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
# --github shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
# --gitlabEnterpriseEventsConfig shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
# --pubsubConfig shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
# --repositoryEventConfig shape: {pullRequest?: record, push?: record, repository?: string}
# --sourceToBuild shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
# --triggerTemplate shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
# --webhookConfig shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
export def "projects-triggers cloudbuildprojectstriggerspatch" [
  projectId: string
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --approvalConfig: record # ApprovalConfig describes configuration for manual approval of a build. — shape: {approvalRequired?: bool}
  --autodetect: string@bool-completer # Autodetect build configuration. The following precedence is used (case insensitive): 1. cloudbuild.yaml 2. cloudbuild.yml 3. cloudbuild.json 4. Dockerfile Currently only available for GitHub App Triggers.
  --bitbucketServerTriggerConfig: record # BitbucketServerTriggerConfig describes the configuration of a trigger that creates a build whenever a Bitbucket Server event is received. — shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
  --build: record # A build resource in the Cloud Build API. At a high level, a `Build` describes where to find source code, how to build it (for example, the builder image to run on the source), and where to store the built artifacts. Fields can include the following variables, which will be expanded when the build is created: - $PROJECT_ID: the project ID of the build. - $PROJECT_NUMBER: the project number of the build. - $LOCATION: the location/region of the build. - $BUILD_ID: the autogenerated ID of the build. - $REPO_NAME: the source repository name specified by RepoSource. - $BRANCH_NAME: the branch name specified by RepoSource. - $TAG_NAME: the tag name specified by RepoSource. - $REVISION_ID or $COMMIT_SHA: the commit SHA specified by RepoSource or resolved from the specified branch or tag. - $SHORT_SHA: first 7 characters of $REVISION_ID or $COMMIT_SHA. — shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
  --description: string # Human-readable description of this trigger.
  --disabled: string@bool-completer # If true, the trigger will never automatically execute a build.
  --eventType: string@eventType-completer # EventType allows the user to explicitly set the type of event to which this BuildTrigger should respond. This field will be validated against the rest of the configuration if it is set.
  --filename: string # Path, from the source root, to the build configuration file (i.e. cloudbuild.yaml).
  --filter: string # A Common Expression Language string.
  --gitFileSource: record # GitFileSource describes a file within a (possibly remote) code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
  --github: record # GitHubEventsConfig describes the configuration of a trigger that creates a build whenever a GitHub event is received. — shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
  --gitlabEnterpriseEventsConfig: record # GitLabEventsConfig describes the configuration of a trigger that creates a build whenever a GitLab event is received. — shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
  --ignoredFiles: list # ignored_files and included_files are file glob matches using https://golang.org/pkg/path/filepath/#Match extended with support for "**". If ignored_files and changed files are both empty, then they are not used to determine whether or not to trigger a build. If ignored_files is not empty, then we ignore any files that match any of the ignored_file globs. If the change has no files that are outside of the ignored_files globs, then we do not trigger a build.
  --includeBuildLogs: string@includeBuildLogs-completer # If set to INCLUDE_BUILD_LOGS_WITH_STATUS, log url will be shown on GitHub page when build status is final. Setting this field to INCLUDE_BUILD_LOGS_WITH_STATUS for non GitHub triggers results in INVALID_ARGUMENT error.
  --includedFiles: list # If any of the files altered in the commit pass the ignored_files filter and included_files is empty, then as far as this filter is concerned, we should trigger the build. If any of the files altered in the commit pass the ignored_files filter and included_files is not empty, then we make sure that at least one of those files matches a included_files glob. If not, then we do not trigger a build.
  --name: string # User-assigned name of the trigger. Must be unique within the project. Trigger names must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character.
  --pubsubConfig: record # PubsubConfig describes the configuration of a trigger that creates a build whenever a Pub/Sub message is published. — shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
  --repositoryEventConfig: record # The configuration of a trigger that creates a build whenever an event from Repo API is received. — shape: {pullRequest?: record, push?: record, repository?: string}
  --resourceName: string # The `Trigger` name with format: `projects/{project}/locations/{location}/triggers/{trigger}`, where {trigger} is a unique identifier generated by the service.
  --serviceAccount: string # The service account used for all user-controlled operations including UpdateBuildTrigger, RunBuildTrigger, CreateBuild, and CancelBuild. If no service account is set, then the standard Cloud Build service account ([PROJECT_NUM]@system.gserviceaccount.com) will be used instead. Format: `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT_ID_OR_EMAIL}`
  --sourceToBuild: record # GitRepoSource describes a repo and ref of a code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
  --substitutions: record # Substitutions for Build resource. The keys must match the following regular expression: `^_[A-Z0-9_]+$`.
  --tags: list # Tags for annotation of a `BuildTrigger`
  --triggerTemplate: record # Location of the source in a Google Cloud Source Repository. — shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
  --webhookConfig: record # WebhookConfig describes the configuration of a trigger that creates a build whenever a webhook is sent to a trigger's webhook URL. — shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
]: any -> record<approvalConfig: record<approvalRequired: bool>, autodetect: bool, bitbucketServerTriggerConfig: record<bitbucketServerConfig: record<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, bitbucketServerConfigResource: string, projectKey: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repoSlug: string>, build: record<approval: record<config: record, result: record, state: string>, artifacts: record<images: list, mavenArtifacts: list, npmPackages: list, objects: record, pythonPackages: list>, availableSecrets: record<inline: list, secretManager: list>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list, logStreamingOption: string, logging: string, machineType: string, pool: record, requestedVerifyOption: string, secretEnv: list, sourceProvenanceHash: list, substitutionOption: string, volumes: list, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record, buildStepImages: list, buildStepOutputs: list, images: list, mavenArtifacts: list, npmPackages: list, numArtifacts: string, pythonPackages: list>, secrets: list<record>, serviceAccount: string, source: record<gitSource: record, repoSource: record, storageSource: record, storageSourceManifest: record>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record, resolvedStorageSource: record, resolvedStorageSourceManifest: record>, startTime: string, status: string, statusDetail: string, steps: list<record>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: list<record>>, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, path: string, repoType: string, revision: string, uri: string>, github: record<enterpriseConfigResourceName: string, installationId: string, name: string, owner: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, gitlabEnterpriseEventsConfig: record<gitlabConfig: record<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, gitlabConfigResource: string, projectNamespace: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, id: string, ignoredFiles: list<string>, includeBuildLogs: string, includedFiles: list<string>, name: string, pubsubConfig: record<serviceAccountEmail: string, state: string, subscription: string, topic: string>, repositoryEventConfig: record<pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repository: string, repositoryType: string>, resourceName: string, serviceAccount: string, sourceToBuild: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, ref: string, repoType: string, uri: string>, substitutions: record, tags: list<string>, triggerTemplate: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, webhookConfig: record<secret: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers/($triggerId)" $qp)
  let body = {approvalConfig: $approvalConfig, autodetect: $autodetect, bitbucketServerTriggerConfig: $bitbucketServerTriggerConfig, build: $build, description: $description, disabled: $disabled, eventType: $eventType, filename: $filename, filter: $filter, gitFileSource: $gitFileSource, github: $github, gitlabEnterpriseEventsConfig: $gitlabEnterpriseEventsConfig, ignoredFiles: $ignoredFiles, includeBuildLogs: $includeBuildLogs, includedFiles: $includedFiles, name: $name, pubsubConfig: $pubsubConfig, repositoryEventConfig: $repositoryEventConfig, resourceName: $resourceName, serviceAccount: $serviceAccount, sourceToBuild: $sourceToBuild, substitutions: $substitutions, tags: $tags, triggerTemplate: $triggerTemplate, webhookConfig: $webhookConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Runs a `BuildTrigger` at a particular source revision. To run a regional or global trigger, use the POST request that includes the location endpoint in the path (ex. v1/projects/{projectId}/locations/{region}/triggers/{triggerId}:run). The POST request that does not include the location endpoint in the path can only be used when running global triggers.
#
# POST /v1/projects/{projectId}/triggers/{triggerId}:run
# operationId: cloudbuild.projects.triggers.run
export def "projects-triggers cloudbuildprojectstriggersrun" [
  projectId: string
  triggerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the `Trigger` to run. Format: `projects/{project}/locations/{location}/triggers/{trigger}`
  --branchName: string # Regex matching branches to build. The syntax of the regular expressions accepted is the syntax accepted by RE2 and described at https://github.com/google/re2/wiki/Syntax
  --commitSha: string # Explicit commit SHA to build.
  --dir: string # Directory, relative to the source root, in which to run the build. This must be a relative path. If a step's `dir` is specified and is an absolute path, this value is ignored for that step's execution.
  --invertRegex: string@bool-completer # Only trigger a build if the revision regex does NOT match the revision regex.
  --body-projectId: string # ID of the project that owns the Cloud Source Repository. If omitted, the project ID requesting the build is assumed.
  --repoName: string # Name of the Cloud Source Repository.
  --substitutions: record # Substitutions to use in a triggered build. Should only be used with RunBuildTrigger
  --tagName: string # Regex matching tags to build. The syntax of the regular expressions accepted is the syntax accepted by RE2 and described at https://github.com/google/re2/wiki/Syntax
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers/($triggerId):run" $qp)
  let body = {branchName: $branchName, commitSha: $commitSha, dir: $dir, invertRegex: $invertRegex, projectId: $body_projectId, repoName: $repoName, substitutions: $substitutions, tagName: $tagName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ReceiveTriggerWebhook [Experimental] is called when the API receives a webhook request targeted at a specific trigger.
#
# POST /v1/projects/{projectId}/triggers/{trigger}:webhook
# operationId: cloudbuild.projects.triggers.webhook
export def "projects-triggers cloudbuildprojectstriggerswebhook" [
  projectId: string
  trigger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the `ReceiveTriggerWebhook` to retrieve. Format: `projects/{project}/locations/{location}/triggers/{trigger}`
  --secret: string # Secret token used for authorization if an OAuth token isn't provided.
  --contentType: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "secret" $secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/triggers/($trigger):webhook" $qp)
  let body = {contentType: $contentType, data: $data, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ReceiveWebhook is called when the API receives a GitHub webhook.
#
# POST /v1/webhook
# operationId: cloudbuild.webhook
export def "webhook cloudbuildwebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --webhookKey: string # For GitHub Enterprise webhooks, this key is used to associate the webhook request with the GitHubEnterpriseConfig to use for validation.
  --contentType: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "webhookKey" $webhookKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhook" $qp)
  let body = {contentType: $contentType, data: $data, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a Bitbucket Server repository from a given BitbucketServerConfig's connected repositories. This API is experimental.
#
# POST /v1/{config}:removeBitbucketServerConnectedRepository
# operationId: cloudbuild.projects.locations.bitbucketServerConfigs.removeBitbucketServerConnectedRepository
# --connectedRepository shape: {projectKey?: string, repoSlug?: string}
export def "projects cloudbuildprojectslocationsbitbucketServerConfigsremoveBitbucketServerConnectedRepository" [
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --connectedRepository: record # BitbucketServerRepositoryId identifies a specific repository hosted on a Bitbucket Server. — shape: {projectKey?: string, repoSlug?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($config):removeBitbucketServerConnectedRepository" $qp)
  let body = {connectedRepository: $connectedRepository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a GitLab repository from a given GitLabConfig's connected repositories. This API is experimental.
#
# POST /v1/{config}:removeGitLabConnectedRepository
# operationId: cloudbuild.projects.locations.gitLabConfigs.removeGitLabConnectedRepository
# --connectedRepository shape: {id?: string}
export def "projects cloudbuildprojectslocationsgitLabConfigsremoveGitLabConnectedRepository" [
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --connectedRepository: record # GitLabRepositoryId identifies a specific repository hosted on GitLab.com or GitLabEnterprise — shape: {id?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($config):removeGitLabConnectedRepository" $qp)
  let body = {connectedRepository: $connectedRepository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ReceiveRegionalWebhook is called when the API receives a regional GitHub webhook.
#
# POST /v1/{location}/regionalWebhook
# operationId: cloudbuild.locations.regionalWebhook
export def "regional-webhook cloudbuildlocationsregionalWebhook" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --webhookKey: string # For GitHub Enterprise webhooks, this key is used to associate the webhook request with the GitHubEnterpriseConfig to use for validation.
  --contentType: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "webhookKey" $webhookKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($location)/regionalWebhook" $qp)
  let body = {contentType: $contentType, data: $data, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a `WorkerPool`.
#
# DELETE /v1/{name}
# operationId: cloudbuild.projects.locations.workerPools.delete
export def "projects cloudbuildprojectslocationsworkerPoolsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowMissing: string@bool-completer # If set to true, and the `WorkerPool` is not found, the request will succeed but no action will be taken on the server.
  --etag: string # Optional. If provided, it must match the server's etag on the workerpool for the request to be processed.
  --validateOnly: string@bool-completer # If set, validate the request and preview the response, but do not actually post it.
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowMissing" $allowMissing "scalar") (serialize-qp "etag" $etag "scalar") (serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details of a `WorkerPool`.
#
# GET /v1/{name}
# operationId: cloudbuild.projects.locations.workerPools.get
export def "projects cloudbuildprojectslocationsworkerPoolsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Required. ID of the project that owns the trigger.
  --triggerId: string # Required. Identifier (`id` or `name`) of the `BuildTrigger` to get.
]: nothing -> record<annotations: record, createTime: string, deleteTime: string, displayName: string, etag: string, name: string, privatePoolV1Config: record<networkConfig: record<egressOption: string, peeredNetwork: string, peeredNetworkIpRange: string>, workerConfig: record<diskSizeGb: string, machineType: string>>, state: string, uid: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "triggerId" $triggerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a `WorkerPool`.
#
# PATCH /v1/{name}
# operationId: cloudbuild.projects.locations.workerPools.patch
# --privatePoolV1Config shape: {networkConfig?: record, workerConfig?: record}
export def "projects cloudbuildprojectslocationsworkerPoolspatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # A mask specifying which fields in `worker_pool` to update.
  --validateOnly: string@bool-completer # If set, validate the request and preview the response, but do not actually post it.
  --annotations: record # User specified annotations. See https://google.aip.dev/128#annotations for more details such as format and size limitations.
  --displayName: string # A user-specified, human-readable name for the `WorkerPool`. If provided, this value must be 1-63 characters.
  --privatePoolV1Config: record # Configuration for a V1 `PrivatePool`. — shape: {networkConfig?: record, workerConfig?: record}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar") (serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let body = {annotations: $annotations, displayName: $displayName, privatePoolV1Config: $privatePoolV1Config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Approves or rejects a pending build. If approved, the returned LRO will be analogous to the LRO returned from a CreateBuild call. If rejected, the returned LRO will be immediately done.
#
# POST /v1/{name}:approve
# operationId: cloudbuild.projects.locations.builds.approve
# --approvalResult shape: {comment?: string, decision?: "DECISION_UNSPECIFIED"|"APPROVED"|"REJECTED", url?: string}
export def "projects cloudbuildprojectslocationsbuildsapprove" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --approvalResult: record # ApprovalResult describes the decision and associated metadata of a manual approval of a build. — shape: {comment?: string, decision?: "DECISION_UNSPECIFIED"|"APPROVED"|"REJECTED", url?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):approve" $qp)
  let body = {approvalResult: $approvalResult} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1/{name}:cancel
# operationId: cloudbuild.projects.locations.operations.cancel
export def "projects cloudbuildprojectslocationsoperationscancel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):cancel" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new build based on the specified build. This method creates a new build using the original build request, which may or may not result in an identical build. For triggered builds: * Triggered builds resolve to a precise revision; therefore a retry of a triggered build will result in a build that uses the same revision. For non-triggered builds that specify `RepoSource`: * If the original build built from the tip of a branch, the retried build will build from the tip of that branch, which may not be the same revision as the original build. * If the original build specified a commit sha or revision ID, the retried build will use the identical source. For builds that specify `StorageSource`: * If the original build pulled source from Google Cloud Storage without specifying the generation of the object, the new build will use the current object, which may be different from the original build source. * If the original build pulled source from Cloud Storage and specified the generation of the object, the new build will attempt to use the same object, which may or may not be available depending on the bucket's lifecycle management settings.
#
# POST /v1/{name}:retry
# operationId: cloudbuild.projects.locations.builds.retry
export def "projects cloudbuildprojectslocationsbuildsretry" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --id: string # Required. Build ID of the original build.
  --body-name: string # The name of the `Build` to retry. Format: `projects/{project}/locations/{location}/builds/{build}`
  --projectId: string # Required. ID of the project.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):retry" $qp)
  let body = {id: $id, name: $body_name, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Runs a `BuildTrigger` at a particular source revision. To run a regional or global trigger, use the POST request that includes the location endpoint in the path (ex. v1/projects/{projectId}/locations/{region}/triggers/{triggerId}:run). The POST request that does not include the location endpoint in the path can only be used when running global triggers.
#
# POST /v1/{name}:run
# operationId: cloudbuild.projects.locations.triggers.run
# --source shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
export def "projects cloudbuildprojectslocationstriggersrun" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Required. ID of the project.
  --body-source: record # Location of the source in a Google Cloud Source Repository. — shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
  --triggerId: string # Required. ID of the trigger.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):run" $qp)
  let body = {projectId: $projectId, source: $body_source, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ReceiveTriggerWebhook [Experimental] is called when the API receives a webhook request targeted at a specific trigger.
#
# POST /v1/{name}:webhook
# operationId: cloudbuild.projects.locations.triggers.webhook
export def "projects cloudbuildprojectslocationstriggerswebhook" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Project in which the specified trigger lives
  --secret: string # Secret token used for authorization if an OAuth token isn't provided.
  --trigger: string # Name of the trigger to run the payload against
  --contentType: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "secret" $secret "scalar") (serialize-qp "trigger" $trigger "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):webhook" $qp)
  let body = {contentType: $contentType, data: $data, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all `BitbucketServerConfigs` for a given project. This API is experimental.
#
# GET /v1/{parent}/bitbucketServerConfigs
# operationId: cloudbuild.projects.locations.bitbucketServerConfigs.list
export def "bitbucket-server-configs cloudbuildprojectslocationsbitbucketServerConfigslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # The maximum number of configs to return. The service may return fewer than this value. If unspecified, at most 50 configs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --pageToken: string # A page token, received from a previous `ListBitbucketServerConfigsRequest` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListBitbucketServerConfigsRequest` must match the call that provided the page token.
]: nothing -> record<bitbucketServerConfigs: table<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/bitbucketServerConfigs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new `BitbucketServerConfig`. This API is experimental.
#
# POST /v1/{parent}/bitbucketServerConfigs
# operationId: cloudbuild.projects.locations.bitbucketServerConfigs.create
# --connectedRepositories item shape: {projectKey?: string, repoSlug?: string}
# --secrets shape: {adminAccessTokenVersionName?: string, readAccessTokenVersionName?: string, webhookSecretVersionName?: string}
export def "bitbucket-server-configs cloudbuildprojectslocationsbitbucketServerConfigscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --bitbucketServerConfigId: string # Optional. The ID to use for the BitbucketServerConfig, which will become the final component of the BitbucketServerConfig's resource name. bitbucket_server_config_id must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character.
  --apiKey: string # Required. Immutable. API Key that will be attached to webhook. Once this field has been set, it cannot be changed. If you need to change it, please create another BitbucketServerConfig.
  --createTime: string # Time when the config was created. (format: google-datetime)
  --hostUri: string # Required. Immutable. The URI of the Bitbucket Server host. Once this field has been set, it cannot be changed. If you need to change it, please create another BitbucketServerConfig.
  --name: string # The resource name for the config.
  --peeredNetwork: string # Optional. The network to be used when reaching out to the Bitbucket Server instance. The VPC network must be enabled for private service connection. This should be set if the Bitbucket Server instance is hosted on-premises and not reachable by public internet. If this field is left empty, no network peering will occur and calls to the Bitbucket Server instance will be made over the public internet. Must be in the format `projects/{project}/global/networks/{network}`, where {project} is a project number or id and {network} is the name of a VPC network in the project.
  --secrets: record # BitbucketServerSecrets represents the secrets in Secret Manager for a Bitbucket Server. — shape: {adminAccessTokenVersionName?: string, readAccessTokenVersionName?: string, webhookSecretVersionName?: string}
  --sslCa: string # Optional. SSL certificate to use for requests to Bitbucket Server. The format should be PEM format but the extension can be one of .pem, .cer, or .crt.
  --username: string # Username of the account Cloud Build will use on Bitbucket Server.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "bitbucketServerConfigId" $bitbucketServerConfigId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/bitbucketServerConfigs" $qp)
  let body = {apiKey: $apiKey, createTime: $createTime, hostUri: $hostUri, name: $name, peeredNetwork: $peeredNetwork, secrets: $secrets, sslCa: $sslCa, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists previously requested builds. Previously requested builds may still be in-progress, or may have finished successfully or unsuccessfully.
#
# GET /v1/{parent}/builds
# operationId: cloudbuild.projects.locations.builds.list
export def "builds cloudbuildprojectslocationsbuildslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The raw filter text to constrain the results.
  --pageSize: int # Number of results to return in the list.
  --pageToken: string # The page token for the next page of Builds. If unspecified, the first page of results is returned. If the token is rejected for any reason, INVALID_ARGUMENT will be thrown. In this case, the token should be discarded, and pagination should be restarted from the first page of results. See https://google.aip.dev/158 for more.
  --projectId: string # Required. ID of the project.
]: nothing -> record<builds: table<approval: record, artifacts: record, availableSecrets: record, buildTriggerId: string, createTime: string, failureInfo: record, finishTime: string, id: string, images: list, logUrl: string, logsBucket: string, name: string, options: record, projectId: string, queueTtl: string, results: record, secrets: list, serviceAccount: string, source: record, sourceProvenance: record, startTime: string, status: string, statusDetail: string, steps: list, substitutions: record, tags: list, timeout: string, timing: record, warnings: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a build with the specified configuration. This method returns a long-running `Operation`, which includes the build ID. Pass the build ID to `GetBuild` to determine the build status (such as `SUCCESS` or `FAILURE`).
#
# POST /v1/{parent}/builds
# operationId: cloudbuild.projects.locations.builds.create
# --approval shape: {config?: record, result?: record}
# --artifacts shape: {images?: list, mavenArtifacts?: list, npmPackages?: list, objects?: record, pythonPackages?: list}
# --availableSecrets shape: {inline?: list, secretManager?: list}
# --failureInfo shape: {detail?: string, type?: "FAILURE_TYPE_UNSPECIFIED"|"PUSH_FAILED"|"PUSH_IMAGE_NOT_FOUND"|"PUSH_NOT_AUTHORIZED"|"LOGGING_FAILURE"|"USER_BUILD_STEP"|"FETCH_SOURCE_FAILED"}
# --options shape: {defaultLogsBucketBehavior?: "DEFAULT_LOGS_BUCKET_BEHAVIOR_UNSPECIFIED"|"REGIONAL_USER_OWNED_BUCKET", diskSizeGb?: string, dynamicSubstitutions?: bool, env?: list, logStreamingOption?: "STREAM_DEFAULT"|"STREAM_ON"|"STREAM_OFF", logging?: "LOGGING_UNSPECIFIED"|"LEGACY"|"GCS_ONLY"|"STACKDRIVER_ONLY"|"CLOUD_LOGGING_ONLY"|"NONE", machineType?: "UNSPECIFIED"|"N1_HIGHCPU_8"|"N1_HIGHCPU_32"|"E2_HIGHCPU_8"|"E2_HIGHCPU_32", pool?: record, requestedVerifyOption?: "NOT_VERIFIED"|"VERIFIED", secretEnv?: list, sourceProvenanceHash?: list, substitutionOption?: "MUST_MATCH"|"ALLOW_LOOSE", volumes?: list, workerPool?: string}
# --results shape: {artifactManifest?: string, artifactTiming?: record, buildStepImages?: list, buildStepOutputs?: list, images?: list, mavenArtifacts?: list, npmPackages?: list, numArtifacts?: string, pythonPackages?: list}
# --secrets item shape: {kmsKeyName?: string, secretEnv?: record}
# --source shape: {gitSource?: record, repoSource?: record, storageSource?: record, storageSourceManifest?: record}
# --sourceProvenance shape: {resolvedRepoSource?: record, resolvedStorageSource?: record, resolvedStorageSourceManifest?: record}
# --steps item shape: {allowExitCodes?: list, allowFailure?: bool, args?: list, dir?: string, entrypoint?: string, env?: list, id?: string, name?: string, pullTiming?: record, script?: string, secretEnv?: list, timeout?: string, timing?: record, volumes?: list, waitFor?: list}
# --warnings item shape: {priority?: "PRIORITY_UNSPECIFIED"|"INFO"|"WARNING"|"ALERT", text?: string}
export def "builds cloudbuildprojectslocationsbuildscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Required. ID of the project.
  --approval: record # BuildApproval describes a build's approval configuration, state, and result. — shape: {config?: record, result?: record}
  --artifacts: record # Artifacts produced by a build that should be uploaded upon successful completion of all build steps. — shape: {images?: list, mavenArtifacts?: list, npmPackages?: list, objects?: record, pythonPackages?: list}
  --availableSecrets: record # Secrets and secret environment variables. — shape: {inline?: list, secretManager?: list}
  --failureInfo: record # A fatal problem encountered during the execution of the build. — shape: {detail?: string, type?: "FAILURE_TYPE_UNSPECIFIED"|"PUSH_FAILED"|"PUSH_IMAGE_NOT_FOUND"|"PUSH_NOT_AUTHORIZED"|"LOGGING_FAILURE"|"USER_BUILD_STEP"|"FETCH_SOURCE_FAILED"}
  --images: list # A list of images to be pushed upon the successful completion of all build steps. The images are pushed using the builder service account's credentials. The digests of the pushed images will be stored in the `Build` resource's results field. If any of the images fail to be pushed, the build status is marked `FAILURE`.
  --logsBucket: string # Google Cloud Storage bucket where logs should be written (see [Bucket Name Requirements](https://cloud.google.com/storage/docs/bucket-naming#requirements)). Logs file names will be of the format `${logs_bucket}/log-${build_id}.txt`.
  --options: record # Optional arguments to enable specific features of builds. — shape: {defaultLogsBucketBehavior?: "DEFAULT_LOGS_BUCKET_BEHAVIOR_UNSPECIFIED"|"REGIONAL_USER_OWNED_BUCKET", diskSizeGb?: string, dynamicSubstitutions?: bool, env?: list, logStreamingOption?: "STREAM_DEFAULT"|"STREAM_ON"|"STREAM_OFF", logging?: "LOGGING_UNSPECIFIED"|"LEGACY"|"GCS_ONLY"|"STACKDRIVER_ONLY"|"CLOUD_LOGGING_ONLY"|"NONE", machineType?: "UNSPECIFIED"|"N1_HIGHCPU_8"|"N1_HIGHCPU_32"|"E2_HIGHCPU_8"|"E2_HIGHCPU_32", pool?: record, requestedVerifyOption?: "NOT_VERIFIED"|"VERIFIED", secretEnv?: list, sourceProvenanceHash?: list, substitutionOption?: "MUST_MATCH"|"ALLOW_LOOSE", volumes?: list, workerPool?: string}
  --queueTtl: string # TTL in queue for this build. If provided and the build is enqueued longer than this value, the build will expire and the build status will be `EXPIRED`. The TTL starts ticking from create_time. (format: google-duration)
  --results: record # Artifacts created by the build pipeline. — shape: {artifactManifest?: string, artifactTiming?: record, buildStepImages?: list, buildStepOutputs?: list, images?: list, mavenArtifacts?: list, npmPackages?: list, numArtifacts?: string, pythonPackages?: list}
  --secrets: list # Secrets to decrypt using Cloud Key Management Service. Note: Secret Manager is the recommended technique for managing sensitive data with Cloud Build. Use `available_secrets` to configure builds to access secrets from Secret Manager. For instructions, see: https://cloud.google.com/cloud-build/docs/securing-builds/use-secrets — item shape: {kmsKeyName?: string, secretEnv?: record}
  --serviceAccount: string # IAM service account whose credentials will be used at build runtime. Must be of the format `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT}`. ACCOUNT can be email address or uniqueId of the service account. 
  --body-source: record # Location of the source in a supported storage service. — shape: {gitSource?: record, repoSource?: record, storageSource?: record, storageSourceManifest?: record}
  --sourceProvenance: record # Provenance of the source. Ways to find the original source, or verify that some source was used for this build. — shape: {resolvedRepoSource?: record, resolvedStorageSource?: record, resolvedStorageSourceManifest?: record}
  --steps: list # Required. The operations to be performed on the workspace. — item shape: {allowExitCodes?: list, allowFailure?: bool, args?: list, dir?: string, entrypoint?: string, env?: list, id?: string, name?: string, pullTiming?: record, script?: string, secretEnv?: list, timeout?: string, timing?: record, volumes?: list, waitFor?: list}
  --substitutions: record # Substitutions data for `Build` resource.
  --tags: list # Tags for annotation of a `Build`. These are not docker tags.
  --timeout: string # Amount of time that this build should be allowed to run, to second granularity. If this amount of time elapses, work on the build will cease and the build status will be `TIMEOUT`. `timeout` starts ticking from `startTime`. Default time is 60 minutes. (format: google-duration)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/builds" $qp)
  let body = {approval: $approval, artifacts: $artifacts, availableSecrets: $availableSecrets, failureInfo: $failureInfo, images: $images, logsBucket: $logsBucket, options: $options, queueTtl: $queueTtl, results: $results, secrets: $secrets, serviceAccount: $serviceAccount, source: $body_source, sourceProvenance: $sourceProvenance, steps: $steps, substitutions: $substitutions, tags: $tags, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch connecting GitLab repositories to Cloud Build. This API is experimental.
#
# POST /v1/{parent}/connectedRepositories:batchCreate
# operationId: cloudbuild.projects.locations.gitLabConfigs.connectedRepositories.batchCreate
# --requests item shape: {gitlabConnectedRepository?: record, parent?: string}
export def "connected-repositories-batch-create cloudbuildprojectslocationsgitLabConfigsconnectedRepositoriesbatchCreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # Required. Requests to connect GitLab repositories. — item shape: {gitlabConnectedRepository?: record, parent?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/connectedRepositories:batchCreate" $qp)
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all `GitLabConfigs` for a given project. This API is experimental
#
# GET /v1/{parent}/gitLabConfigs
# operationId: cloudbuild.projects.locations.gitLabConfigs.list
export def "git-lab-configs cloudbuildprojectslocationsgitLabConfigslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # The maximum number of configs to return. The service may return fewer than this value. If unspecified, at most 50 configs will be returned. The maximum value is 1000;, values above 1000 will be coerced to 1000.
  --pageToken: string # A page token, received from a previous ‘ListGitlabConfigsRequest’ call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ‘ListGitlabConfigsRequest’ must match the call that provided the page token.
]: nothing -> record<gitlabConfigs: table<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/gitLabConfigs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new `GitLabConfig`. This API is experimental
#
# POST /v1/{parent}/gitLabConfigs
# operationId: cloudbuild.projects.locations.gitLabConfigs.create
# --connectedRepositories item shape: {id?: string}
# --enterpriseConfig shape: {hostUri?: string, serviceDirectoryConfig?: record, sslCa?: string}
# --secrets shape: {apiAccessTokenVersion?: string, apiKeyVersion?: string, readAccessTokenVersion?: string, webhookSecretVersion?: string}
export def "git-lab-configs cloudbuildprojectslocationsgitLabConfigscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gitlabConfigId: string # Optional. The ID to use for the GitLabConfig, which will become the final component of the GitLabConfig’s resource name. gitlab_config_id must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character
  --connectedRepositories: list # Connected GitLab.com or GitLabEnterprise repositories for this config. — item shape: {id?: string}
  --enterpriseConfig: record # GitLabEnterpriseConfig represents the configuration for a GitLabEnterprise integration. — shape: {hostUri?: string, serviceDirectoryConfig?: record, sslCa?: string}
  --name: string # The resource name for the config.
  --secrets: record # GitLabSecrets represents the secrets in Secret Manager for a GitLab integration. — shape: {apiAccessTokenVersion?: string, apiKeyVersion?: string, readAccessTokenVersion?: string, webhookSecretVersion?: string}
  --username: string # Username of the GitLab.com or GitLab Enterprise account Cloud Build will use.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "gitlabConfigId" $gitlabConfigId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/gitLabConfigs" $qp)
  let body = {connectedRepositories: $connectedRepositories, enterpriseConfig: $enterpriseConfig, name: $name, secrets: $secrets, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all GitHubEnterpriseConfigs for a given project.
#
# GET /v1/{parent}/githubEnterpriseConfigs
# operationId: cloudbuild.projects.locations.githubEnterpriseConfigs.list
export def "github-enterprise-configs cloudbuildprojectslocationsgithubEnterpriseConfigslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # ID of the project
]: nothing -> record<configs: table<appId: string, createTime: string, displayName: string, hostUrl: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, webhookKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/githubEnterpriseConfigs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an association between a GCP project and a GitHub Enterprise server.
#
# POST /v1/{parent}/githubEnterpriseConfigs
# operationId: cloudbuild.projects.locations.githubEnterpriseConfigs.create
# --secrets shape: {oauthClientIdName?: string, oauthClientIdVersionName?: string, oauthSecretName?: string, oauthSecretVersionName?: string, privateKeyName?: string, privateKeyVersionName?: string, webhookSecretName?: string, webhookSecretVersionName?: string}
export def "github-enterprise-configs cloudbuildprojectslocationsgithubEnterpriseConfigscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gheConfigId: string # Optional. The ID to use for the GithubEnterpriseConfig, which will become the final component of the GithubEnterpriseConfig's resource name. ghe_config_id must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character
  --projectId: string # ID of the project.
  --appId: string # Required. The GitHub app id of the Cloud Build app on the GitHub Enterprise server. (format: int64)
  --displayName: string # Name to display for this config.
  --hostUrl: string # The URL of the github enterprise host the configuration is for.
  --name: string # Optional. The full resource name for the GitHubEnterpriseConfig For example: "projects/{$project_id}/locations/{$location_id}/githubEnterpriseConfigs/{$config_id}"
  --peeredNetwork: string # Optional. The network to be used when reaching out to the GitHub Enterprise server. The VPC network must be enabled for private service connection. This should be set if the GitHub Enterprise server is hosted on-premises and not reachable by public internet. If this field is left empty, no network peering will occur and calls to the GitHub Enterprise server will be made over the public internet. Must be in the format `projects/{project}/global/networks/{network}`, where {project} is a project number or id and {network} is the name of a VPC network in the project.
  --secrets: record # GitHubEnterpriseSecrets represents the names of all necessary secrets in Secret Manager for a GitHub Enterprise server. Format is: projects//secrets/. — shape: {oauthClientIdName?: string, oauthClientIdVersionName?: string, oauthSecretName?: string, oauthSecretVersionName?: string, privateKeyName?: string, privateKeyVersionName?: string, webhookSecretName?: string, webhookSecretVersionName?: string}
  --sslCa: string # Optional. SSL certificate to use for requests to GitHub Enterprise.
  --webhookKey: string # The key that should be attached to webhook calls to the ReceiveWebhook endpoint.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "gheConfigId" $gheConfigId "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/githubEnterpriseConfigs" $qp)
  let body = {appId: $appId, displayName: $displayName, hostUrl: $hostUrl, name: $name, peeredNetwork: $peeredNetwork, secrets: $secrets, sslCa: $sslCa, webhookKey: $webhookKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all repositories for a given `GitLabConfig`. This API is experimental
#
# GET /v1/{parent}/repos
# operationId: cloudbuild.projects.locations.gitLabConfigs.repos.list
export def "repos cloudbuildprojectslocationsgitLabConfigsreposlist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # The maximum number of repositories to return. The service may return fewer than this value.
  --pageToken: string # A page token, received from a previous ListGitLabRepositoriesRequest` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListGitLabRepositoriesRequest` must match the call that provided the page token.
]: nothing -> record<gitlabRepositories: table<browseUri: string, description: string, displayName: string, name: string, repositoryId: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists existing `BuildTrigger`s. This API is experimental.
#
# GET /v1/{parent}/triggers
# operationId: cloudbuild.projects.locations.triggers.list
export def "triggers cloudbuildprojectslocationstriggerslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Number of results to return in the list.
  --pageToken: string # Token to provide to skip to a particular spot in the list.
  --projectId: string # Required. ID of the project for which to list BuildTriggers.
]: nothing -> record<nextPageToken: string, triggers: table<approvalConfig: record, autodetect: bool, bitbucketServerTriggerConfig: record, build: record, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record, github: record, gitlabEnterpriseEventsConfig: record, id: string, ignoredFiles: list, includeBuildLogs: string, includedFiles: list, name: string, pubsubConfig: record, repositoryEventConfig: record, resourceName: string, serviceAccount: string, sourceToBuild: record, substitutions: record, tags: list, triggerTemplate: record, webhookConfig: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new `BuildTrigger`. This API is experimental.
#
# POST /v1/{parent}/triggers
# operationId: cloudbuild.projects.locations.triggers.create
# --approvalConfig shape: {approvalRequired?: bool}
# --bitbucketServerTriggerConfig shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
# --build shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
# --gitFileSource shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
# --github shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
# --gitlabEnterpriseEventsConfig shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
# --pubsubConfig shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
# --repositoryEventConfig shape: {pullRequest?: record, push?: record, repository?: string}
# --sourceToBuild shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
# --triggerTemplate shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
# --webhookConfig shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
export def "triggers cloudbuildprojectslocationstriggerscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Required. ID of the project for which to configure automatic builds.
  --approvalConfig: record # ApprovalConfig describes configuration for manual approval of a build. — shape: {approvalRequired?: bool}
  --autodetect: string@bool-completer # Autodetect build configuration. The following precedence is used (case insensitive): 1. cloudbuild.yaml 2. cloudbuild.yml 3. cloudbuild.json 4. Dockerfile Currently only available for GitHub App Triggers.
  --bitbucketServerTriggerConfig: record # BitbucketServerTriggerConfig describes the configuration of a trigger that creates a build whenever a Bitbucket Server event is received. — shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
  --build: record # A build resource in the Cloud Build API. At a high level, a `Build` describes where to find source code, how to build it (for example, the builder image to run on the source), and where to store the built artifacts. Fields can include the following variables, which will be expanded when the build is created: - $PROJECT_ID: the project ID of the build. - $PROJECT_NUMBER: the project number of the build. - $LOCATION: the location/region of the build. - $BUILD_ID: the autogenerated ID of the build. - $REPO_NAME: the source repository name specified by RepoSource. - $BRANCH_NAME: the branch name specified by RepoSource. - $TAG_NAME: the tag name specified by RepoSource. - $REVISION_ID or $COMMIT_SHA: the commit SHA specified by RepoSource or resolved from the specified branch or tag. - $SHORT_SHA: first 7 characters of $REVISION_ID or $COMMIT_SHA. — shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
  --description: string # Human-readable description of this trigger.
  --disabled: string@bool-completer # If true, the trigger will never automatically execute a build.
  --eventType: string@eventType-completer # EventType allows the user to explicitly set the type of event to which this BuildTrigger should respond. This field will be validated against the rest of the configuration if it is set.
  --filename: string # Path, from the source root, to the build configuration file (i.e. cloudbuild.yaml).
  --filter: string # A Common Expression Language string.
  --gitFileSource: record # GitFileSource describes a file within a (possibly remote) code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
  --github: record # GitHubEventsConfig describes the configuration of a trigger that creates a build whenever a GitHub event is received. — shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
  --gitlabEnterpriseEventsConfig: record # GitLabEventsConfig describes the configuration of a trigger that creates a build whenever a GitLab event is received. — shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
  --ignoredFiles: list # ignored_files and included_files are file glob matches using https://golang.org/pkg/path/filepath/#Match extended with support for "**". If ignored_files and changed files are both empty, then they are not used to determine whether or not to trigger a build. If ignored_files is not empty, then we ignore any files that match any of the ignored_file globs. If the change has no files that are outside of the ignored_files globs, then we do not trigger a build.
  --includeBuildLogs: string@includeBuildLogs-completer # If set to INCLUDE_BUILD_LOGS_WITH_STATUS, log url will be shown on GitHub page when build status is final. Setting this field to INCLUDE_BUILD_LOGS_WITH_STATUS for non GitHub triggers results in INVALID_ARGUMENT error.
  --includedFiles: list # If any of the files altered in the commit pass the ignored_files filter and included_files is empty, then as far as this filter is concerned, we should trigger the build. If any of the files altered in the commit pass the ignored_files filter and included_files is not empty, then we make sure that at least one of those files matches a included_files glob. If not, then we do not trigger a build.
  --name: string # User-assigned name of the trigger. Must be unique within the project. Trigger names must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character.
  --pubsubConfig: record # PubsubConfig describes the configuration of a trigger that creates a build whenever a Pub/Sub message is published. — shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
  --repositoryEventConfig: record # The configuration of a trigger that creates a build whenever an event from Repo API is received. — shape: {pullRequest?: record, push?: record, repository?: string}
  --resourceName: string # The `Trigger` name with format: `projects/{project}/locations/{location}/triggers/{trigger}`, where {trigger} is a unique identifier generated by the service.
  --serviceAccount: string # The service account used for all user-controlled operations including UpdateBuildTrigger, RunBuildTrigger, CreateBuild, and CancelBuild. If no service account is set, then the standard Cloud Build service account ([PROJECT_NUM]@system.gserviceaccount.com) will be used instead. Format: `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT_ID_OR_EMAIL}`
  --sourceToBuild: record # GitRepoSource describes a repo and ref of a code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
  --substitutions: record # Substitutions for Build resource. The keys must match the following regular expression: `^_[A-Z0-9_]+$`.
  --tags: list # Tags for annotation of a `BuildTrigger`
  --triggerTemplate: record # Location of the source in a Google Cloud Source Repository. — shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
  --webhookConfig: record # WebhookConfig describes the configuration of a trigger that creates a build whenever a webhook is sent to a trigger's webhook URL. — shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
]: any -> record<approvalConfig: record<approvalRequired: bool>, autodetect: bool, bitbucketServerTriggerConfig: record<bitbucketServerConfig: record<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, bitbucketServerConfigResource: string, projectKey: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repoSlug: string>, build: record<approval: record<config: record, result: record, state: string>, artifacts: record<images: list, mavenArtifacts: list, npmPackages: list, objects: record, pythonPackages: list>, availableSecrets: record<inline: list, secretManager: list>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list, logStreamingOption: string, logging: string, machineType: string, pool: record, requestedVerifyOption: string, secretEnv: list, sourceProvenanceHash: list, substitutionOption: string, volumes: list, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record, buildStepImages: list, buildStepOutputs: list, images: list, mavenArtifacts: list, npmPackages: list, numArtifacts: string, pythonPackages: list>, secrets: list<record>, serviceAccount: string, source: record<gitSource: record, repoSource: record, storageSource: record, storageSourceManifest: record>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record, resolvedStorageSource: record, resolvedStorageSourceManifest: record>, startTime: string, status: string, statusDetail: string, steps: list<record>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: list<record>>, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, path: string, repoType: string, revision: string, uri: string>, github: record<enterpriseConfigResourceName: string, installationId: string, name: string, owner: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, gitlabEnterpriseEventsConfig: record<gitlabConfig: record<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, gitlabConfigResource: string, projectNamespace: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, id: string, ignoredFiles: list<string>, includeBuildLogs: string, includedFiles: list<string>, name: string, pubsubConfig: record<serviceAccountEmail: string, state: string, subscription: string, topic: string>, repositoryEventConfig: record<pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repository: string, repositoryType: string>, resourceName: string, serviceAccount: string, sourceToBuild: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, ref: string, repoType: string, uri: string>, substitutions: record, tags: list<string>, triggerTemplate: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, webhookConfig: record<secret: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/triggers" $qp)
  let body = {approvalConfig: $approvalConfig, autodetect: $autodetect, bitbucketServerTriggerConfig: $bitbucketServerTriggerConfig, build: $build, description: $description, disabled: $disabled, eventType: $eventType, filename: $filename, filter: $filter, gitFileSource: $gitFileSource, github: $github, gitlabEnterpriseEventsConfig: $gitlabEnterpriseEventsConfig, ignoredFiles: $ignoredFiles, includeBuildLogs: $includeBuildLogs, includedFiles: $includedFiles, name: $name, pubsubConfig: $pubsubConfig, repositoryEventConfig: $repositoryEventConfig, resourceName: $resourceName, serviceAccount: $serviceAccount, sourceToBuild: $sourceToBuild, substitutions: $substitutions, tags: $tags, triggerTemplate: $triggerTemplate, webhookConfig: $webhookConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists `WorkerPool`s.
#
# GET /v1/{parent}/workerPools
# operationId: cloudbuild.projects.locations.workerPools.list
export def "worker-pools cloudbuildprojectslocationsworkerPoolslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # The maximum number of `WorkerPool`s to return. The service may return fewer than this value. If omitted, the server will use a sensible default.
  --pageToken: string # A page token, received from a previous `ListWorkerPools` call. Provide this to retrieve the subsequent page.
]: nothing -> record<nextPageToken: string, workerPools: table<annotations: record, createTime: string, deleteTime: string, displayName: string, etag: string, name: string, privatePoolV1Config: record, state: string, uid: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/workerPools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a `WorkerPool`.
#
# POST /v1/{parent}/workerPools
# operationId: cloudbuild.projects.locations.workerPools.create
# --privatePoolV1Config shape: {networkConfig?: record, workerConfig?: record}
export def "worker-pools cloudbuildprojectslocationsworkerPoolscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --validateOnly: string@bool-completer # If set, validate the request and preview the response, but do not actually post it.
  --workerPoolId: string # Required. Immutable. The ID to use for the `WorkerPool`, which will become the final component of the resource name. This value should be 1-63 characters, and valid characters are /a-z-/.
  --annotations: record # User specified annotations. See https://google.aip.dev/128#annotations for more details such as format and size limitations.
  --displayName: string # A user-specified, human-readable name for the `WorkerPool`. If provided, this value must be 1-63 characters.
  --privatePoolV1Config: record # Configuration for a V1 `PrivatePool`. — shape: {networkConfig?: record, workerConfig?: record}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "validateOnly" $validateOnly "scalar") (serialize-qp "workerPoolId" $workerPoolId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/workerPools" $qp)
  let body = {annotations: $annotations, displayName: $displayName, privatePoolV1Config: $privatePoolV1Config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a `BuildTrigger` by its project ID and trigger ID. This API is experimental.
#
# PATCH /v1/{resourceName}
# operationId: cloudbuild.projects.locations.triggers.patch
# --approvalConfig shape: {approvalRequired?: bool}
# --bitbucketServerTriggerConfig shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
# --build shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
# --gitFileSource shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
# --github shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
# --gitlabEnterpriseEventsConfig shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
# --pubsubConfig shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
# --repositoryEventConfig shape: {pullRequest?: record, push?: record, repository?: string}
# --sourceToBuild shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
# --triggerTemplate shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
# --webhookConfig shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
export def "projects cloudbuildprojectslocationstriggerspatch" [
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --projectId: string # Required. ID of the project that owns the trigger.
  --triggerId: string # Required. ID of the `BuildTrigger` to update.
  --approvalConfig: record # ApprovalConfig describes configuration for manual approval of a build. — shape: {approvalRequired?: bool}
  --autodetect: string@bool-completer # Autodetect build configuration. The following precedence is used (case insensitive): 1. cloudbuild.yaml 2. cloudbuild.yml 3. cloudbuild.json 4. Dockerfile Currently only available for GitHub App Triggers.
  --bitbucketServerTriggerConfig: record # BitbucketServerTriggerConfig describes the configuration of a trigger that creates a build whenever a Bitbucket Server event is received. — shape: {bitbucketServerConfig?: record, bitbucketServerConfigResource?: string, projectKey?: string, pullRequest?: record, push?: record, repoSlug?: string}
  --build: record # A build resource in the Cloud Build API. At a high level, a `Build` describes where to find source code, how to build it (for example, the builder image to run on the source), and where to store the built artifacts. Fields can include the following variables, which will be expanded when the build is created: - $PROJECT_ID: the project ID of the build. - $PROJECT_NUMBER: the project number of the build. - $LOCATION: the location/region of the build. - $BUILD_ID: the autogenerated ID of the build. - $REPO_NAME: the source repository name specified by RepoSource. - $BRANCH_NAME: the branch name specified by RepoSource. - $TAG_NAME: the tag name specified by RepoSource. - $REVISION_ID or $COMMIT_SHA: the commit SHA specified by RepoSource or resolved from the specified branch or tag. - $SHORT_SHA: first 7 characters of $REVISION_ID or $COMMIT_SHA. — shape: {approval?: record, artifacts?: record, availableSecrets?: record, failureInfo?: record, images?: list, logsBucket?: string, options?: record, queueTtl?: string, results?: record, secrets?: list, serviceAccount?: string, source?: record, sourceProvenance?: record, steps?: list, substitutions?: record, tags?: list, timeout?: string}
  --description: string # Human-readable description of this trigger.
  --disabled: string@bool-completer # If true, the trigger will never automatically execute a build.
  --eventType: string@eventType-completer # EventType allows the user to explicitly set the type of event to which this BuildTrigger should respond. This field will be validated against the rest of the configuration if it is set.
  --filename: string # Path, from the source root, to the build configuration file (i.e. cloudbuild.yaml).
  --filter: string # A Common Expression Language string.
  --gitFileSource: record # GitFileSource describes a file within a (possibly remote) code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, path?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", revision?: string, uri?: string}
  --github: record # GitHubEventsConfig describes the configuration of a trigger that creates a build whenever a GitHub event is received. — shape: {enterpriseConfigResourceName?: string, installationId?: string, name?: string, owner?: string, pullRequest?: record, push?: record}
  --gitlabEnterpriseEventsConfig: record # GitLabEventsConfig describes the configuration of a trigger that creates a build whenever a GitLab event is received. — shape: {gitlabConfig?: record, gitlabConfigResource?: string, projectNamespace?: string, pullRequest?: record, push?: record}
  --ignoredFiles: list # ignored_files and included_files are file glob matches using https://golang.org/pkg/path/filepath/#Match extended with support for "**". If ignored_files and changed files are both empty, then they are not used to determine whether or not to trigger a build. If ignored_files is not empty, then we ignore any files that match any of the ignored_file globs. If the change has no files that are outside of the ignored_files globs, then we do not trigger a build.
  --includeBuildLogs: string@includeBuildLogs-completer # If set to INCLUDE_BUILD_LOGS_WITH_STATUS, log url will be shown on GitHub page when build status is final. Setting this field to INCLUDE_BUILD_LOGS_WITH_STATUS for non GitHub triggers results in INVALID_ARGUMENT error.
  --includedFiles: list # If any of the files altered in the commit pass the ignored_files filter and included_files is empty, then as far as this filter is concerned, we should trigger the build. If any of the files altered in the commit pass the ignored_files filter and included_files is not empty, then we make sure that at least one of those files matches a included_files glob. If not, then we do not trigger a build.
  --name: string # User-assigned name of the trigger. Must be unique within the project. Trigger names must meet the following requirements: + They must contain only alphanumeric characters and dashes. + They can be 1-64 characters long. + They must begin and end with an alphanumeric character.
  --pubsubConfig: record # PubsubConfig describes the configuration of a trigger that creates a build whenever a Pub/Sub message is published. — shape: {serviceAccountEmail?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SUBSCRIPTION_DELETED"|"TOPIC_DELETED"|"SUBSCRIPTION_MISCONFIGURED", topic?: string}
  --repositoryEventConfig: record # The configuration of a trigger that creates a build whenever an event from Repo API is received. — shape: {pullRequest?: record, push?: record, repository?: string}
  --body-resourceName: string # The `Trigger` name with format: `projects/{project}/locations/{location}/triggers/{trigger}`, where {trigger} is a unique identifier generated by the service.
  --serviceAccount: string # The service account used for all user-controlled operations including UpdateBuildTrigger, RunBuildTrigger, CreateBuild, and CancelBuild. If no service account is set, then the standard Cloud Build service account ([PROJECT_NUM]@system.gserviceaccount.com) will be used instead. Format: `projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT_ID_OR_EMAIL}`
  --sourceToBuild: record # GitRepoSource describes a repo and ref of a code repository. — shape: {bitbucketServerConfig?: string, githubEnterpriseConfig?: string, ref?: string, repoType?: "UNKNOWN"|"CLOUD_SOURCE_REPOSITORIES"|"GITHUB"|"BITBUCKET_SERVER"|"GITLAB", uri?: string}
  --substitutions: record # Substitutions for Build resource. The keys must match the following regular expression: `^_[A-Z0-9_]+$`.
  --tags: list # Tags for annotation of a `BuildTrigger`
  --triggerTemplate: record # Location of the source in a Google Cloud Source Repository. — shape: {branchName?: string, commitSha?: string, dir?: string, invertRegex?: bool, projectId?: string, repoName?: string, substitutions?: record, tagName?: string}
  --webhookConfig: record # WebhookConfig describes the configuration of a trigger that creates a build whenever a webhook is sent to a trigger's webhook URL. — shape: {secret?: string, state?: "STATE_UNSPECIFIED"|"OK"|"SECRET_DELETED"}
]: any -> record<approvalConfig: record<approvalRequired: bool>, autodetect: bool, bitbucketServerTriggerConfig: record<bitbucketServerConfig: record<apiKey: string, connectedRepositories: list, createTime: string, hostUri: string, name: string, peeredNetwork: string, secrets: record, sslCa: string, username: string, webhookKey: string>, bitbucketServerConfigResource: string, projectKey: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repoSlug: string>, build: record<approval: record<config: record, result: record, state: string>, artifacts: record<images: list, mavenArtifacts: list, npmPackages: list, objects: record, pythonPackages: list>, availableSecrets: record<inline: list, secretManager: list>, buildTriggerId: string, createTime: string, failureInfo: record<detail: string, type: string>, finishTime: string, id: string, images: list<string>, logUrl: string, logsBucket: string, name: string, options: record<defaultLogsBucketBehavior: string, diskSizeGb: string, dynamicSubstitutions: bool, env: list, logStreamingOption: string, logging: string, machineType: string, pool: record, requestedVerifyOption: string, secretEnv: list, sourceProvenanceHash: list, substitutionOption: string, volumes: list, workerPool: string>, projectId: string, queueTtl: string, results: record<artifactManifest: string, artifactTiming: record, buildStepImages: list, buildStepOutputs: list, images: list, mavenArtifacts: list, npmPackages: list, numArtifacts: string, pythonPackages: list>, secrets: list<record>, serviceAccount: string, source: record<gitSource: record, repoSource: record, storageSource: record, storageSourceManifest: record>, sourceProvenance: record<fileHashes: record, resolvedRepoSource: record, resolvedStorageSource: record, resolvedStorageSourceManifest: record>, startTime: string, status: string, statusDetail: string, steps: list<record>, substitutions: record, tags: list<string>, timeout: string, timing: record, warnings: list<record>>, createTime: string, description: string, disabled: bool, eventType: string, filename: string, filter: string, gitFileSource: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, path: string, repoType: string, revision: string, uri: string>, github: record<enterpriseConfigResourceName: string, installationId: string, name: string, owner: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, gitlabEnterpriseEventsConfig: record<gitlabConfig: record<connectedRepositories: list, createTime: string, enterpriseConfig: record, name: string, secrets: record, username: string, webhookKey: string>, gitlabConfigResource: string, projectNamespace: string, pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>>, id: string, ignoredFiles: list<string>, includeBuildLogs: string, includedFiles: list<string>, name: string, pubsubConfig: record<serviceAccountEmail: string, state: string, subscription: string, topic: string>, repositoryEventConfig: record<pullRequest: record<branch: string, commentControl: string, invertRegex: bool>, push: record<branch: string, invertRegex: bool, tag: string>, repository: string, repositoryType: string>, resourceName: string, serviceAccount: string, sourceToBuild: record<bitbucketServerConfig: string, githubEnterpriseConfig: string, ref: string, repoType: string, uri: string>, substitutions: record, tags: list<string>, triggerTemplate: record<branchName: string, commitSha: string, dir: string, invertRegex: bool, projectId: string, repoName: string, substitutions: record, tagName: string>, webhookConfig: record<secret: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "triggerId" $triggerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($resourceName)" $qp)
  let body = {approvalConfig: $approvalConfig, autodetect: $autodetect, bitbucketServerTriggerConfig: $bitbucketServerTriggerConfig, build: $build, description: $description, disabled: $disabled, eventType: $eventType, filename: $filename, filter: $filter, gitFileSource: $gitFileSource, github: $github, gitlabEnterpriseEventsConfig: $gitlabEnterpriseEventsConfig, ignoredFiles: $ignoredFiles, includeBuildLogs: $includeBuildLogs, includedFiles: $includedFiles, name: $name, pubsubConfig: $pubsubConfig, repositoryEventConfig: $repositoryEventConfig, resourceName: $body_resourceName, serviceAccount: $serviceAccount, sourceToBuild: $sourceToBuild, substitutions: $substitutions, tags: $tags, triggerTemplate: $triggerTemplate, webhookConfig: $webhookConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
