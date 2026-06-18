# Auto-generated client for AWS Resource Groups Tagging API v2017-01-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/resourcegroupstaggingapi/2017-01-26/openapi.json
# Auth: --token flag or $env.AWS_RESOURCE_GROUPS_TAGGING_API_TOKEN

const BASE_URL = "http://tagging.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_RESOURCE_GROUPS_TAGGING_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://tagging.us-east-1.amazonaws.com" "http://tagging.us-east-2.amazonaws.com" "http://tagging.us-west-1.amazonaws.com" "http://tagging.us-west-2.amazonaws.com" "http://tagging.us-gov-west-1.amazonaws.com" "http://tagging.us-gov-east-1.amazonaws.com" "http://tagging.ca-central-1.amazonaws.com" "http://tagging.eu-north-1.amazonaws.com" "http://tagging.eu-west-1.amazonaws.com" "http://tagging.eu-west-2.amazonaws.com" "http://tagging.eu-west-3.amazonaws.com" "http://tagging.eu-central-1.amazonaws.com" "http://tagging.eu-south-1.amazonaws.com" "http://tagging.af-south-1.amazonaws.com" "http://tagging.ap-northeast-1.amazonaws.com" "http://tagging.ap-northeast-2.amazonaws.com" "http://tagging.ap-northeast-3.amazonaws.com" "http://tagging.ap-southeast-1.amazonaws.com" "http://tagging.ap-southeast-2.amazonaws.com" "http://tagging.ap-east-1.amazonaws.com" "http://tagging.ap-south-1.amazonaws.com" "http://tagging.sa-east-1.amazonaws.com" "http://tagging.me-south-1.amazonaws.com" "https://tagging.us-east-1.amazonaws.com" "https://tagging.us-east-2.amazonaws.com" "https://tagging.us-west-1.amazonaws.com" "https://tagging.us-west-2.amazonaws.com" "https://tagging.us-gov-west-1.amazonaws.com" "https://tagging.us-gov-east-1.amazonaws.com" "https://tagging.ca-central-1.amazonaws.com" "https://tagging.eu-north-1.amazonaws.com" "https://tagging.eu-west-1.amazonaws.com" "https://tagging.eu-west-2.amazonaws.com" "https://tagging.eu-west-3.amazonaws.com" "https://tagging.eu-central-1.amazonaws.com" "https://tagging.eu-south-1.amazonaws.com" "https://tagging.af-south-1.amazonaws.com" "https://tagging.ap-northeast-1.amazonaws.com" "https://tagging.ap-northeast-2.amazonaws.com" "https://tagging.ap-northeast-3.amazonaws.com" "https://tagging.ap-southeast-1.amazonaws.com" "https://tagging.ap-southeast-2.amazonaws.com" "https://tagging.ap-east-1.amazonaws.com" "https://tagging.ap-south-1.amazonaws.com" "https://tagging.sa-east-1.amazonaws.com" "https://tagging.me-south-1.amazonaws.com" "http://tagging.cn-north-1.amazonaws.com.cn" "http://tagging.cn-northwest-1.amazonaws.com.cn" "https://tagging.cn-north-1.amazonaws.com.cn" "https://tagging.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["ResourceGroupsTaggingAPI_20170126.DescribeReportCreation"] }
def x-amz-target-completer-1 [] { ["ResourceGroupsTaggingAPI_20170126.GetComplianceSummary"] }
def x-amz-target-completer-2 [] { ["ResourceGroupsTaggingAPI_20170126.GetResources"] }
def x-amz-target-completer-3 [] { ["ResourceGroupsTaggingAPI_20170126.GetTagKeys"] }
def x-amz-target-completer-4 [] { ["ResourceGroupsTaggingAPI_20170126.GetTagValues"] }
def x-amz-target-completer-5 [] { ["ResourceGroupsTaggingAPI_20170126.StartReportCreation"] }
def x-amz-target-completer-6 [] { ["ResourceGroupsTaggingAPI_20170126.TagResources"] }
def x-amz-target-completer-7 [] { ["ResourceGroupsTaggingAPI_20170126.UntagResources"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-resource-groups-tagging-api-20170126-describe-report-creation get" } } | get name | first)
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

# Describes the status of the StartReportCreation operation. You can call this operation only from the organization's management account and from the us-east-1 Region.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.DescribeReportCreation
# operationId: DescribeReportCreation
export def "x-amz-target-resource-groups-tagging-api-20170126-describe-report-creation get" [
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
  --x-amz-target: string@x-amz-target-completer
  --body: record
]: any -> record<Status: record, S3Location: record, ErrorMessage: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.DescribeReportCreation")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a table that shows counts of resources that are noncompliant with their tag policies. For more information on tag policies, see Tag Policies (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) in the Organizations User Guide. You can call this operation only from the organization's management account and from the us-east-1 Region. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetComplianceSummary
# operationId: GetComplianceSummary
export def "x-amz-target-resource-groups-tagging-api-20170126-get-compliance-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1
  --target-id-filters: any
  --region-filters: any
  --resource-type-filters: any
  --tag-key-filters: any
  --group-by: any
  --max-results: any
  --pagination-token: any
]: any -> record<SummaryList: record, PaginationToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetComplianceSummary" $qp)
  let req_body = {"TargetIdFilters": $target_id_filters, "RegionFilters": $region_filters, "ResourceTypeFilters": $resource_type_filters, "TagKeyFilters": $tag_key_filters, "GroupBy": $group_by, "MaxResults": $max_results, "PaginationToken": $pagination_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all the tagged or previously tagged resources that are located in the specified Amazon Web Services Region for the account. Depending on what information you want returned, you can also specify the following: Filters that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources. Information about compliance with the account's effective tag policy. For more information on tag policies, see Tag Policies (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) in the Organizations User Guide. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources
# operationId: GetResources
export def "x-amz-target-resource-groups-tagging-api-20170126-get-resources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources-per-page: string # Pagination limit
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2
  --pagination-token: any
  --tag-filters: any
  --resources-per-page: any
  --tags-per-page: any
  --resource-type-filters: any
  --include-compliance-details: any
  --exclude-compliant-resources: any
  --resource-arn-list: any
]: any -> record<PaginationToken: record, ResourceTagMappingList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ResourcesPerPage" $resources_per_page "scalar") (serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources" $qp)
  let req_body = {"PaginationToken": $pagination_token, "TagFilters": $tag_filters, "ResourcesPerPage": $resources_per_page, "TagsPerPage": $tags_per_page, "ResourceTypeFilters": $resource_type_filters, "IncludeComplianceDetails": $include_compliance_details, "ExcludeCompliantResources": $exclude_compliant_resources, "ResourceARNList": $resource_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all tag keys currently in use in the specified Amazon Web Services Region for the calling account. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys
# operationId: GetTagKeys
export def "x-amz-target-resource-groups-tagging-api-20170126-get-tag-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3
  --pagination-token: any
]: any -> record<PaginationToken: record, TagKeys: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys" $qp)
  let req_body = {"PaginationToken": $pagination_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all tag values for the specified key that are used in the specified Amazon Web Services Region for the calling account. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues
# operationId: GetTagValues
export def "x-amz-target-resource-groups-tagging-api-20170126-get-tag-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4
  --pagination-token: any
  key: any
]: any -> record<PaginationToken: record, TagValues: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues" $qp)
  let req_body = {"PaginationToken": $pagination_token, "Key": $key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Generates a report that lists all tagged resources in the accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. The report is generated asynchronously. The generated report is saved to the following location: s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv You can call this operation only from the organization's management account and from the us-east-1 Region.
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.StartReportCreation
# operationId: StartReportCreation
export def "x-amz-target-resource-groups-tagging-api-20170126-start-report-creation start" [
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
  --x-amz-target: string@x-amz-target-completer-5
  s3_bucket: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.StartReportCreation")
  let req_body = {"S3Bucket": $s3_bucket} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Applies one or more tags to the specified resources. Note the following: Not all resources can have tags. For a list of services with resources that support tagging using this operation, see Services that support the Resource Groups Tagging API (https://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/supported-services.html). If the resource doesn't yet support this operation, the resource's service might support tagging using its own API operations. For more information, refer to the documentation for that service. Each resource can have up to 50 tags. For other limits, see Tag Naming and Usage Conventions (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions) in the Amazon Web Services General Reference. You can only tag resources that are located in the specified Amazon Web Services Region for the Amazon Web Services account. To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see the documentation for each service. Do not store personally identifiable information (PII) or other confidential or sensitive information in tags. We use tags to provide you with billing and administration services. Tags are not intended to be used for private or sensitive data. Minimum permissions In addition to the tag:TagResources permission required by this operation, you must also have the tagging permission defined by the service that created the resource. For example, to tag an Amazon EC2 instance using the TagResources operation, you must have both of the following permissions: tag:TagResource ec2:CreateTags
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources
# operationId: TagResources
export def "x-amz-target-resource-groups-tagging-api-20170126-tag-resources tag" [
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
  --x-amz-target: string@x-amz-target-completer-6
  resource_arn_list: any
  tags: any
]: any -> record<FailedResourcesMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources")
  let req_body = {"ResourceARNList": $resource_arn_list, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following: To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see the documentation for the service whose resource you want to untag. You can only tag resources that are located in the specified Amazon Web Services Region for the calling Amazon Web Services account. Minimum permissions In addition to the tag:UntagResources permission required by this operation, you must also have the remove tags permission defined by the service that created the resource. For example, to remove the tags from an Amazon EC2 instance using the UntagResources operation, you must have both of the following permissions: tag:UntagResource ec2:DeleteTags
#
# POST /#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources
# operationId: UntagResources
export def "x-amz-target-resource-groups-tagging-api-20170126-untag-resources untag" [
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
  --x-amz-target: string@x-amz-target-completer-7
  resource_arn_list: any
  tag_keys: any
]: any -> record<FailedResourcesMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources")
  let req_body = {"ResourceARNList": $resource_arn_list, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
