# Auto-generated client for Amazon Lookout for Vision v2020-11-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lookoutvision/2020-11-20/openapi.json
# Auth: --token flag or $env.AMAZON_LOOKOUT_FOR_VISION_TOKEN

const BASE_URL = "http://lookoutvision.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LOOKOUT_FOR_VISION_TOKEN | default "" }
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

def base-url-completer [] { ["http://lookoutvision.us-east-1.amazonaws.com" "http://lookoutvision.us-east-2.amazonaws.com" "http://lookoutvision.us-west-1.amazonaws.com" "http://lookoutvision.us-west-2.amazonaws.com" "http://lookoutvision.us-gov-west-1.amazonaws.com" "http://lookoutvision.us-gov-east-1.amazonaws.com" "http://lookoutvision.ca-central-1.amazonaws.com" "http://lookoutvision.eu-north-1.amazonaws.com" "http://lookoutvision.eu-west-1.amazonaws.com" "http://lookoutvision.eu-west-2.amazonaws.com" "http://lookoutvision.eu-west-3.amazonaws.com" "http://lookoutvision.eu-central-1.amazonaws.com" "http://lookoutvision.eu-south-1.amazonaws.com" "http://lookoutvision.af-south-1.amazonaws.com" "http://lookoutvision.ap-northeast-1.amazonaws.com" "http://lookoutvision.ap-northeast-2.amazonaws.com" "http://lookoutvision.ap-northeast-3.amazonaws.com" "http://lookoutvision.ap-southeast-1.amazonaws.com" "http://lookoutvision.ap-southeast-2.amazonaws.com" "http://lookoutvision.ap-east-1.amazonaws.com" "http://lookoutvision.ap-south-1.amazonaws.com" "http://lookoutvision.sa-east-1.amazonaws.com" "http://lookoutvision.me-south-1.amazonaws.com" "https://lookoutvision.us-east-1.amazonaws.com" "https://lookoutvision.us-east-2.amazonaws.com" "https://lookoutvision.us-west-1.amazonaws.com" "https://lookoutvision.us-west-2.amazonaws.com" "https://lookoutvision.us-gov-west-1.amazonaws.com" "https://lookoutvision.us-gov-east-1.amazonaws.com" "https://lookoutvision.ca-central-1.amazonaws.com" "https://lookoutvision.eu-north-1.amazonaws.com" "https://lookoutvision.eu-west-1.amazonaws.com" "https://lookoutvision.eu-west-2.amazonaws.com" "https://lookoutvision.eu-west-3.amazonaws.com" "https://lookoutvision.eu-central-1.amazonaws.com" "https://lookoutvision.eu-south-1.amazonaws.com" "https://lookoutvision.af-south-1.amazonaws.com" "https://lookoutvision.ap-northeast-1.amazonaws.com" "https://lookoutvision.ap-northeast-2.amazonaws.com" "https://lookoutvision.ap-northeast-3.amazonaws.com" "https://lookoutvision.ap-southeast-1.amazonaws.com" "https://lookoutvision.ap-southeast-2.amazonaws.com" "https://lookoutvision.ap-east-1.amazonaws.com" "https://lookoutvision.ap-south-1.amazonaws.com" "https://lookoutvision.sa-east-1.amazonaws.com" "https://lookoutvision.me-south-1.amazonaws.com" "http://lookoutvision.cn-north-1.amazonaws.com.cn" "http://lookoutvision.cn-northwest-1.amazonaws.com.cn" "https://lookoutvision.cn-north-1.amazonaws.com.cn" "https://lookoutvision.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2020-11-20-projects-datasets create" } } | get name | first)
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

# Creates a new dataset in an Amazon Lookout for Vision project. CreateDataset can create a training or a test dataset from a valid dataset source (DatasetSource). If you want a single dataset project, specify train for the value of DatasetType. To have a project with separate training and test datasets, call CreateDataset twice. On the first call, specify train for the value of DatasetType. On the second call, specify test for the value of DatasetType. This operation requires permissions to perform the lookoutvision:CreateDataset operation.
#
# POST /2020-11-20/projects/{projectName}/datasets
# operationId: CreateDataset
# --DatasetSource shape: {GroundTruthManifest?: any}
export def "2020-11-20-projects-datasets create" [
  project_name: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateDataset completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateDataset. In this case, safely retry your call to CreateDataset by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple dataset creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateDataset. An idempotency token is active for 8 hours.
  dataset_type: string # The type of the dataset. Specify train for a training dataset. Specify test for a test dataset.
  --dataset-source: record # Information about the location of a manifest file that Amazon Lookout for Vision uses to to create a dataset. — shape: {GroundTruthManifest?: any}
]: any -> record<DatasetMetadata: record<DatasetType: record, CreationTimestamp: record, Status: record, StatusMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}/datasets"))
  let req_body = {"DatasetType": $dataset_type, "DatasetSource": $dataset_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a new version of a model within an an Amazon Lookout for Vision project. CreateModel is an asynchronous operation in which Amazon Lookout for Vision trains, tests, and evaluates a new version of a model. To get the current status, check the Status field returned in the response from DescribeModel. If the project has a single dataset, Amazon Lookout for Vision internally splits the dataset to create a training and a test dataset. If the project has a training and a test dataset, Lookout for Vision uses the respective datasets to train and test the model. After training completes, the evaluation metrics are stored at the location specified in OutputConfig. This operation requires permissions to perform the lookoutvision:CreateModel operation. If you want to tag your model, you also require permission to the lookoutvision:TagResource operation.
#
# POST /2020-11-20/projects/{projectName}/models
# operationId: CreateModel
# --OutputConfig shape: {S3Location?: any}
# --Tags item shape: {Key: any, Value: any}
export def "2020-11-20-projects-models create" [
  project_name: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateModel. In this case, safely retry your call to CreateModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from starting multiple training jobs. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateModel. An idempotency token is active for 8 hours.
  --description: string # A description for the version of the model.
  output_config: record # The S3 location where Amazon Lookout for Vision saves model training files. — shape: {S3Location?: any}
  --kms-key-id: string # The identifier for your AWS KMS key. The key is used to encrypt training and test images copied into the service for model training. Your source images are unaffected. If this parameter is not specified, the copied images are encrypted by a key that AWS owns and manages.
  --tags: list # A set of tags (key-value pairs) that you want to attach to the model. — item shape: {Key: any, Value: any}
]: any -> record<ModelMetadata: record<CreationTimestamp: record, ModelVersion: record, ModelArn: record, Description: record, Status: record, StatusMessage: record, Performance: record<F1Score: record, Recall: record, Precision: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}/models"))
  let req_body = {"Description": $description, "OutputConfig": $output_config, "KmsKeyId": $kms_key_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the versions of a model in an Amazon Lookout for Vision project. The ListModels operation is eventually consistent. Recent calls to CreateModel might take a while to appear in the response from ListProjects. This operation requires permissions to perform the lookoutvision:ListModels operation.
#
# GET /2020-11-20/projects/{projectName}/models
# operationId: ListModels
export def "2020-11-20-projects-models list" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of models.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Models: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an empty Amazon Lookout for Vision project. After you create the project, add a dataset by calling CreateDataset. This operation requires permissions to perform the lookoutvision:CreateProject operation.
#
# POST /2020-11-20/projects
# operationId: CreateProject
export def "2020-11-20-projects create" [
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to CreateProject completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from CreateProject. In this case, safely retry your call to CreateProject by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple project creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to CreateProject. An idempotency token is active for 8 hours.
  project_name: string # The name for the project.
]: any -> record<ProjectMetadata: record<ProjectArn: record, ProjectName: record, CreationTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2020-11-20/projects")
  let req_body = {"ProjectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the Amazon Lookout for Vision projects in your AWS account that are in the AWS Region in which you call ListProjects. The ListProjects operation is eventually consistent. Recent calls to CreateProject and DeleteProject might take a while to appear in the response from ListProjects. This operation requires permissions to perform the lookoutvision:ListProjects operation.
#
# GET /2020-11-20/projects
# operationId: ListProjects
export def "2020-11-20-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of projects.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Projects: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-11-20/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an existing Amazon Lookout for Vision dataset. If your the project has a single dataset, you must create a new dataset before you can create a model. If you project has a training dataset and a test dataset consider the following. If you delete the test dataset, your project reverts to a single dataset project. If you then train the model, Amazon Lookout for Vision internally splits the remaining dataset into a training and test dataset. If you delete the training dataset, you must create a training dataset before you can create a model. This operation requires permissions to perform the lookoutvision:DeleteDataset operation.
#
# DELETE /2020-11-20/projects/{projectName}/datasets/{datasetType}
# operationId: DeleteDataset
export def "2020-11-20-projects-datasets delete" [
  project_name: string
  dataset_type: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteDataset completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from DeleteDataset. In this case, safely retry your call to DeleteDataset by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple deletetion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteDataset. An idempotency token is active for 8 hours.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), dataset_type: (encode-path-segment $dataset_type)} | format pattern "/2020-11-20/projects/{project_name}/datasets/{dataset_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describe an Amazon Lookout for Vision dataset. This operation requires permissions to perform the lookoutvision:DescribeDataset operation.
#
# GET /2020-11-20/projects/{projectName}/datasets/{datasetType}
# operationId: DescribeDataset
export def "2020-11-20-projects-datasets get" [
  project_name: string
  dataset_type: string
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
]: nothing -> record<DatasetDescription: record<ProjectName: record, DatasetType: record, CreationTimestamp: record, LastUpdatedTimestamp: record, Status: record, StatusMessage: record, ImageStats: record<Total: record, Labeled: record, Normal: record, Anomaly: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), dataset_type: (encode-path-segment $dataset_type)} | format pattern "/2020-11-20/projects/{project_name}/datasets/{dataset_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an Amazon Lookout for Vision model. You can't delete a running model. To stop a running model, use the StopModel operation. It might take a few seconds to delete a model. To determine if a model has been deleted, call ListModels and check if the version of the model (ModelVersion) is in the Models array. This operation requires permissions to perform the lookoutvision:DeleteModel operation.
#
# DELETE /2020-11-20/projects/{projectName}/models/{modelVersion}
# operationId: DeleteModel
export def "2020-11-20-projects-models delete" [
  project_name: string
  model_version: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteModel completes only once. You choose the value to pass. For example, an issue might prevent you from getting a response from DeleteModel. In this case, safely retry your call to DeleteModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple model deletion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteModel. An idempotency token is active for 8 hours.
]: nothing -> record<ModelArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), model_version: (encode-path-segment $model_version)} | format pattern "/2020-11-20/projects/{project_name}/models/{model_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a version of an Amazon Lookout for Vision model. This operation requires permissions to perform the lookoutvision:DescribeModel operation.
#
# GET /2020-11-20/projects/{projectName}/models/{modelVersion}
# operationId: DescribeModel
export def "2020-11-20-projects-models get" [
  project_name: string
  model_version: string
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
]: nothing -> record<ModelDescription: record<ModelVersion: record, ModelArn: record, CreationTimestamp: record, Description: record, Status: record, StatusMessage: record, Performance: record<F1Score: record, Recall: record, Precision: record>, OutputConfig: record<S3Location: record>, EvaluationManifest: record<Bucket: record, Key: record>, EvaluationResult: record<Bucket: record, Key: record>, EvaluationEndTimestamp: record, KmsKeyId: record, MinInferenceUnits: record, MaxInferenceUnits: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), model_version: (encode-path-segment $model_version)} | format pattern "/2020-11-20/projects/{project_name}/models/{model_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an Amazon Lookout for Vision project. To delete a project, you must first delete each version of the model associated with the project. To delete a model use the DeleteModel operation. You also have to delete the dataset(s) associated with the model. For more information, see DeleteDataset. The images referenced by the training and test datasets aren't deleted. This operation requires permissions to perform the lookoutvision:DeleteProject operation.
#
# DELETE /2020-11-20/projects/{projectName}
# operationId: DeleteProject
export def "2020-11-20-projects delete" [
  project_name: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to DeleteProject completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from DeleteProject. In this case, safely retry your call to DeleteProject by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple project deletion requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to DeleteProject. An idempotency token is active for 8 hours.
]: nothing -> record<ProjectArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes an Amazon Lookout for Vision project. This operation requires permissions to perform the lookoutvision:DescribeProject operation.
#
# GET /2020-11-20/projects/{projectName}
# operationId: DescribeProject
export def "2020-11-20-projects get" [
  project_name: string
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
]: nothing -> record<ProjectDescription: record<ProjectArn: record, ProjectName: record, CreationTimestamp: record, Datasets: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes an Amazon Lookout for Vision model packaging job. This operation requires permissions to perform the lookoutvision:DescribeModelPackagingJob operation. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# GET /2020-11-20/projects/{projectName}/modelpackagingjobs/{jobName}
# operationId: DescribeModelPackagingJob
export def "2020-11-20-projects-modelpackagingjobs get-model-packaging-job" [
  project_name: string
  job_name: string
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
]: nothing -> record<ModelPackagingDescription: record<JobName: record, ProjectName: record, ModelVersion: record, ModelPackagingConfiguration: record<Greengrass: record>, ModelPackagingJobDescription: record, ModelPackagingMethod: record, ModelPackagingOutputDetails: record<Greengrass: record>, Status: record, StatusMessage: record, CreationTimestamp: record, LastUpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), job_name: (encode-path-segment $job_name)} | format pattern "/2020-11-20/projects/{project_name}/modelpackagingjobs/{job_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Detects anomalies in an image that you supply. The response from DetectAnomalies includes a boolean prediction that the image contains one or more anomalies and a confidence value for the prediction. If the model is an image segmentation model, the response also includes segmentation information for each type of anomaly found in the image. Before calling DetectAnomalies, you must first start your model with the StartModel operation. You are charged for the amount of time, in minutes, that a model runs and for the number of anomaly detection units that your model uses. If you are not using a model, use the StopModel operation to stop your model. For more information, see Detecting anomalies in an image in the Amazon Lookout for Vision developer guide. This operation requires permissions to perform the lookoutvision:DetectAnomalies operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/detect#Content-Type
# operationId: DetectAnomalies
export def "2020-11-20-projects-models-detect-content-type create-detect-anomalies" [
  project_name: string
  model_version: string
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
  --content-type: string # The type of the image passed in Body. Valid values are image/png (PNG format images) and image/jpeg (JPG format images).
  body: string # The unencrypted image bytes that you want to analyze.
]: any -> record<DetectAnomalyResult: record<Source: record<Type: record>, IsAnomalous: record, Confidence: record, Anomalies: record, AnomalyMask: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), model_version: (encode-path-segment $model_version)} | format pattern "/2020-11-20/projects/{project_name}/models/{model_version}/detect#Content-Type"))
  let req_body = {"Body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Lists the JSON Lines within a dataset. An Amazon Lookout for Vision JSON Line contains the anomaly information for a single image, including the image location and the assigned label. This operation requires permissions to perform the lookoutvision:ListDatasetEntries operation.
#
# GET /2020-11-20/projects/{projectName}/datasets/{datasetType}/entries
# operationId: ListDatasetEntries
export def "2020-11-20-projects-datasets-entries list" [
  project_name: string
  dataset_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labeled: oneof<nothing, bool> # Specify true to include labeled entries, otherwise specify false. If you don't specify a value, Lookout for Vision returns all entries.
  --anomaly-class: string # Specify normal to include only normal images. Specify anomaly to only include anomalous entries. If you don't specify a value, Amazon Lookout for Vision returns normal and anomalous images.
  --created-before: string # Only includes entries before the specified date in the response. For example, 2020-06-23T00:00:00. (format: date-time)
  --created-after: string # Only includes entries after the specified date in the response. For example, 2020-06-23T00:00:00. (format: date-time)
  --next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of dataset entries.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
  --source-ref-contains: string # Perform a "contains" search on the values of the source-ref key within the dataset. For example a value of "IMG_17" returns all JSON Lines where the source-ref key value matches *IMG_17*.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DatasetEntries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labeled" $labeled "scalar") (serialize-qp "anomalyClass" $anomaly_class "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "sourceRefContains" $source_ref_contains "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), dataset_type: (encode-path-segment $dataset_type)} | format pattern "/2020-11-20/projects/{project_name}/datasets/{dataset_type}/entries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds or updates one or more JSON Line entries in a dataset. A JSON Line includes information about an image used for training or testing an Amazon Lookout for Vision model. To update an existing JSON Line, use the source-ref field to identify the JSON Line. The JSON line that you supply replaces the existing JSON line. Any existing annotations that are not in the new JSON line are removed from the dataset. For more information, see Defining JSON lines for anomaly classification in the Amazon Lookout for Vision Developer Guide. The images you reference in the source-ref field of a JSON line, must be in the same S3 bucket as the existing images in the dataset. Updating a dataset might take a while to complete. To check the current status, call DescribeDataset and check the Status field in the response. This operation requires permissions to perform the lookoutvision:UpdateDatasetEntries operation.
#
# PATCH /2020-11-20/projects/{projectName}/datasets/{datasetType}/entries
# operationId: UpdateDatasetEntries
export def "2020-11-20-projects-datasets-entries update" [
  project_name: string
  dataset_type: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to UpdateDatasetEntries completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from UpdateDatasetEntries. In this case, safely retry your call to UpdateDatasetEntries by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple updates with the same dataset entries. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to UpdateDatasetEntries. An idempotency token is active for 8 hours.
  changes: string # The entries to add to the dataset.
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), dataset_type: (encode-path-segment $dataset_type)} | format pattern "/2020-11-20/projects/{project_name}/datasets/{dataset_type}/entries"))
  let req_body = {"Changes": $changes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the model packaging jobs created for an Amazon Lookout for Vision project. This operation requires permissions to perform the lookoutvision:ListModelPackagingJobs operation. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# GET /2020-11-20/projects/{projectName}/modelpackagingjobs
# operationId: ListModelPackagingJobs
export def "2020-11-20-projects-modelpackagingjobs list-model-packaging-jobs" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the previous response was incomplete (because there is more results to retrieve), Amazon Lookout for Vision returns a pagination token in the response. You can use this pagination token to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per paginated call. The largest value you can specify is 100. If you specify a value greater than 100, a ValidationException error occurs. The default value is 100.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ModelPackagingJobs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}/modelpackagingjobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Starts an Amazon Lookout for Vision model packaging job. A model packaging job creates an AWS IoT Greengrass component for a Lookout for Vision model. You can use the component to deploy your model to an edge device managed by Greengrass. Use the DescribeModelPackagingJob API to determine the current status of the job. The model packaging job is complete if the value of Status is SUCCEEDED. To deploy the component to the target device, use the component name and component version with the AWS IoT Greengrass CreateDeployment (https://docs.aws.amazon.com/greengrass/v2/APIReference/API_CreateDeployment.html) API. This operation requires the following permissions: lookoutvision:StartModelPackagingJob s3:PutObject s3:GetBucketLocation kms:GenerateDataKey greengrass:CreateComponentVersion greengrass:DescribeComponent (Optional) greengrass:TagResource. Only required if you want to tag the component. For more information, see Using your Amazon Lookout for Vision model on an edge device in the Amazon Lookout for Vision Developer Guide.
#
# POST /2020-11-20/projects/{projectName}/modelpackagingjobs
# operationId: StartModelPackagingJob
# --Configuration shape: {Greengrass?: any}
export def "2020-11-20-projects-modelpackagingjobs start-model-packaging-job" [
  project_name: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StartModelPackagingJob completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StartModelPackagingJob. In this case, safely retry your call to StartModelPackagingJob by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple dataset creation requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StartModelPackagingJob. An idempotency token is active for 8 hours.
  model_version: string # The version of the model within the project that you want to package.
  --job-name: string # A name for the model packaging job. If you don't supply a value, the service creates a job name for you.
  configuration: record # Configuration information for a Amazon Lookout for Vision model packaging job. For more information, see StartModelPackagingJob. — shape: {Greengrass?: any}
  --description: string # A description for the model packaging job.
]: any -> record<JobName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/2020-11-20/projects/{project_name}/modelpackagingjobs"))
  let req_body = {"ModelVersion": $model_version, "JobName": $job_name, "Configuration": $configuration, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of tags attached to the specified Amazon Lookout for Vision model. This operation requires permissions to perform the lookoutvision:ListTagsForResource operation.
#
# GET /2020-11-20/tags/{resourceArn}
# operationId: ListTagsForResource
export def "2020-11-20-tags list-for-resource" [
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-11-20/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds one or more key-value tags to an Amazon Lookout for Vision model. For more information, see Tagging a model in the Amazon Lookout for Vision Developer Guide. This operation requires permissions to perform the lookoutvision:TagResource operation.
#
# POST /2020-11-20/tags/{resourceArn}
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "2020-11-20-tags tag-resource" [
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
  tags: list # The key-value tags to assign to the model. — item shape: {Key: any, Value: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-11-20/tags/{resource_arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts the running of the version of an Amazon Lookout for Vision model. Starting a model takes a while to complete. To check the current state of the model, use DescribeModel. A model is ready to use when its status is HOSTED. Once the model is running, you can detect custom labels in new images by calling DetectAnomalies. You are charged for the amount of time that the model is running. To stop a running model, call StopModel. This operation requires permissions to perform the lookoutvision:StartModel operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/start
# operationId: StartModel
export def "2020-11-20-projects-models-start start" [
  project_name: string
  model_version: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StartModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StartModel. In this case, safely retry your call to StartModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple start requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StartModel. An idempotency token is active for 8 hours.
  min_inference_units: int # The minimum number of inference units to use. A single inference unit represents 1 hour of processing. Use a higher number to increase the TPS throughput of your model. You are charged for the number of inference units that you use.
  --max-inference-units: int # The maximum number of inference units to use for auto-scaling the model. If you don't specify a value, Amazon Lookout for Vision doesn't auto-scale the model.
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), model_version: (encode-path-segment $model_version)} | format pattern "/2020-11-20/projects/{project_name}/models/{model_version}/start"))
  let req_body = {"MinInferenceUnits": $min_inference_units, "MaxInferenceUnits": $max_inference_units} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stops the hosting of a running model. The operation might take a while to complete. To check the current status, call DescribeModel. After the model hosting stops, the Status of the model is TRAINED. This operation requires permissions to perform the lookoutvision:StopModel operation.
#
# POST /2020-11-20/projects/{projectName}/models/{modelVersion}/stop
# operationId: StopModel
export def "2020-11-20-projects-models-stop stop" [
  project_name: string
  model_version: string
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
  --x-amzn-client-token: string # ClientToken is an idempotency token that ensures a call to StopModel completes only once. You choose the value to pass. For example, An issue might prevent you from getting a response from StopModel. In this case, safely retry your call to StopModel by using the same ClientToken parameter value. If you don't supply a value for ClientToken, the AWS SDK you are using inserts a value for you. This prevents retries after a network error from making multiple stop requests. You'll need to provide your own value for other use cases. An error occurs if the other input parameters are not the same as in the first request. Using a different value for ClientToken is considered a new call to StopModel. An idempotency token is active for 8 hours.
]: nothing -> record<Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), model_version: (encode-path-segment $model_version)} | format pattern "/2020-11-20/projects/{project_name}/models/{model_version}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amzn-Client-Token": $x_amzn_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Removes one or more tags from an Amazon Lookout for Vision model. For more information, see Tagging a model in the Amazon Lookout for Vision Developer Guide. This operation requires permissions to perform the lookoutvision:UntagResource operation.
#
# DELETE /2020-11-20/tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "2020-11-20-tags untag-resource" [
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
  --tag-keys: list # A list of the keys of the tags that you want to remove.
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
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-11-20/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
