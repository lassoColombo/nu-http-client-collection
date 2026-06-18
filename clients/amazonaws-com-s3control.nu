# Auto-generated client for AWS S3 Control v2018-08-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/s3control/2018-08-20/openapi.json
# Auth: --token flag or $env.AWS_S3_CONTROL_TOKEN

const BASE_URL = "http://s3-control.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_S3_CONTROL_TOKEN | default "" }
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

def base-url-completer [] { ["http://s3-control.us-east-1.amazonaws.com" "http://s3-control.us-east-2.amazonaws.com" "http://s3-control.us-west-1.amazonaws.com" "http://s3-control.us-west-2.amazonaws.com" "http://s3-control.us-gov-west-1.amazonaws.com" "http://s3-control.us-gov-east-1.amazonaws.com" "http://s3-control.ca-central-1.amazonaws.com" "http://s3-control.eu-north-1.amazonaws.com" "http://s3-control.eu-west-1.amazonaws.com" "http://s3-control.eu-west-2.amazonaws.com" "http://s3-control.eu-west-3.amazonaws.com" "http://s3-control.eu-central-1.amazonaws.com" "http://s3-control.eu-south-1.amazonaws.com" "http://s3-control.af-south-1.amazonaws.com" "http://s3-control.ap-northeast-1.amazonaws.com" "http://s3-control.ap-northeast-2.amazonaws.com" "http://s3-control.ap-northeast-3.amazonaws.com" "http://s3-control.ap-southeast-1.amazonaws.com" "http://s3-control.ap-southeast-2.amazonaws.com" "http://s3-control.ap-east-1.amazonaws.com" "http://s3-control.ap-south-1.amazonaws.com" "http://s3-control.sa-east-1.amazonaws.com" "http://s3-control.me-south-1.amazonaws.com" "https://s3-control.us-east-1.amazonaws.com" "https://s3-control.us-east-2.amazonaws.com" "https://s3-control.us-west-1.amazonaws.com" "https://s3-control.us-west-2.amazonaws.com" "https://s3-control.us-gov-west-1.amazonaws.com" "https://s3-control.us-gov-east-1.amazonaws.com" "https://s3-control.ca-central-1.amazonaws.com" "https://s3-control.eu-north-1.amazonaws.com" "https://s3-control.eu-west-1.amazonaws.com" "https://s3-control.eu-west-2.amazonaws.com" "https://s3-control.eu-west-3.amazonaws.com" "https://s3-control.eu-central-1.amazonaws.com" "https://s3-control.eu-south-1.amazonaws.com" "https://s3-control.af-south-1.amazonaws.com" "https://s3-control.ap-northeast-1.amazonaws.com" "https://s3-control.ap-northeast-2.amazonaws.com" "https://s3-control.ap-northeast-3.amazonaws.com" "https://s3-control.ap-southeast-1.amazonaws.com" "https://s3-control.ap-southeast-2.amazonaws.com" "https://s3-control.ap-east-1.amazonaws.com" "https://s3-control.ap-south-1.amazonaws.com" "https://s3-control.sa-east-1.amazonaws.com" "https://s3-control.me-south-1.amazonaws.com" "http://s3-control.cn-north-1.amazonaws.com.cn" "http://s3-control.cn-northwest-1.amazonaws.com.cn" "https://s3-control.cn-north-1.amazonaws.com.cn" "https://s3-control.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-acl-completer [] { ["authenticated-read" "private" "public-read" "public-read-write"] }
def requested-job-status-completer [] { ["Cancelled" "Ready"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accesspoint create-access-point" } } | get name | first)
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

# Creates an access point and associates it with the specified bucket. For more information, see Managing Data Access with Amazon S3 Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html) in the Amazon S3 User Guide. S3 on Outposts only supports VPC-style access points. For more information, see Accessing Amazon S3 on Outposts using virtual private cloud (VPC) only access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html#API_control_CreateAccessPoint_Examples) section. The following actions are related to CreateAccessPoint: GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# PUT /v20180820/accesspoint/{name}#x-amz-account-id
# operationId: CreateAccessPoint
export def "accesspoint create-access-point" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html#API_control_DeleteAccessPoint_Examples) section. The following actions are related to DeleteAccessPoint: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# DELETE /v20180820/accesspoint/{name}#x-amz-account-id
# operationId: DeleteAccessPoint
export def "accesspoint delete-access-point" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns configuration information about the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html#API_control_GetAccessPoint_Examples) section. The following actions are related to GetAccessPoint: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# GET /v20180820/accesspoint/{name}#x-amz-account-id
# operationId: GetAccessPoint
export def "accesspoint get-access-point" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an Object Lambda Access Point. For more information, see Transforming objects with Object Lambda Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html) in the Amazon S3 User Guide. The following actions are related to CreateAccessPointForObjectLambda: DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}#x-amz-account-id
# operationId: CreateAccessPointForObjectLambda
export def "accesspointforobjectlambda create-access-point-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for owner of the specified Object Lambda Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes the specified Object Lambda Access Point. The following actions are related to DeleteAccessPointForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# DELETE /v20180820/accesspointforobjectlambda/{name}#x-amz-account-id
# operationId: DeleteAccessPointForObjectLambda
export def "accesspointforobjectlambda delete-access-point-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns configuration information about the specified Object Lambda Access Point The following actions are related to GetAccessPointForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}#x-amz-account-id
# operationId: GetAccessPointForObjectLambda
export def "accesspointforobjectlambda get-access-point-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action creates an Amazon S3 on Outposts bucket. To create an S3 bucket, see Create Bucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html) in the Amazon S3 API Reference. Creates a new Outposts bucket. By creating the bucket, you become the bucket owner. To create an Outposts bucket, you must have S3 on Outposts. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. Not every string is an acceptable bucket name. For information on bucket naming restrictions, see Working with Amazon S3 Buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html#bucketnamingrules). S3 on Outposts buckets support: Tags LifecycleConfigurations for deleting expired objects For a complete list of restrictions and Amazon S3 feature limitations on S3 on Outposts, see Amazon S3 on Outposts Restrictions and Limitations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OnOutpostsRestrictionsLimitations.html). For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and x-amz-outpost-id in your API request, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html#API_control_CreateBucket_Examples) section. The following actions are related to CreateBucket for Amazon S3 on Outposts: PutObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html) GetBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html) DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html) CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html)
#
# PUT /v20180820/bucket/{name}
# operationId: CreateBucket
export def "bucket create" [
  name: string
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
  --x-amz-acl: string@x-amz-acl-completer # The canned ACL to apply to the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-full-control: string # Allows grantee the read, write, read ACP, and write ACP permissions on the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-read: string # Allows grantee to list the objects in the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-read-acp: string # Allows grantee to read the bucket ACL. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-write: string # Allows grantee to create, overwrite, and delete any object in the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-write-acp: string # Allows grantee to write the ACL for the applicable bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-bucket-object-lock-enabled: oneof<nothing, bool> # Specifies whether you want S3 Object Lock to be enabled for the new bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-outpost-id: string # The ID of the Outposts where the bucket is being created. This ID is required by Amazon S3 on Outposts buckets.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-acl": $x_amz_acl, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write": $x_amz_grant_write, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-bucket-object-lock-enabled": $x_amz_bucket_object_lock_enabled, "x-amz-outpost-id": $x_amz_outpost_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# You can use S3 Batch Operations to perform large-scale batch actions on Amazon S3 objects. Batch Operations can run a single action on lists of Amazon S3 objects that you specify. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. This action creates a S3 Batch Operations job. Related actions include: DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html) JobOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_JobOperation.html)
#
# POST /v20180820/jobs#x-amz-account-id
# operationId: CreateJob
export def "jobsx-amz-account-id create-job" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID that creates the job.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/jobs#x-amz-account-id")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Lists current S3 Batch Operations jobs and jobs that have ended within the last 30 days for the Amazon Web Services account making the request. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# GET /v20180820/jobs#x-amz-account-id
# operationId: ListJobs
export def "jobsx-amz-account-id list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-statuses: list # The List Jobs request returns jobs that match the statuses listed in this element.
  --next-token: string # A pagination token to request the next page of results. Use the token that Amazon S3 returned in the NextToken element of the ListJobsResult from the previous List Jobs request.
  --max-results: int # The maximum number of jobs that Amazon S3 will include in the List Jobs response. If there are more jobs than this number, the response will include a pagination token in the NextToken field to enable you to retrieve the next page of results.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jobStatuses" $job_statuses "multi") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/jobs#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a Multi-Region Access Point and associates it with the specified buckets. For more information about creating Multi-Region Access Points, see Creating Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/CreatingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This request is asynchronous, meaning that you might receive a response before the command has completed. When this request provides a response, it provides a token that you can use to monitor the status of the request with DescribeMultiRegionAccessPointOperation. The following actions are related to CreateMultiRegionAccessPoint: DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# POST /v20180820/async-requests/mrap/create#x-amz-account-id
# operationId: CreateMultiRegionAccessPoint
export def "async-requests-mrap-createx-amz-account-id create-multi-region-access-point" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. The owner of the Multi-Region Access Point also must own the underlying buckets.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/async-requests/mrap/create#x-amz-account-id")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes the access point policy for the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html#API_control_DeleteAccessPointPolicy_Examples) section. The following actions are related to DeleteAccessPointPolicy: PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html) GetAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicy.html)
#
# DELETE /v20180820/accesspoint/{name}/policy#x-amz-account-id
# operationId: DeleteAccessPointPolicy
export def "accesspoint-policyx-amz-account-id delete-access-point-policy" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified access point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}/policy#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the access point policy associated with the specified access point. The following actions are related to GetAccessPointPolicy: PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html) DeleteAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html)
#
# GET /v20180820/accesspoint/{name}/policy#x-amz-account-id
# operationId: GetAccessPointPolicy
export def "accesspoint-policyx-amz-account-id get-access-point-policy" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified access point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}/policy#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html#API_control_PutAccessPointPolicy_Examples) section. The following actions are related to PutAccessPointPolicy: GetAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicy.html) DeleteAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html)
#
# PUT /v20180820/accesspoint/{name}/policy#x-amz-account-id
# operationId: PutAccessPointPolicy
export def "accesspoint-policyx-amz-account-id update-access-point-policy" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for owner of the bucket associated with the specified access point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}/policy#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Removes the resource policy for an Object Lambda Access Point. The following actions are related to DeleteAccessPointPolicyForObjectLambda: GetAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicyForObjectLambda.html) PutAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicyForObjectLambda.html)
#
# DELETE /v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id
# operationId: DeleteAccessPointPolicyForObjectLambda
export def "accesspointforobjectlambda-policyx-amz-account-id delete-access-point-policy-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the resource policy for an Object Lambda Access Point. The following actions are related to GetAccessPointPolicyForObjectLambda: DeleteAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicyForObjectLambda.html) PutAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicyForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id
# operationId: GetAccessPointPolicyForObjectLambda
export def "accesspointforobjectlambda-policyx-amz-account-id get-access-point-policy-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or replaces resource policy for an Object Lambda Access Point. For an example policy, see Creating Object Lambda Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/olap-create.html#olap-create-cli) in the Amazon S3 User Guide. The following actions are related to PutAccessPointPolicyForObjectLambda: DeleteAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicyForObjectLambda.html) GetAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicyForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id
# operationId: PutAccessPointPolicyForObjectLambda
export def "accesspointforobjectlambda-policyx-amz-account-id update-access-point-policy-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/policy#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# This action deletes an Amazon S3 on Outposts bucket. To delete an S3 bucket, see DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html) in the Amazon S3 API Reference. Deletes the Amazon S3 on Outposts bucket. All objects (including all object versions and delete markers) in the bucket must be deleted before the bucket itself can be deleted. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html#API_control_DeleteBucket_Examples) section. Related Resources CreateBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html) GetBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html) DeleteObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html)
#
# DELETE /v20180820/bucket/{name}#x-amz-account-id
# operationId: DeleteBucket
export def "bucket delete" [
  name: string
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
  --x-amz-account-id: string # The account ID that owns the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets an Amazon S3 on Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the Outposts bucket, the calling identity must have the s3-outposts:GetBucket permissions on the specified Outposts bucket and belong to the Outposts bucket owner's account in order to use this action. Only users from Outposts bucket owner account with the right permissions can perform actions on an Outposts bucket. If you don't have s3-outposts:GetBucket permissions or you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 403 Access Denied error. The following actions are related to GetBucket for Amazon S3 on Outposts: All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html#API_control_GetBucket_Examples) section. PutObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html) CreateBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html) DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html)
#
# GET /v20180820/bucket/{name}#x-amz-account-id
# operationId: GetBucket
export def "bucket get" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action deletes an Amazon S3 on Outposts bucket's lifecycle configuration. To delete an S3 bucket's lifecycle configuration, see DeleteBucketLifecycle (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html) in the Amazon S3 API Reference. Deletes the lifecycle configuration from the specified Outposts bucket. Amazon S3 on Outposts removes all the lifecycle configuration rules in the lifecycle subresource associated with the bucket. Your objects never expire, and Amazon S3 on Outposts no longer automatically deletes any objects on the basis of rules contained in the deleted lifecycle configuration. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the s3-outposts:DeleteLifecycleConfiguration action. By default, the bucket owner has this permission and the Outposts bucket owner can grant this permission to others. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html#API_control_DeleteBucketLifecycleConfiguration_Examples) section. For more information about object expiration, see Elements to Describe Lifecycle Actions (https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions). Related actions include: PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# DELETE /v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id
# operationId: DeleteBucketLifecycleConfiguration
export def "bucket-lifecycleconfigurationx-amz-account-id delete-lifecycle-configuration" [
  name: string
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
  --x-amz-account-id: string # The account ID of the lifecycle configuration to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action gets an Amazon S3 on Outposts bucket's lifecycle configuration. To get an S3 bucket's lifecycle configuration, see GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html) in the Amazon S3 API Reference. Returns the lifecycle configuration information set on the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) and for information about lifecycle configuration, see Object Lifecycle Management (https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the s3-outposts:GetLifecycleConfiguration action. The Outposts bucket owner has this permission, by default. The bucket owner can grant this permission to others. For more information about permissions, see Permissions Related to Bucket Subresource Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources) and Managing Access Permissions to Your Amazon S3 Resources (https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html#API_control_GetBucketLifecycleConfiguration_Examples) section. GetBucketLifecycleConfiguration has the following special error: Error code: NoSuchLifecycleConfiguration Description: The lifecycle configuration does not exist. HTTP Status Code: 404 Not Found SOAP Fault Code Prefix: Client The following actions are related to GetBucketLifecycleConfiguration: PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) DeleteBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html)
#
# GET /v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id
# operationId: GetBucketLifecycleConfiguration
export def "bucket-lifecycleconfigurationx-amz-account-id get-lifecycle-configuration" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action puts a lifecycle configuration to an Amazon S3 on Outposts bucket. To put a lifecycle configuration to an S3 bucket, see PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html) in the Amazon S3 API Reference. Creates a new lifecycle configuration for the S3 on Outposts bucket or replaces an existing lifecycle configuration. Outposts buckets only support lifecycle configurations that delete/expire objects after a certain period of time and abort incomplete multipart uploads. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html#API_control_PutBucketLifecycleConfiguration_Examples) section. The following actions are related to PutBucketLifecycleConfiguration: GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html) DeleteBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html)
#
# PUT /v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id
# operationId: PutBucketLifecycleConfiguration
export def "bucket-lifecycleconfigurationx-amz-account-id update-lifecycle-configuration" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/lifecycleconfiguration#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# This action deletes an Amazon S3 on Outposts bucket policy. To delete an S3 bucket policy, see DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketPolicy.html) in the Amazon S3 API Reference. This implementation of the DELETE action uses the policy subresource to delete the policy of a specified Amazon S3 on Outposts bucket. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the s3-outposts:DeleteBucketPolicy permissions on the specified Outposts bucket and belong to the bucket owner's account to use this action. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. If you don't have DeleteBucketPolicy permissions, Amazon S3 returns a 403 Access Denied error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 405 Method Not Allowed error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html#API_control_DeleteBucketPolicy_Examples) section. The following actions are related to DeleteBucketPolicy: GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html) PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html)
#
# DELETE /v20180820/bucket/{name}/policy#x-amz-account-id
# operationId: DeleteBucketPolicy
export def "bucket-policyx-amz-account-id delete-policy" [
  name: string
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
  --x-amz-account-id: string # The account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/policy#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action gets a bucket policy for an Amazon S3 on Outposts bucket. To get a policy for an S3 bucket, see GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicy.html) in the Amazon S3 API Reference. Returns the policy of a specified Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the GetBucketPolicy permissions on the specified bucket and belong to the bucket owner's account in order to use this action. Only users from Outposts bucket owner account with the right permissions can perform actions on an Outposts bucket. If you don't have s3-outposts:GetBucketPolicy permissions or you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 403 Access Denied error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html#API_control_GetBucketPolicy_Examples) section. The following actions are related to GetBucketPolicy: GetObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html) PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html) DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html)
#
# GET /v20180820/bucket/{name}/policy#x-amz-account-id
# operationId: GetBucketPolicy
export def "bucket-policyx-amz-account-id get-policy" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/policy#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action puts a bucket policy to an Amazon S3 on Outposts bucket. To put a policy on an S3 bucket, see PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketPolicy.html) in the Amazon S3 API Reference. Applies an Amazon S3 bucket policy to an Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the Outposts bucket, the calling identity must have the PutBucketPolicy permissions on the specified Outposts bucket and belong to the bucket owner's account in order to use this action. If you don't have PutBucketPolicy permissions, Amazon S3 returns a 403 Access Denied error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 405 Method Not Allowed error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html#API_control_PutBucketPolicy_Examples) section. The following actions are related to PutBucketPolicy: GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html) DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html)
#
# PUT /v20180820/bucket/{name}/policy#x-amz-account-id
# operationId: PutBucketPolicy
export def "bucket-policyx-amz-account-id update-policy" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
  --x-amz-confirm-remove-self-bucket-access: oneof<nothing, bool> # Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future. This is not supported by Amazon S3 on Outposts buckets.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/policy#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id, "x-amz-confirm-remove-self-bucket-access": $x_amz_confirm_remove_self_bucket_access} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# This operation deletes an Amazon S3 on Outposts bucket's replication configuration. To delete an S3 bucket's replication configuration, see DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html) in the Amazon S3 API Reference. Deletes the replication configuration from the specified S3 on Outposts bucket. To use this operation, you must have permissions to perform the s3-outposts:PutReplicationConfiguration action. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html#API_control_DeleteBucketReplication_Examples) section. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. The following operations are related to DeleteBucketReplication: PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html) GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html)
#
# DELETE /v20180820/bucket/{name}/replication#x-amz-account-id
# operationId: DeleteBucketReplication
export def "bucket-replicationx-amz-account-id delete-replication" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket to delete the replication configuration for.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/replication#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This operation gets an Amazon S3 on Outposts bucket's replication configuration. To get an S3 bucket's replication configuration, see GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html) in the Amazon S3 API Reference. Returns the replication configuration of an S3 on Outposts bucket. For more information about S3 on Outposts, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. This action requires permissions for the s3-outposts:GetReplicationConfiguration action. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html#API_control_GetBucketReplication_Examples) section. If you include the Filter element in a replication configuration, you must also include the DeleteMarkerReplication, Status, and Priority elements. The response also returns those elements. For information about S3 on Outposts replication failure reasons, see Replication failure reasons (https://docs.aws.amazon.com/AmazonS3/latest/userguide/outposts-replication-eventbridge.html#outposts-replication-failure-codes) in the Amazon S3 User Guide. The following operations are related to GetBucketReplication: PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html) DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html)
#
# GET /v20180820/bucket/{name}/replication#x-amz-account-id
# operationId: GetBucketReplication
export def "bucket-replicationx-amz-account-id get-replication" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/replication#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action creates an Amazon S3 on Outposts bucket's replication configuration. To create an S3 bucket's replication configuration, see PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html) in the Amazon S3 API Reference. Creates a replication configuration or replaces an existing one. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. Specify the replication configuration in the request body. In the replication configuration, you provide the following information: The name of the destination bucket or buckets where you want S3 on Outposts to replicate objects The Identity and Access Management (IAM) role that S3 on Outposts can assume to replicate objects on your behalf Other relevant information, such as replication rules A replication configuration must include at least one rule and can contain a maximum of 100. Each rule identifies a subset of objects to replicate by filtering the objects in the source Outposts bucket. To choose additional subsets of objects to replicate, add a rule for each subset. To specify a subset of the objects in the source Outposts bucket to apply a replication rule to, add the Filter element as a child of the Rule element. You can filter objects based on an object key prefix, one or more object tags, or both. When you add the Filter element in the configuration, you must also add the following elements: DeleteMarkerReplication, Status, and Priority. Using PutBucketReplication on Outposts requires that both the source and destination buckets must have versioning enabled. For information about enabling versioning on a bucket, see Managing S3 Versioning for your S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsManagingVersioning.html). For information about S3 on Outposts replication failure reasons, see Replication failure reasons (https://docs.aws.amazon.com/AmazonS3/latest/userguide/outposts-replication-eventbridge.html#outposts-replication-failure-codes) in the Amazon S3 User Guide. Handling Replication of Encrypted Objects Outposts buckets are encrypted at all times. All the objects in the source Outposts bucket are encrypted and can be replicated. Also, all the replicas in the destination Outposts bucket are encrypted with the same encryption key as the objects in the source Outposts bucket. Permissions To create a PutBucketReplication request, you must have s3-outposts:PutReplicationConfiguration permissions for the bucket. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html). To perform this operation, the user or role must also have the iam:CreateRole and iam:PassRole permissions. For more information, see Granting a user permissions to pass a role to an Amazon Web Services service (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html#API_control_PutBucketReplication_Examples) section. The following operations are related to PutBucketReplication: GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html) DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html)
#
# PUT /v20180820/bucket/{name}/replication#x-amz-account-id
# operationId: PutBucketReplication
export def "bucket-replicationx-amz-account-id update-replication" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/replication#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# This action deletes an Amazon S3 on Outposts bucket's tags. To delete an S3 bucket tags, see DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html) in the Amazon S3 API Reference. Deletes the tags from the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the PutBucketTagging action. By default, the bucket owner has this permission and can grant this permission to others. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html#API_control_DeleteBucketTagging_Examples) section. The following actions are related to DeleteBucketTagging: GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html) PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html)
#
# DELETE /v20180820/bucket/{name}/tagging#x-amz-account-id
# operationId: DeleteBucketTagging
export def "bucket-taggingx-amz-account-id delete-tagging" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket tag set to be removed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/tagging#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action gets an Amazon S3 on Outposts bucket's tags. To get an S3 bucket tags, see GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html) in the Amazon S3 API Reference. Returns the tag set associated with the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the GetBucketTagging action. By default, the bucket owner has this permission and can grant this permission to others. GetBucketTagging has the following special error: Error code: NoSuchTagSetError Description: There is no tag set associated with the bucket. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html#API_control_GetBucketTagging_Examples) section. The following actions are related to GetBucketTagging: PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html) DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html)
#
# GET /v20180820/bucket/{name}/tagging#x-amz-account-id
# operationId: GetBucketTagging
export def "bucket-taggingx-amz-account-id get-tagging" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/tagging#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This action puts tags on an Amazon S3 on Outposts bucket. To put tags on an S3 bucket, see PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html) in the Amazon S3 API Reference. Sets the tags for an S3 on Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. Use tags to organize your Amazon Web Services bill to reflect your own cost structure. To do this, sign up to get your Amazon Web Services account bill with tag key values included. Then, to see the cost of combined resources, organize your billing information according to resources with the same tag key values. For example, you can tag several resources with a specific application name, and then organize your billing information to see the total cost of that application across several services. For more information, see Cost allocation and tagging (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html). Within a bucket, if you add a tag that has the same key as an existing tag, the new value overwrites the old value. For more information, see Using cost allocation in Amazon S3 bucket tags (https://docs.aws.amazon.com/AmazonS3/latest/userguide/CostAllocTagging.html). To use this action, you must have permissions to perform the s3-outposts:PutBucketTagging action. The Outposts bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see Permissions Related to Bucket Subresource Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources) and Managing access permissions to your Amazon S3 resources (https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html). PutBucketTagging has the following special errors: Error code: InvalidTagError Description: The tag provided was not a valid tag. This error can occur if the tag did not pass input validation. For information about tag restrictions, see User-Defined Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html) and Amazon Web Services-Generated Cost Allocation Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/aws-tag-restrictions.html). Error code: MalformedXMLError Description: The XML provided does not match the schema. Error code: OperationAbortedError Description: A conflicting conditional action is currently in progress against this resource. Try again. Error code: InternalError Description: The service was unable to apply the provided tag to the bucket. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html#API_control_PutBucketTagging_Examples) section. The following actions are related to PutBucketTagging: GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html) DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html)
#
# PUT /v20180820/bucket/{name}/tagging#x-amz-account-id
# operationId: PutBucketTagging
export def "bucket-taggingx-amz-account-id update-tagging" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/tagging#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Removes the entire tag set from the specified S3 Batch Operations job. To use the DeleteJobTagging operation, you must have permission to perform the s3:DeleteJobTagging action. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html) PutJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutJobTagging.html)
#
# DELETE /v20180820/jobs/{id}/tagging#x-amz-account-id
# operationId: DeleteJobTagging
export def "jobs-taggingx-amz-account-id delete-tagging" [
  id: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}/tagging#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the tags on an S3 Batch Operations job. To use the GetJobTagging operation, you must have permission to perform the s3:GetJobTagging action. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) PutJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutJobTagging.html) DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html)
#
# GET /v20180820/jobs/{id}/tagging#x-amz-account-id
# operationId: GetJobTagging
export def "jobs-taggingx-amz-account-id get-tagging" [
  id: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}/tagging#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sets the supplied tag-set on an S3 Batch Operations job. A tag is a key-value pair. You can associate S3 Batch Operations tags with any job by sending a PUT request against the tagging subresource that is associated with the job. To modify the existing tag set, you can either replace the existing tag set entirely, or make changes within the existing tag set by retrieving the existing tag set using GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html), modify that tag set, and use this action to replace the tag set with the one you modified. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. If you send this request with an empty tag set, Amazon S3 deletes the existing tag set on the Batch Operations job. If you use this method, you are charged for a Tier 1 Request (PUT). For more information, see Amazon S3 pricing (http://aws.amazon.com/s3/pricing/). For deleting existing tags for your Batch Operations job, a DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html) request is preferred because it achieves the same result without incurring charges. A few things to consider about using tags: Amazon S3 limits the maximum number of tags to 50 tags per job. You can associate up to 50 tags with a job as long as they have unique tag keys. A tag key can be up to 128 Unicode characters in length, and tag values can be up to 256 Unicode characters in length. The key and values are case sensitive. For tagging-related restrictions related to characters and encodings, see User-Defined Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html) in the Billing and Cost Management User Guide. To use the PutJobTagging operation, you must have permission to perform the s3:PutJobTagging action. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html) DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html)
#
# PUT /v20180820/jobs/{id}/tagging#x-amz-account-id
# operationId: PutJobTagging
export def "jobs-taggingx-amz-account-id update-tagging" [
  id: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}/tagging#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes a Multi-Region Access Point. This action does not delete the buckets associated with the Multi-Region Access Point, only the Multi-Region Access Point itself. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This request is asynchronous, meaning that you might receive a response before the command has completed. When this request provides a response, it provides a token that you can use to monitor the status of the request with DescribeMultiRegionAccessPointOperation. The following actions are related to DeleteMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# POST /v20180820/async-requests/mrap/delete#x-amz-account-id
# operationId: DeleteMultiRegionAccessPoint
export def "async-requests-mrap-deletex-amz-account-id delete-multi-region-access-point" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/async-requests/mrap/delete#x-amz-account-id")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Removes the PublicAccessBlock configuration for an Amazon Web Services account. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: GetPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html) PutPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutPublicAccessBlock.html)
#
# DELETE /v20180820/configuration/publicAccessBlock#x-amz-account-id
# operationId: DeletePublicAccessBlock
export def "configuration-public-access-blockx-amz-account-id delete-block" [
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
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to remove.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/configuration/publicAccessBlock#x-amz-account-id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the PublicAccessBlock configuration for an Amazon Web Services account. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: DeletePublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeletePublicAccessBlock.html) PutPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutPublicAccessBlock.html)
#
# GET /v20180820/configuration/publicAccessBlock#x-amz-account-id
# operationId: GetPublicAccessBlock
export def "configuration-public-access-blockx-amz-account-id get-block" [
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
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to retrieve.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/configuration/publicAccessBlock#x-amz-account-id")
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or modifies the PublicAccessBlock configuration for an Amazon Web Services account. For this operation, users must have the s3:PutAccountPublicAccessBlock permission. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: GetPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html) DeletePublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeletePublicAccessBlock.html)
#
# PUT /v20180820/configuration/publicAccessBlock#x-amz-account-id
# operationId: PutPublicAccessBlock
export def "configuration-public-access-blockx-amz-account-id update-block" [
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
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to set.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/configuration/publicAccessBlock#x-amz-account-id")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes the Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:DeleteStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# DELETE /v20180820/storagelens/{storagelensid}#x-amz-account-id
# operationId: DeleteStorageLensConfiguration
export def "storagelens delete-storage-lens-configuration" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}#x-amz-account-id"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the Amazon S3 Storage Lens configuration. For more information, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. For a complete list of S3 Storage Lens metrics, see S3 Storage Lens metrics glossary (https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_metrics_glossary.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:GetStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens/{storagelensid}#x-amz-account-id
# operationId: GetStorageLensConfiguration
export def "storagelens get-storage-lens-configuration" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Puts an Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Working with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. For a complete list of S3 Storage Lens metrics, see S3 Storage Lens metrics glossary (https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_metrics_glossary.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:PutStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# PUT /v20180820/storagelens/{storagelensid}#x-amz-account-id
# operationId: PutStorageLensConfiguration
export def "storagelens update-storage-lens-configuration" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Deletes the Amazon S3 Storage Lens configuration tags. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:DeleteStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# DELETE /v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id
# operationId: DeleteStorageLensConfigurationTagging
export def "storagelens-taggingx-amz-account-id delete-storage-lens-configuration-tagging" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the tags of Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:GetStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id
# operationId: GetStorageLensConfigurationTagging
export def "storagelens-taggingx-amz-account-id get-storage-lens-configuration-tagging" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Put or replace tags on an existing Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:PutStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# PUT /v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id
# operationId: PutStorageLensConfigurationTagging
export def "storagelens-taggingx-amz-account-id update-storage-lens-configuration-tagging" [
  storagelensid: string
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
  --x-amz-account-id: string # The account ID of the requester.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storagelensid: (encode-path-segment $storagelensid)} | format pattern "/v20180820/storagelens/{storagelensid}/tagging#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Retrieves the configuration parameters and status for a Batch Operations job. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# GET /v20180820/jobs/{id}#x-amz-account-id
# operationId: DescribeJob
export def "jobs get" [
  id: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the status of an asynchronous request to manage a Multi-Region Access Point. For more information about managing Multi-Region Access Points and how asynchronous requests work, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# GET /v20180820/async-requests/mrap/{request_token}#x-amz-account-id
# operationId: DescribeMultiRegionAccessPointOperation
export def "async-requests-mrap get-multi-region-access-point-operation" [
  request_token: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({request_token: (encode-path-segment $request_token)} | format pattern "/v20180820/async-requests/mrap/{request_token}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns configuration for an Object Lambda Access Point. The following actions are related to GetAccessPointConfigurationForObjectLambda: PutAccessPointConfigurationForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointConfigurationForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}/configuration#x-amz-account-id
# operationId: GetAccessPointConfigurationForObjectLambda
export def "accesspointforobjectlambda-configurationx-amz-account-id get-access-point-configuration-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/configuration#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Replaces configuration for an Object Lambda Access Point. The following actions are related to PutAccessPointConfigurationForObjectLambda: GetAccessPointConfigurationForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointConfigurationForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}/configuration#x-amz-account-id
# operationId: PutAccessPointConfigurationForObjectLambda
export def "accesspointforobjectlambda-configurationx-amz-account-id update-access-point-configuration-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/configuration#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see Managing Data Access with Amazon S3 access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html) in the Amazon S3 User Guide.
#
# GET /v20180820/accesspoint/{name}/policyStatus#x-amz-account-id
# operationId: GetAccessPointPolicyStatus
export def "accesspoint-policy-statusx-amz-account-id get-access-point-status" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified access point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspoint/{name}/policyStatus#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the status of the resource policy associated with an Object Lambda Access Point.
#
# GET /v20180820/accesspointforobjectlambda/{name}/policyStatus#x-amz-account-id
# operationId: GetAccessPointPolicyStatusForObjectLambda
export def "accesspointforobjectlambda-policy-statusx-amz-account-id get-access-point-status-for-object-lambda" [
  name: string
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
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/accesspointforobjectlambda/{name}/policyStatus#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This operation returns the versioning state for S3 on Outposts buckets only. To return the versioning state for an S3 bucket, see GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html) in the Amazon S3 API Reference. Returns the versioning state for an S3 on Outposts bucket. With S3 Versioning, you can save multiple distinct copies of your objects and recover from unintended user actions and application failures. If you've never set versioning on your bucket, it has no versioning state. In that case, the GetBucketVersioning request does not return a versioning state value. For more information about versioning, see Versioning (https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html#API_control_GetBucketVersioning_Examples) section. The following operations are related to GetBucketVersioning for S3 on Outposts. PutBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketVersioning.html) PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# GET /v20180820/bucket/{name}/versioning#x-amz-account-id
# operationId: GetBucketVersioning
export def "bucket-versioningx-amz-account-id get-versioning" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the S3 on Outposts bucket.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/versioning#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This operation sets the versioning state for S3 on Outposts buckets only. To set the versioning state for an S3 bucket, see PutBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html) in the Amazon S3 API Reference. Sets the versioning state for an S3 on Outposts bucket. With S3 Versioning, you can save multiple distinct copies of your objects and recover from unintended user actions and application failures. You can set the versioning state to one of the following: Enabled - Enables versioning for the objects in the bucket. All objects added to the bucket receive a unique version ID. Suspended - Suspends versioning for the objects in the bucket. All objects added to the bucket receive the version ID null. If you've never set versioning on your bucket, it has no versioning state. In that case, a GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html) request does not return a versioning state value. When you enable S3 Versioning, for each object in your bucket, you have a current version and zero or more noncurrent versions. You can configure your bucket S3 Lifecycle rules to expire noncurrent versions after a specified time period. For more information, see Creating and managing a lifecycle configuration for your S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsLifecycleManaging.html) in the Amazon S3 User Guide. If you have an object expiration lifecycle configuration in your non-versioned bucket and you want to maintain the same permanent delete behavior when you enable versioning, you must add a noncurrent expiration policy. The noncurrent expiration lifecycle configuration will manage the deletes of the noncurrent object versions in the version-enabled bucket. For more information, see Versioning (https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketVersioning.html#API_control_PutBucketVersioning_Examples) section. The following operations are related to PutBucketVersioning for S3 on Outposts. GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html) PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# PUT /v20180820/bucket/{name}/versioning#x-amz-account-id
# operationId: PutBucketVersioning
export def "bucket-versioningx-amz-account-id update-versioning" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID of the S3 on Outposts bucket.
  --x-amz-mfa: string # The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/bucket/{name}/versioning#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id, "x-amz-mfa": $x_amz_mfa} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Returns configuration information about the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# GET /v20180820/mrap/instances/{name}#x-amz-account-id
# operationId: GetMultiRegionAccessPoint
export def "mrap-instances get-multi-region-access-point" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/mrap/instances/{name}#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the access control policy of the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPointPolicy: GetMultiRegionAccessPointPolicyStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicyStatus.html) PutMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutMultiRegionAccessPointPolicy.html)
#
# GET /v20180820/mrap/instances/{name}/policy#x-amz-account-id
# operationId: GetMultiRegionAccessPointPolicy
export def "mrap-instances-policyx-amz-account-id get-multi-region-access-point-policy" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/mrap/instances/{name}/policy#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Indicates whether the specified Multi-Region Access Point has an access control policy that allows public access. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPointPolicyStatus: GetMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicy.html) PutMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutMultiRegionAccessPointPolicy.html)
#
# GET /v20180820/mrap/instances/{name}/policystatus#x-amz-account-id
# operationId: GetMultiRegionAccessPointPolicyStatus
export def "mrap-instances-policystatusx-amz-account-id get-multi-region-access-point-policy-status" [
  name: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v20180820/mrap/instances/{name}/policystatus#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns the routing configuration for a Multi-Region Access Point, indicating which Regions are active or passive. To obtain routing control changes and failover requests, use the Amazon S3 failover control infrastructure endpoints in these five Amazon Web Services Regions: us-east-1 us-west-2 ap-southeast-2 ap-northeast-1 eu-west-1 Your Amazon S3 bucket does not need to be in these five Regions.
#
# GET /v20180820/mrap/instances/{mrap}/routes#x-amz-account-id
# operationId: GetMultiRegionAccessPointRoutes
export def "mrap-instances-routesx-amz-account-id get-multi-region-access-point-routes" [
  mrap: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({mrap: (encode-path-segment $mrap)} | format pattern "/v20180820/mrap/instances/{mrap}/routes#x-amz-account-id"))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Submits an updated route configuration for a Multi-Region Access Point. This API operation updates the routing status for the specified Regions from active to passive, or from passive to active. A value of 0 indicates a passive status, which means that traffic won't be routed to the specified Region. A value of 100 indicates an active status, which means that traffic will be routed to the specified Region. At least one Region must be active at all times. When the routing configuration is changed, any in-progress operations (uploads, copies, deletes, and so on) to formerly active Regions will continue to run to their final completion state (success or failure). The routing configurations of any Regions that aren’t specified remain unchanged. Updated routing configurations might not be immediately applied. It can take up to 2 minutes for your changes to take effect. To submit routing control changes and failover requests, use the Amazon S3 failover control infrastructure endpoints in these five Amazon Web Services Regions: us-east-1 us-west-2 ap-southeast-2 ap-northeast-1 eu-west-1 Your Amazon S3 bucket does not need to be in these five Regions.
#
# PATCH /v20180820/mrap/instances/{mrap}/routes#x-amz-account-id
# operationId: SubmitMultiRegionAccessPointRoutes
export def "mrap-instances-routesx-amz-account-id submit-multi-region-access-point-routes" [
  mrap: string
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({mrap: (encode-path-segment $mrap)} | format pattern "/v20180820/mrap/instances/{mrap}/routes#x-amz-account-id"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Returns a list of the access points that are owned by the current account that's associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1,000 access points (or the number specified in maxResults, whichever is less), the response will include a continuation token that you can use to list the additional access points. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html#API_control_GetAccessPoint_Examples) section. The following actions are related to ListAccessPoints: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html)
#
# GET /v20180820/accesspoint#x-amz-account-id
# operationId: ListAccessPoints
export def "accesspointx-amz-account-id list-access-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucket: string # The name of the bucket whose associated access points you want to list. For using this parameter with Amazon S3 on Outposts with the REST API, you must specify the name and the x-amz-outpost-id as well. For using this parameter with S3 on Outposts with the Amazon Web Services SDK and CLI, you must specify the ARN of the bucket accessed in the format arn:aws:s3-outposts:<Region>:<account-id>:outpost/<outpost-id>/bucket/<my-bucket-name>. For example, to access the bucket reports through Outpost my-outpost owned by account 123456789012 in Region us-west-2, use the URL encoding of arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/bucket/reports. The value must be URL encoded.
  --next-token: string # A continuation token. If a previous call to ListAccessPoints returned a continuation token in the NextToken field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  --max-results: int # The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the NextToken field that you can use to retrieve the next page of access points.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access points.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/accesspoint#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns some or all (up to 1,000) access points associated with the Object Lambda Access Point per call. If there are more access points than what can be returned in one call, the response will include a continuation token that you can use to list the additional access points. The following actions are related to ListAccessPointsForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda#x-amz-account-id
# operationId: ListAccessPointsForObjectLambda
export def "accesspointforobjectlambdax-amz-account-id list-access-points-for-object-lambda" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the list has more access points than can be returned in one call to this API, this field contains a continuation token that you can provide in subsequent calls to this API to retrieve additional access points.
  --max-results: int # The maximum number of access points that you want to include in the list. The response may contain fewer access points but will never contain more. If there are more than this number of access points, then the response will include a continuation token in the NextToken field that you can use to retrieve the next page of access points.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/accesspointforobjectlambda#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a list of the Multi-Region Access Points currently associated with the specified Amazon Web Services account. Each call can return up to 100 Multi-Region Access Points, the maximum number of Multi-Region Access Points that can be associated with a single account. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to ListMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html)
#
# GET /v20180820/mrap/instances#x-amz-account-id
# operationId: ListMultiRegionAccessPoints
export def "mrap-instancesx-amz-account-id list-multi-region-access-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Not currently used. Do not use this parameter.
  --max-results: int # Not currently used. Do not use this parameter.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/mrap/instances#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a list of all Outposts buckets in an Outpost that are owned by the authenticated sender of the request. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and x-amz-outpost-id in your request, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListRegionalBuckets.html#API_control_ListRegionalBuckets_Examples) section.
#
# GET /v20180820/bucket#x-amz-account-id
# operationId: ListRegionalBuckets
export def "bucketx-amz-account-id list-regional-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket.
  --x-amz-outpost-id: string # The ID of the Outposts resource. This ID is required by Amazon S3 on Outposts buckets.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/bucket#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id, "x-amz-outpost-id": $x_amz_outpost_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of Amazon S3 Storage Lens configurations. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:ListStorageLensConfigurations action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens#x-amz-account-id
# operationId: ListStorageLensConfigurations
export def "storagelensx-amz-account-id list-storage-lens-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token to request the next page of results.
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20180820/storagelens#x-amz-account-id" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates an access control policy with the specified Multi-Region Access Point. Each Multi-Region Access Point can have only one policy, so a request made to this action replaces any existing policy that is associated with the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to PutMultiRegionAccessPointPolicy: GetMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicy.html) GetMultiRegionAccessPointPolicyStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicyStatus.html)
#
# POST /v20180820/async-requests/mrap/put-policy#x-amz-account-id
# operationId: PutMultiRegionAccessPointPolicy
export def "async-requests-mrap-put-policyx-amz-account-id update-multi-region-access-point-policy" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point.
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20180820/async-requests/mrap/put-policy#x-amz-account-id")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body
}

# Updates an existing S3 Batch Operations job's priority. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# POST /v20180820/jobs/{id}/priority#x-amz-account-id&priority
# operationId: UpdateJobPriority
export def "jobs-priorityx-amz-account-idpriority update-priority" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority: int # The priority you want to assign to this job.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}/priority#x-amz-account-id&priority") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the status for the specified job. Use this action to confirm that you want to run a job or to cancel an existing job. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# POST /v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus
# operationId: UpdateJobStatus
export def "jobs-statusx-amz-account-idrequested-job-status update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requested-job-status: string@requested-job-status-completer # The status that you want to move the specified job to.
  --status-update-reason: string # A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestedJobStatus" $requested_job_status "scalar") (serialize-qp "statusUpdateReason" $status_update_reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-account-id": $x_amz_account_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
