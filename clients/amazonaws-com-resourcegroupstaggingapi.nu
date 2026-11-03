# Auto-generated client for AWS Resource Groups Tagging API v2017-01-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/resourcegroupstaggingapi/2017-01-26/openapi.json
# Auth: --token flag or $env.AWS_RESOURCE_GROUPS_TAGGING_API_TOKEN

const BASE_URL = "http://tagging.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_RESOURCE_GROUPS_TAGGING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "describe-report-creation" } } | get name | first)
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
# POST /
# operationId: DescribeReportCreation
export def "describe-report-creation" [
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
  --x-amz-target: string@x-amz-target-completer # required
  --body: record
]: any -> record<Status: string, S3Location: string, ErrorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.DescribeReportCreation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a table that shows counts of resources that are noncompliant with their tag policies. For more information on tag policies, see Tag Policies (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) in the Organizations User Guide. You can call this operation only from the organization's management account and from the us-east-1 Region. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /
# operationId: GetComplianceSummary
export def "get-compliance-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  --target-id-filters: list<string> # Specifies target identifiers (usually, specific account IDs) to limit the output by. If you use this parameter, the count of returned noncompliant resources includes only resources with the specified target IDs.
  --region-filters: list<string> # Specifies a list of Amazon Web Services Regions to limit the output to. If you use this parameter, the count of returned noncompliant resources includes only resources in the specified Regions.
  --resource-type-filters: list<string> # Specifies that you want the response to include information for only resources of the specified types. The format of each resource type is service[:resourceType]. For example, specifying a resource type of ec2 returns all Amazon EC2 resources (which includes EC2 instances). Specifying a resource type of ec2:instance returns only EC2 instances. The string for each service name and resource type is the same as that embedded in a resource's Amazon Resource Name (ARN). Consult the Amazon Web Services General Reference (https://docs.aws.amazon.com/general/latest/gr/) for the following: For a list of service name strings, see Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-aws-service-namespaces). For resource type strings, see Example ARNs (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arns-syntax). For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html). You can specify multiple resource types by using a comma separated array. The array can include up to 100 items. Note that the length constraint requirement applies to each resource type filter.
  --tag-key-filters: list<string> # Specifies that you want the response to include information for only resources that have tags with the specified tag keys. If you use this parameter, the count of returned noncompliant resources includes only resources that have the specified tag keys.
  --group-by: list<string> # Specifies a list of attributes to group the counts of noncompliant resources by. If supplied, the counts are sorted by those attributes.
  --max-results-body: int # Specifies the maximum number of results to be returned in each page. A query can return fewer than this maximum, even if there are more results still to return. You should always check the PaginationToken response value to see if there are more results. You can specify a minimum of 1 and a maximum value of 100. (body field)
  --pagination-token-body: string # Specifies a PaginationToken response value from a previous request to indicate that you want the next page of results. Leave this parameter empty in your initial request. (body field)
]: any -> record<SummaryList: table<LastUpdated: string, TargetId: string, TargetIdType: string, Region: string, ResourceType: string, NonCompliantResources: int>, PaginationToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.GetComplianceSummary")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TargetIdFilters": $target_id_filters, "RegionFilters": $region_filters, "ResourceTypeFilters": $resource_type_filters, "TagKeyFilters": $tag_key_filters, "GroupBy": $group_by, "MaxResults": $max_results_body, "PaginationToken": $pagination_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "PaginationToken": $pagination_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all the tagged or previously tagged resources that are located in the specified Amazon Web Services Region for the account. Depending on what information you want returned, you can also specify the following: Filters that specify what tags and resource types you want returned. The response includes all tags that are associated with the requested resources. Information about compliance with the account's effective tag policy. For more information on tag policies, see Tag Policies (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) in the Organizations User Guide. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /
# operationId: GetResources
# --TagFilters item shape: {Key?: string, Values?: list<string>}
export def "get-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  --pagination-token-body: string # Specifies a PaginationToken response value from a previous request to indicate that you want the next page of results. Leave this parameter empty in your initial request. (body field)
  --tag-filters: list # Specifies a list of TagFilters (keys and values) to restrict the output to only those resources that have tags with the specified keys and, if included, the specified values. Each TagFilter must contain a key with values optional. A request can include up to 50 keys, and each key can include up to 20 values. Note the following when deciding how to use TagFilters: If you don't specify a TagFilter, the response includes all resources that are currently tagged or ever had a tag. Resources that currently don't have tags are shown with an empty tag set, like this: "Tags": []. If you specify more than one filter in a single request, the response returns only those resources that satisfy all filters. If you specify a filter that contains more than one value for a key, the response returns resources that match any of the specified values for that key. If you don't specify a value for a key, the response returns all resources that are tagged with that key, with any or no value. For example, for the following filters: filter1= {keyA,{value1}}, filter2={keyB,{value2,value3,value4}}, filter3= {keyC}: GetResources({filter1}) returns resources tagged with key1=value1 GetResources({filter2}) returns resources tagged with key2=value2 or key2=value3 or key2=value4 GetResources({filter3}) returns resources tagged with any tag with the key key3, and with any or no value GetResources({filter1,filter2,filter3}) returns resources tagged with (key1=value1) and (key2=value2 or key2=value3 or key2=value4) and (key3, any or no value) — item shape: {Key?: string, Values?: list<string>}
  --resources-per-page-body: int # Specifies the maximum number of results to be returned in each page. A query can return fewer than this maximum, even if there are more results still to return. You should always check the PaginationToken response value to see if there are more results. You can specify a minimum of 1 and a maximum value of 100. (body field)
  --tags-per-page: int # Amazon Web Services recommends using ResourcesPerPage instead of this parameter. A limit that restricts the number of tags (key and value pairs) returned by GetResources in paginated output. A resource with no tags is counted as having one tag (one key and value pair). GetResources does not split a resource and its associated tags across pages. If the specified TagsPerPage would cause such a break, a PaginationToken is returned in place of the affected resource and its tags. Use that token in another request to get the remaining data. For example, if you specify a TagsPerPage of 100 and the account has 22 resources with 10 tags each (meaning that each resource has 10 key and value pairs), the output will consist of three pages. The first page displays the first 10 resources, each with its 10 tags. The second page displays the next 10 resources, each with its 10 tags. The third page displays the remaining 2 resources, each with its 10 tags. You can set TagsPerPage to a minimum of 100 items up to a maximum of 500 items.
  --resource-type-filters: list<string> # Specifies the resource types that you want included in the response. The format of each resource type is service[:resourceType]. For example, specifying a resource type of ec2 returns all Amazon EC2 resources (which includes EC2 instances). Specifying a resource type of ec2:instance returns only EC2 instances. The string for each service name and resource type is the same as that embedded in a resource's Amazon Resource Name (ARN). For the list of services whose resources you can use in this parameter, see Services that support the Resource Groups Tagging API (https://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/supported-services.html). You can specify multiple resource types by using an array. The array can include up to 100 items. Note that the length constraint requirement applies to each resource type filter. For example, the following string would limit the response to only Amazon EC2 instances, Amazon S3 buckets, or any Audit Manager resource: ec2:instance,s3:bucket,auditmanager
  --include-compliance-details: oneof<nothing, bool> # Specifies whether to include details regarding the compliance with the effective tag policy. Set this to true to determine whether resources are compliant with the tag policy and to get details.
  --exclude-compliant-resources: oneof<nothing, bool> # Specifies whether to exclude resources that are compliant with the tag policy. Set this to true if you are interested in retrieving information on noncompliant resources only. You can use this parameter only if the IncludeComplianceDetails parameter is also set to true.
  --resource-arn-list: list<string> # Specifies a list of ARNs of resources for which you want to retrieve tag data. You can't specify both this parameter and any of the pagination parameters (ResourcesPerPage, TagsPerPage, PaginationToken) in the same request. If you specify both, you get an Invalid Parameter exception. If a resource specified by this parameter doesn't exist, it doesn't generate an error; it simply isn't included in the response. An ARN (Amazon Resource Name) uniquely identifies a resource. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
]: any -> record<PaginationToken: string, ResourceTagMappingList: table<ResourceARN: string, Tags: list, ComplianceDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.GetResources")
  let qp = [(serialize-qp "ResourcesPerPage" $resources_per_page "scalar") (serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"PaginationToken": $pagination_token_body, "TagFilters": $tag_filters, "ResourcesPerPage": $resources_per_page_body, "TagsPerPage": $tags_per_page, "ResourceTypeFilters": $resource_type_filters, "IncludeComplianceDetails": $include_compliance_details, "ExcludeCompliantResources": $exclude_compliant_resources, "ResourceARNList": $resource_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ResourcesPerPage": $resources_per_page, "PaginationToken": $pagination_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all tag keys currently in use in the specified Amazon Web Services Region for the calling account. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /
# operationId: GetTagKeys
export def "get-tag-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  --pagination-token-body: string # Specifies a PaginationToken response value from a previous request to indicate that you want the next page of results. Leave this parameter empty in your initial request. (body field)
]: any -> record<PaginationToken: string, TagKeys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.GetTagKeys")
  let qp = [(serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"PaginationToken": $pagination_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PaginationToken": $pagination_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all tag values for the specified key that are used in the specified Amazon Web Services Region for the calling account. This operation supports pagination, where the response can be sent in multiple pages. You should check the PaginationToken response parameter to determine if there are additional results available to return. Repeat the query, passing the PaginationToken response parameter value as an input to the next request until you recieve a null value. A null value for PaginationToken indicates that there are no more results waiting to be returned.
#
# POST /
# operationId: GetTagValues
export def "get-tag-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  --pagination-token-body: string # Specifies a PaginationToken response value from a previous request to indicate that you want the next page of results. Leave this parameter empty in your initial request. (body field)
  key: string # Specifies the tag key for which you want to list all existing values that are currently used in the specified Amazon Web Services Region for the calling account.
]: any -> record<PaginationToken: string, TagValues: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.GetTagValues")
  let qp = [(serialize-qp "PaginationToken" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"PaginationToken": $pagination_token_body, "Key": $key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PaginationToken": $pagination_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Generates a report that lists all tagged resources in the accounts across your organization and tells whether each resource is compliant with the effective tag policy. Compliance data is refreshed daily. The report is generated asynchronously. The generated report is saved to the following location: s3://example-bucket/AwsTagPolicies/o-exampleorgid/YYYY-MM-ddTHH:mm:ssZ/report.csv You can call this operation only from the organization's management account and from the us-east-1 Region.
#
# POST /
# operationId: StartReportCreation
export def "start-report-creation" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  s3_bucket: string # The name of the Amazon S3 bucket where the report will be stored; for example: awsexamplebucket For more information on S3 bucket requirements, including an example bucket policy, see the example S3 bucket policy on this page.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.StartReportCreation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"S3Bucket": $s3_bucket} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Applies one or more tags to the specified resources. Note the following: Not all resources can have tags. For a list of services with resources that support tagging using this operation, see Services that support the Resource Groups Tagging API (https://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/supported-services.html). If the resource doesn't yet support this operation, the resource's service might support tagging using its own API operations. For more information, refer to the documentation for that service. Each resource can have up to 50 tags. For other limits, see Tag Naming and Usage Conventions (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-conventions) in the Amazon Web Services General Reference. You can only tag resources that are located in the specified Amazon Web Services Region for the Amazon Web Services account. To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see the documentation for each service. Do not store personally identifiable information (PII) or other confidential or sensitive information in tags. We use tags to provide you with billing and administration services. Tags are not intended to be used for private or sensitive data. Minimum permissions In addition to the tag:TagResources permission required by this operation, you must also have the tagging permission defined by the service that created the resource. For example, to tag an Amazon EC2 instance using the TagResources operation, you must have both of the following permissions: tag:TagResource ec2:CreateTags
#
# POST /
# operationId: TagResources
export def "tag-resources" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  resource_arn_list: list<string> # Specifies the list of ARNs of the resources that you want to apply tags to. An ARN (Amazon Resource Name) uniquely identifies a resource. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tags: record # Specifies a list of tags that you want to add to the specified resources. A tag consists of a key and a value that you define.
]: any -> record<FailedResourcesMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.TagResources")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARNList": $resource_arn_list, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following: To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see the documentation for the service whose resource you want to untag. You can only tag resources that are located in the specified Amazon Web Services Region for the calling Amazon Web Services account. Minimum permissions In addition to the tag:UntagResources permission required by this operation, you must also have the remove tags permission defined by the service that created the resource. For example, to remove the tags from an Amazon EC2 instance using the UntagResources operation, you must have both of the following permissions: tag:UntagResource ec2:DeleteTags
#
# POST /
# operationId: UntagResources
export def "untag-resources" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  resource_arn_list: list<string> # Specifies a list of ARNs of the resources that you want to remove tags from. An ARN (Amazon Resource Name) uniquely identifies a resource. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tag_keys: list<string> # Specifies a list of tag keys that you want to remove from the specified resources.
]: any -> record<FailedResourcesMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ResourceGroupsTaggingAPI_20170126.UntagResources")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARNList": $resource_arn_list, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
