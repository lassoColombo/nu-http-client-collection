# Auto-generated client for Amazon CodeGuru Reviewer v2019-09-19
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codeguru-reviewer/2019-09-19/openapi.json
# Auth: --token flag or $env.AMAZON_CODEGURU_REVIEWER_TOKEN

const BASE_URL = "http://codeguru-reviewer.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CODEGURU_REVIEWER_TOKEN | default "" }
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

def base-url-completer [] { ["http://codeguru-reviewer.us-east-1.amazonaws.com" "http://codeguru-reviewer.us-east-2.amazonaws.com" "http://codeguru-reviewer.us-west-1.amazonaws.com" "http://codeguru-reviewer.us-west-2.amazonaws.com" "http://codeguru-reviewer.us-gov-west-1.amazonaws.com" "http://codeguru-reviewer.us-gov-east-1.amazonaws.com" "http://codeguru-reviewer.ca-central-1.amazonaws.com" "http://codeguru-reviewer.eu-north-1.amazonaws.com" "http://codeguru-reviewer.eu-west-1.amazonaws.com" "http://codeguru-reviewer.eu-west-2.amazonaws.com" "http://codeguru-reviewer.eu-west-3.amazonaws.com" "http://codeguru-reviewer.eu-central-1.amazonaws.com" "http://codeguru-reviewer.eu-south-1.amazonaws.com" "http://codeguru-reviewer.af-south-1.amazonaws.com" "http://codeguru-reviewer.ap-northeast-1.amazonaws.com" "http://codeguru-reviewer.ap-northeast-2.amazonaws.com" "http://codeguru-reviewer.ap-northeast-3.amazonaws.com" "http://codeguru-reviewer.ap-southeast-1.amazonaws.com" "http://codeguru-reviewer.ap-southeast-2.amazonaws.com" "http://codeguru-reviewer.ap-east-1.amazonaws.com" "http://codeguru-reviewer.ap-south-1.amazonaws.com" "http://codeguru-reviewer.sa-east-1.amazonaws.com" "http://codeguru-reviewer.me-south-1.amazonaws.com" "https://codeguru-reviewer.us-east-1.amazonaws.com" "https://codeguru-reviewer.us-east-2.amazonaws.com" "https://codeguru-reviewer.us-west-1.amazonaws.com" "https://codeguru-reviewer.us-west-2.amazonaws.com" "https://codeguru-reviewer.us-gov-west-1.amazonaws.com" "https://codeguru-reviewer.us-gov-east-1.amazonaws.com" "https://codeguru-reviewer.ca-central-1.amazonaws.com" "https://codeguru-reviewer.eu-north-1.amazonaws.com" "https://codeguru-reviewer.eu-west-1.amazonaws.com" "https://codeguru-reviewer.eu-west-2.amazonaws.com" "https://codeguru-reviewer.eu-west-3.amazonaws.com" "https://codeguru-reviewer.eu-central-1.amazonaws.com" "https://codeguru-reviewer.eu-south-1.amazonaws.com" "https://codeguru-reviewer.af-south-1.amazonaws.com" "https://codeguru-reviewer.ap-northeast-1.amazonaws.com" "https://codeguru-reviewer.ap-northeast-2.amazonaws.com" "https://codeguru-reviewer.ap-northeast-3.amazonaws.com" "https://codeguru-reviewer.ap-southeast-1.amazonaws.com" "https://codeguru-reviewer.ap-southeast-2.amazonaws.com" "https://codeguru-reviewer.ap-east-1.amazonaws.com" "https://codeguru-reviewer.ap-south-1.amazonaws.com" "https://codeguru-reviewer.sa-east-1.amazonaws.com" "https://codeguru-reviewer.me-south-1.amazonaws.com" "http://codeguru-reviewer.cn-north-1.amazonaws.com.cn" "http://codeguru-reviewer.cn-northwest-1.amazonaws.com.cn" "https://codeguru-reviewer.cn-north-1.amazonaws.com.cn" "https://codeguru-reviewer.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["PullRequest" "RepositoryAnalysis"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "associations create-associate-repository" } } | get name | first)
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

# Use to associate an Amazon Web Services CodeCommit repository or a repository managed by Amazon Web Services CodeStar Connections with Amazon CodeGuru Reviewer. When you associate a repository, CodeGuru Reviewer reviews source code changes in the repository's pull requests and provides automatic recommendations. You can view recommendations using the CodeGuru Reviewer console. For more information, see Recommendations in Amazon CodeGuru Reviewer (https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/recommendations.html) in the Amazon CodeGuru Reviewer User Guide. If you associate a CodeCommit or S3 repository, it must be in the same Amazon Web Services Region and Amazon Web Services account where its CodeGuru Reviewer code reviews are configured. Bitbucket and GitHub Enterprise Server repositories are managed by Amazon Web Services CodeStar Connections to connect to CodeGuru Reviewer. For more information, see Associate a repository (https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/getting-started-associate-repository.html) in the Amazon CodeGuru Reviewer User Guide. You cannot use the CodeGuru Reviewer SDK or the Amazon Web Services CLI to associate a GitHub repository with Amazon CodeGuru Reviewer. To associate a GitHub repository, use the console. For more information, see Getting started with CodeGuru Reviewer (https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/getting-started-with-guru.html) in the CodeGuru Reviewer User Guide.
#
# POST /associations
# operationId: AssociateRepository
# --Repository shape: {CodeCommit?: any, Bitbucket?: any, GitHubEnterpriseServer?: any, S3Bucket?: record}
# --KMSKeyDetails shape: {KMSKeyId?: any, EncryptionOption?: any}
export def "associations create-associate-repository" [
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
  repository: record # Information about an associated Amazon Web Services CodeCommit repository or an associated repository that is managed by Amazon Web Services CodeStar Connections (for example, Bitbucket). This Repository object is not used if your source code is in an associated GitHub repository. — shape: {CodeCommit?: any, Bitbucket?: any, GitHubEnterpriseServer?: any, S3Bucket?: record}
  --client-request-token: string # Amazon CodeGuru Reviewer uses this value to prevent the accidental creation of duplicate repository associations if there are failures and retries.
  --tags: record # An array of key-value pairs used to tag an associated repository. A tag is a custom attribute label with two parts: A tag key (for example, CostCenter, Environment, Project, or Secret). Tag keys are case sensitive. An optional field known as a tag value (for example, 111122223333, Production, or a team name). Omitting the tag value is the same as using an empty string. Like tag keys, tag values are case sensitive.
  --kms-key-details: record # An object that contains: The encryption option for a repository association. It is either owned by Amazon Web Services Key Management Service (KMS) (AWS_OWNED_CMK) or customer managed (CUSTOMER_MANAGED_CMK). The ID of the Amazon Web Services KMS key that is associated with a repository association. — shape: {KMSKeyId?: any, EncryptionOption?: any}
]: any -> record<RepositoryAssociation: record<AssociationId: record, AssociationArn: record, ConnectionArn: record, Name: record, Owner: record, ProviderType: record, State: record, StateReason: record, LastUpdatedTimeStamp: record, CreatedTimeStamp: record, KMSKeyDetails: record<KMSKeyId: record, EncryptionOption: record>, S3RepositoryDetails: record<BucketName: record, CodeArtifacts: record>>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/associations")
  let req_body = {"Repository": $repository, "ClientRequestToken": $client_request_token, "Tags": $tags, "KMSKeyDetails": $kms_key_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of RepositoryAssociationSummary (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociationSummary.html) objects that contain summary information about a repository association. You can filter the returned list by ProviderType (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociationSummary.html#reviewer-Type-RepositoryAssociationSummary-ProviderType), Name (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociationSummary.html#reviewer-Type-RepositoryAssociationSummary-Name), State (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociationSummary.html#reviewer-Type-RepositoryAssociationSummary-State), and Owner (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociationSummary.html#reviewer-Type-RepositoryAssociationSummary-Owner).
#
# GET /associations
# operationId: ListRepositoryAssociations
export def "associations list-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-type: list # List of provider types to use as a filter.
  --state: list # List of repository association states to use as a filter. The valid repository association states are: Associated: The repository association is complete. Associating: CodeGuru Reviewer is: Setting up pull request notifications. This is required for pull requests to trigger a CodeGuru Reviewer review. If your repository ProviderType is GitHub, GitHub Enterprise Server, or Bitbucket, CodeGuru Reviewer creates webhooks in your repository to trigger CodeGuru Reviewer reviews. If you delete these webhooks, reviews of code in your repository cannot be triggered. Setting up source code access. This is required for CodeGuru Reviewer to securely clone code in your repository. Failed: The repository failed to associate or disassociate. Disassociating: CodeGuru Reviewer is removing the repository's pull request notifications and source code access. Disassociated: CodeGuru Reviewer successfully disassociated the repository. You can create a new association with this repository if you want to review source code in it later. You can control access to code reviews created in anassociated repository with tags after it has been disassociated. For more information, see Using tags to control access to associated repositories (https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/auth-and-access-control-using-tags.html) in the Amazon CodeGuru Reviewer User Guide.
  --name: list # List of repository names to use as a filter.
  --owner: list # List of owners to use as a filter. For Amazon Web Services CodeCommit, it is the name of the CodeCommit account that was used to associate the repository. For other repository source providers, such as Bitbucket and GitHub Enterprise Server, this is name of the account that was used to associate the repository.
  --max-results: int # The maximum number of repository association results returned by ListRepositoryAssociations in paginated output. When this parameter is used, ListRepositoryAssociations only returns maxResults results in a single page with a nextToken response element. The remaining results of the initial request can be seen by sending another ListRepositoryAssociations request with the returned nextToken value. This value can be between 1 and 100. If this parameter is not used, ListRepositoryAssociations returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListRepositoryAssociations request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. Treat this token as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RepositoryAssociationSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProviderType" $provider_type "multi") (serialize-qp "State" $state "multi") (serialize-qp "Name" $name "multi") (serialize-qp "Owner" $owner "multi") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/associations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use to create a code review with a CodeReviewType (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_CodeReviewType.html) of RepositoryAnalysis. This type of code review analyzes all code under a specified branch in an associated repository. PullRequest code reviews are automatically triggered by a pull request.
#
# POST /codereviews
# operationId: CreateCodeReview
# --Type shape: {RepositoryAnalysis?: any, AnalysisTypes?: any}
export def "codereviews create-code-review" [
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
  name: string # The name of the code review. The name of each code review in your Amazon Web Services account must be unique.
  repository_association_arn: string # The Amazon Resource Name (ARN) of the RepositoryAssociation (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociation.html) object. You can retrieve this ARN by calling ListRepositoryAssociations (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_ListRepositoryAssociations.html). A code review can only be created on an associated repository. This is the ARN of the associated repository.
  type: record # The type of a code review. There are two code review types: PullRequest - A code review that is automatically triggered by a pull request on an associated repository. RepositoryAnalysis - A code review that analyzes all code under a specified branch in an associated repository. The associated repository is specified using its ARN in CreateCodeReview (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_CreateCodeReview). — shape: {RepositoryAnalysis?: any, AnalysisTypes?: any}
  --client-request-token: string # Amazon CodeGuru Reviewer uses this value to prevent the accidental creation of duplicate code reviews if there are failures and retries.
]: any -> record<CodeReview: record<Name: record, CodeReviewArn: record, RepositoryName: record, Owner: record, ProviderType: record, State: record, StateReason: record, CreatedTimeStamp: record, LastUpdatedTimeStamp: record, Type: record, PullRequestId: record, SourceCodeType: record<CommitDiff: record, RepositoryHead: record, BranchDiff: record, S3BucketRepository: record, RequestMetadata: record>, AssociationArn: record, Metrics: record<MeteredLinesOfCodeCount: record, SuppressedLinesOfCodeCount: record, FindingsCount: record>, AnalysisTypes: record, ConfigFileState: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/codereviews")
  let req_body = {"Name": $name, "RepositoryAssociationArn": $repository_association_arn, "Type": $type, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the metadata associated with the code review along with its status.
#
# GET /codereviews/{CodeReviewArn}
# operationId: DescribeCodeReview
export def "codereviews get-code-review" [
  code_review_arn: string
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
]: nothing -> record<CodeReview: record<Name: record, CodeReviewArn: record, RepositoryName: record, Owner: record, ProviderType: record, State: record, StateReason: record, CreatedTimeStamp: record, LastUpdatedTimeStamp: record, Type: record, PullRequestId: record, SourceCodeType: record<CommitDiff: record, RepositoryHead: record, BranchDiff: record, S3BucketRepository: record, RequestMetadata: record>, AssociationArn: record, Metrics: record<MeteredLinesOfCodeCount: record, SuppressedLinesOfCodeCount: record, FindingsCount: record>, AnalysisTypes: record, ConfigFileState: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code_review_arn: (encode-path-segment $code_review_arn)} | format pattern "/codereviews/{code_review_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the customer feedback for a CodeGuru Reviewer recommendation.
#
# GET /feedback/{CodeReviewArn}#RecommendationId
# operationId: DescribeRecommendationFeedback
export def "feedback get-recommendation" [
  code_review_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recommendation-id: string # The recommendation ID that can be used to track the provided recommendations and then to collect the feedback.
  --user-id: string # Optional parameter to describe the feedback for a given user. If this is not supplied, it defaults to the user making the request. The UserId is an IAM principal that can be specified as an Amazon Web Services account ID or an Amazon Resource Name (ARN). For more information, see Specifying a Principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#Principal_specifying) in the Amazon Web Services Identity and Access Management User Guide.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RecommendationFeedback: record<CodeReviewArn: record, RecommendationId: record, Reactions: record, UserId: record, CreatedTimeStamp: record, LastUpdatedTimeStamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RecommendationId" $recommendation_id "scalar") (serialize-qp "UserId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code_review_arn: (encode-path-segment $code_review_arn)} | format pattern "/feedback/{code_review_arn}#RecommendationId") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a RepositoryAssociation (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RepositoryAssociation.html) object that contains information about the requested repository association.
#
# GET /associations/{AssociationArn}
# operationId: DescribeRepositoryAssociation
export def "associations get-repository" [
  association_arn: string
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
]: nothing -> record<RepositoryAssociation: record<AssociationId: record, AssociationArn: record, ConnectionArn: record, Name: record, Owner: record, ProviderType: record, State: record, StateReason: record, LastUpdatedTimeStamp: record, CreatedTimeStamp: record, KMSKeyDetails: record<KMSKeyId: record, EncryptionOption: record>, S3RepositoryDetails: record<BucketName: record, CodeArtifacts: record>>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({association_arn: (encode-path-segment $association_arn)} | format pattern "/associations/{association_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the association between Amazon CodeGuru Reviewer and a repository.
#
# DELETE /associations/{AssociationArn}
# operationId: DisassociateRepository
export def "associations delete-disassociate-repository" [
  association_arn: string
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
]: nothing -> record<RepositoryAssociation: record<AssociationId: record, AssociationArn: record, ConnectionArn: record, Name: record, Owner: record, ProviderType: record, State: record, StateReason: record, LastUpdatedTimeStamp: record, CreatedTimeStamp: record, KMSKeyDetails: record<KMSKeyId: record, EncryptionOption: record>, S3RepositoryDetails: record<BucketName: record, CodeArtifacts: record>>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({association_arn: (encode-path-segment $association_arn)} | format pattern "/associations/{association_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the code reviews that the customer has created in the past 90 days.
#
# GET /codereviews#Type
# operationId: ListCodeReviews
export def "codereviews-type list-code-reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-types: list # List of provider types for filtering that needs to be applied before displaying the result. For example, providerTypes=[GitHub] lists code reviews from GitHub.
  --states: list # List of states for filtering that needs to be applied before displaying the result. For example, states=[Pending] lists code reviews in the Pending state. The valid code review states are: Completed: The code review is complete. Pending: The code review started and has not completed or failed. Failed: The code review failed. Deleting: The code review is being deleted.
  --repository-names: list # List of repository names for filtering that needs to be applied before displaying the result.
  --type: string@type-completer # The type of code reviews to list in the response.
  --max-results: int # The maximum number of results that are returned per call. The default is 100.
  --next-token: string # If nextToken is returned, there are more results available. The value of nextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CodeReviewSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProviderTypes" $provider_types "multi") (serialize-qp "States" $states "multi") (serialize-qp "RepositoryNames" $repository_names "multi") (serialize-qp "Type" $type "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codereviews#Type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of RecommendationFeedbackSummary (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_RecommendationFeedbackSummary.html) objects that contain customer recommendation feedback for all CodeGuru Reviewer users.
#
# GET /feedback/{CodeReviewArn}/RecommendationFeedback
# operationId: ListRecommendationFeedback
export def "feedback-recommendation-feedback list" [
  code_review_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If nextToken is returned, there are more results available. The value of nextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged.
  --max-results: int # The maximum number of results that are returned per call. The default is 100.
  --user-ids: list # An Amazon Web Services user's account ID or Amazon Resource Name (ARN). Use this ID to query the recommendation feedback for a code review from that user. The UserId is an IAM principal that can be specified as an Amazon Web Services account ID or an Amazon Resource Name (ARN). For more information, see Specifying a Principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#Principal_specifying) in the Amazon Web Services Identity and Access Management User Guide.
  --recommendation-ids: list # Used to query the recommendation feedback for a given recommendation.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RecommendationFeedbackSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "UserIds" $user_ids "multi") (serialize-qp "RecommendationIds" $recommendation_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({code_review_arn: (encode-path-segment $code_review_arn)} | format pattern "/feedback/{code_review_arn}/RecommendationFeedback") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of all recommendations for a completed code review.
#
# GET /codereviews/{CodeReviewArn}/Recommendations
# operationId: ListRecommendations
export def "codereviews-recommendations list" [
  code_review_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token.
  --max-results: int # The maximum number of results that are returned per call. The default is 100.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RecommendationSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code_review_arn: (encode-path-segment $code_review_arn)} | format pattern "/codereviews/{code_review_arn}/Recommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of tags associated with an associated repository resource.
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds one or more tags to an associated repository.
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
  tags: record # An array of key-value pairs used to tag an associated repository. A tag is a custom attribute label with two parts: A tag key (for example, CostCenter, Environment, Project, or Secret). Tag keys are case sensitive. An optional field known as a tag value (for example, 111122223333, Production, or a team name). Omitting the tag value is the same as using an empty string. Like tag keys, tag values are case sensitive.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stores customer feedback for a CodeGuru Reviewer recommendation. When this API is called again with different reactions the previous feedback is overwritten.
#
# PUT /feedback
# operationId: PutRecommendationFeedback
export def "feedback update-recommendation" [
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
  code_review_arn: string # The Amazon Resource Name (ARN) of the CodeReview (https://docs.aws.amazon.com/codeguru/latest/reviewer-api/API_CodeReview.html) object.
  recommendation_id: string # The recommendation ID that can be used to track the provided recommendations and then to collect the feedback.
  reactions: list<string> # List for storing reactions. Reactions are utf-8 text code for emojis. If you send an empty list it clears all your feedback.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feedback")
  let req_body = {"CodeReviewArn": $code_review_arn, "RecommendationId": $recommendation_id, "Reactions": $reactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a tag from an associated repository.
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
  --tag-keys: list # A list of the keys for each tag you want to remove from an associated repository.
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
