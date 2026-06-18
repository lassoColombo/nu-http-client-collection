# Auto-generated client for Amazon S3 on Outposts v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/s3outposts/2017-07-25/openapi.json
# Auth: --token flag or $env.AMAZON_S3_ON_OUTPOSTS_TOKEN

const BASE_URL = "http://s3-outposts.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_S3_ON_OUTPOSTS_TOKEN | default "" }
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

def base-url-completer [] { ["http://s3-outposts.us-east-1.amazonaws.com" "http://s3-outposts.us-east-2.amazonaws.com" "http://s3-outposts.us-west-1.amazonaws.com" "http://s3-outposts.us-west-2.amazonaws.com" "http://s3-outposts.us-gov-west-1.amazonaws.com" "http://s3-outposts.us-gov-east-1.amazonaws.com" "http://s3-outposts.ca-central-1.amazonaws.com" "http://s3-outposts.eu-north-1.amazonaws.com" "http://s3-outposts.eu-west-1.amazonaws.com" "http://s3-outposts.eu-west-2.amazonaws.com" "http://s3-outposts.eu-west-3.amazonaws.com" "http://s3-outposts.eu-central-1.amazonaws.com" "http://s3-outposts.eu-south-1.amazonaws.com" "http://s3-outposts.af-south-1.amazonaws.com" "http://s3-outposts.ap-northeast-1.amazonaws.com" "http://s3-outposts.ap-northeast-2.amazonaws.com" "http://s3-outposts.ap-northeast-3.amazonaws.com" "http://s3-outposts.ap-southeast-1.amazonaws.com" "http://s3-outposts.ap-southeast-2.amazonaws.com" "http://s3-outposts.ap-east-1.amazonaws.com" "http://s3-outposts.ap-south-1.amazonaws.com" "http://s3-outposts.sa-east-1.amazonaws.com" "http://s3-outposts.me-south-1.amazonaws.com" "https://s3-outposts.us-east-1.amazonaws.com" "https://s3-outposts.us-east-2.amazonaws.com" "https://s3-outposts.us-west-1.amazonaws.com" "https://s3-outposts.us-west-2.amazonaws.com" "https://s3-outposts.us-gov-west-1.amazonaws.com" "https://s3-outposts.us-gov-east-1.amazonaws.com" "https://s3-outposts.ca-central-1.amazonaws.com" "https://s3-outposts.eu-north-1.amazonaws.com" "https://s3-outposts.eu-west-1.amazonaws.com" "https://s3-outposts.eu-west-2.amazonaws.com" "https://s3-outposts.eu-west-3.amazonaws.com" "https://s3-outposts.eu-central-1.amazonaws.com" "https://s3-outposts.eu-south-1.amazonaws.com" "https://s3-outposts.af-south-1.amazonaws.com" "https://s3-outposts.ap-northeast-1.amazonaws.com" "https://s3-outposts.ap-northeast-2.amazonaws.com" "https://s3-outposts.ap-northeast-3.amazonaws.com" "https://s3-outposts.ap-southeast-1.amazonaws.com" "https://s3-outposts.ap-southeast-2.amazonaws.com" "https://s3-outposts.ap-east-1.amazonaws.com" "https://s3-outposts.ap-south-1.amazonaws.com" "https://s3-outposts.sa-east-1.amazonaws.com" "https://s3-outposts.me-south-1.amazonaws.com" "http://s3-outposts.cn-north-1.amazonaws.com.cn" "http://s3-outposts.cn-northwest-1.amazonaws.com.cn" "https://s3-outposts.cn-north-1.amazonaws.com.cn" "https://s3-outposts.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def access-type-completer [] { ["CustomerOwnedIp" "Private"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "s3-outposts-create-endpoint create" } } | get name | first)
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

# Creates an endpoint and associates it with the specified Outpost. It can take up to 5 minutes for this action to finish. Related actions include: DeleteEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_DeleteEndpoint.html) ListEndpoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_ListEndpoints.html)
#
# POST /S3Outposts/CreateEndpoint
# operationId: CreateEndpoint
export def "s3-outposts-create-endpoint create" [
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
  outpost_id: string # The ID of the Outposts.
  subnet_id: string # The ID of the subnet in the selected VPC. The endpoint subnet must belong to the Outpost that has Amazon S3 on Outposts provisioned.
  security_group_id: string # The ID of the security group to use with the endpoint.
  --access-type: string@access-type-completer # The type of access for the network connectivity for the Amazon S3 on Outposts endpoint. To use the Amazon Web Services VPC, choose Private. To use the endpoint with an on-premises network, choose CustomerOwnedIp. If you choose CustomerOwnedIp, you must also provide the customer-owned IP address pool (CoIP pool). Private is the default access type value.
  --customer-owned-ipv4-pool: string # The ID of the customer-owned IPv4 address pool (CoIP pool) for the endpoint. IP addresses are allocated from this pool for the endpoint.
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/S3Outposts/CreateEndpoint")
  let req_body = {"OutpostId": $outpost_id, "SubnetId": $subnet_id, "SecurityGroupId": $security_group_id, "AccessType": $access_type, "CustomerOwnedIpv4Pool": $customer_owned_ipv4_pool} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an endpoint. It can take up to 5 minutes for this action to finish. Related actions include: CreateEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_CreateEndpoint.html) ListEndpoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_ListEndpoints.html)
#
# DELETE /S3Outposts/DeleteEndpoint#endpointId&outpostId
# operationId: DeleteEndpoint
export def "s3-outposts-delete-endpointendpoint-idoutpost-id delete-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-id: string # The ID of the endpoint.
  --outpost-id: string # The ID of the Outposts.
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
  let qp = [(serialize-qp "endpointId" $endpoint_id "scalar") (serialize-qp "outpostId" $outpost_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/S3Outposts/DeleteEndpoint#endpointId&outpostId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists endpoints associated with the specified Outpost. Related actions include: CreateEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_CreateEndpoint.html) DeleteEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_DeleteEndpoint.html)
#
# GET /S3Outposts/ListEndpoints
# operationId: ListEndpoints
export def "s3-outposts-list-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If a previous response from this operation included a NextToken value, provide that value here to retrieve the next page of results.
  --max-results: int # The maximum number of endpoints that will be returned in the response.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Endpoints: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/S3Outposts/ListEndpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the Outposts with S3 on Outposts capacity for your Amazon Web Services account. Includes S3 on Outposts that you have access to as the Outposts owner, or as a shared user from Resource Access Manager (RAM).
#
# GET /S3Outposts/ListOutpostsWithS3
# operationId: ListOutpostsWithS3
export def "s3-outposts-list-outposts-with-s3 list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # When you can get additional results from the ListOutpostsWithS3 call, a NextToken parameter is returned in the output. You can then pass in a subsequent command to the NextToken parameter to continue listing additional Outposts.
  --max-results: int # The maximum number of Outposts to return. The limit is 100.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Outposts: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/S3Outposts/ListOutpostsWithS3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all endpoints associated with an Outpost that has been shared by Amazon Web Services Resource Access Manager (RAM). Related actions include: CreateEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_CreateEndpoint.html) DeleteEndpoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_s3outposts_DeleteEndpoint.html)
#
# GET /S3Outposts/ListSharedEndpoints#outpostId
# operationId: ListSharedEndpoints
export def "s3-outposts-list-shared-endpointsoutpost-id list-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If a previous response from this operation included a NextToken value, you can provide that value here to retrieve the next page of results.
  --max-results: int # The maximum number of endpoints that will be returned in the response.
  --outpost-id: string # The ID of the Amazon Web Services Outpost.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Endpoints: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "outpostId" $outpost_id "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/S3Outposts/ListSharedEndpoints#outpostId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
