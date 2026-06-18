# Auto-generated client for Security Token Service API vv1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/sts/v1beta/openapi.json
# Auth: --token flag or $env.SECURITY_TOKEN_SERVICE_API_TOKEN

const BASE_URL = "https://sts.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SECURITY_TOKEN_SERVICE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://sts.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta-token create" } } | get name | first)
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

# Exchanges a credential for a Google OAuth 2.0 access token. The token asserts an external identity within a workload identity pool, or it applies a Credential Access Boundary to a Google access token. When you call this method, do not send the `Authorization` HTTP header in the request. This method does not require the `Authorization` header, and using the header can cause the request to fail.
#
# POST /v1beta/token
# operationId: sts.token
export def "v1beta-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --audience: string # The full resource name of the identity provider. For example, `//iam.googleapis.com/projects//locations/global/workloadIdentityPools//providers/`. Required when exchanging an external credential for a Google access token.
  --grant-type: string # Required. The grant type. Must be `urn:ietf:params:oauth:grant-type:token-exchange`, which indicates a token exchange.
  --options: string # A set of features that Security Token Service supports, in addition to the standard OAuth 2.0 token exchange, formatted as a serialized JSON object of Options. The size of the parameter value must not exceed 4096 characters.
  --requested-token-type: string # Required. The type of security token. Must be `urn:ietf:params:oauth:token-type:access_token`, which indicates an OAuth 2.0 access token.
  --scope: string # The OAuth 2.0 scopes to include on the resulting access token, formatted as a list of space-delimited, case-sensitive strings. Required when exchanging an external credential for a Google access token.
  --subject-token: string # Required. The input token. This token is either an external credential issued by a workload identity pool provider, or a short-lived access token issued by Google. If the token is an OIDC JWT, it must use the JWT format defined in [RFC 7523](https://tools.ietf.org/html/rfc7523), and the `subject_token_type` must be either `urn:ietf:params:oauth:token-type:jwt` or `urn:ietf:params:oauth:token-type:id_token`. The following headers are required: - `kid`: The identifier of the signing key securing the JWT. - `alg`: The cryptographic algorithm securing the JWT. Must be `RS256` or `ES256`. The following payload fields are required. For more information, see [RFC 7523, Section 3](https://tools.ietf.org/html/rfc7523#section-3): - `iss`: The issuer of the token. The issuer must provide a discovery document at the URL `/.well-known/openid-configuration`, where `` is the value of this field. The document must be formatted according to section 4.2 of the [OIDC 1.0 Discovery specification](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse). - `iat`: The issue time, in seconds, since the Unix epoch. Must be in the past. - `exp`: The expiration time, in seconds, since the Unix epoch. Must be less than 48 hours after `iat`. Shorter expiration times are more secure. If possible, we recommend setting an expiration time less than 6 hours. - `sub`: The identity asserted in the JWT. - `aud`: For workload identity pools, this must be a value specified in the allowed audiences for the workload identity pool provider, or one of the audiences allowed by default if no audiences were specified. See https://cloud.google.com/iam/docs/reference/rest/v1/projects.locations.workloadIdentityPools.providers#oidc Example header: ``` { "alg": "RS256", "kid": "us-east-11" } ``` Example payload: ``` { "iss": "https://accounts.google.com", "iat": 1517963104, "exp": 1517966704, "aud": "//iam.googleapis.com/projects/1234567890123/locations/global/workloadIdentityPools/my-pool/providers/my-provider", "sub": "113475438248934895348", "my_claims": { "additional_claim": "value" } } ``` If `subject_token` is for AWS, it must be a serialized `GetCallerIdentity` token. This token contains the same information as a request to the AWS [`GetCallerIdentity()`](https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity) method, as well as the AWS [signature](https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html) for the request information. Use Signature Version 4. Format the request as URL-encoded JSON, and set the `subject_token_type` parameter to `urn:ietf:params:aws:token-type:aws4_request`. The following parameters are required: - `url`: The URL of the AWS STS endpoint for `GetCallerIdentity()`, such as `https://sts.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15`. Regional endpoints are also supported. - `method`: The HTTP request method: `POST`. - `headers`: The HTTP request headers, which must include: - `Authorization`: The request signature. - `x-amz-date`: The time you will send the request, formatted as an [ISO8601 Basic](https://docs.aws.amazon.com/general/latest/gr/sigv4_elements.html#sigv4_elements_date) string. This value is typically set to the current time and is used to help prevent replay attacks. - `host`: The hostname of the `url` field; for example, `sts.amazonaws.com`. - `x-goog-cloud-target-resource`: The full, canonical resource name of the workload identity pool provider, with or without an `https:` prefix. To help ensure data integrity, we recommend including this header in the `SignedHeaders` field of the signed request. For example: //iam.googleapis.com/projects//locations/global/workloadIdentityPools//providers/ https://iam.googleapis.com/projects//locations/global/workloadIdentityPools//providers/ If you are using temporary security credentials provided by AWS, you must also include the header `x-amz-security-token`, with the value set to the session token. The following example shows a `GetCallerIdentity` token: ``` { "headers": [ {"key": "x-amz-date", "value": "20200815T015049Z"}, {"key": "Authorization", "value": "AWS4-HMAC-SHA256+Credential=$credential,+SignedHeaders=host;x-amz-date;x-goog-cloud-target-resource,+Signature=$signature"}, {"key": "x-goog-cloud-target-resource", "value": "//iam.googleapis.com/projects//locations/global/workloadIdentityPools//providers/"}, {"key": "host", "value": "sts.amazonaws.com"} . ], "method": "POST", "url": "https://sts.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15" } ``` You can also use a Google-issued OAuth 2.0 access token with this field to obtain an access token with new security attributes applied, such as a Credential Access Boundary. In this case, set `subject_token_type` to `urn:ietf:params:oauth:token-type:access_token`. If an access token already contains security attributes, you cannot apply additional security attributes.
  --subject-token-type: string # Required. An identifier that indicates the type of the security token in the `subject_token` parameter. Supported values are `urn:ietf:params:oauth:token-type:jwt`, `urn:ietf:params:oauth:token-type:id_token`, `urn:ietf:params:aws:token-type:aws4_request`, and `urn:ietf:params:oauth:token-type:access_token`.
]: any -> record<access_token: string, expires_in: int, issued_token_type: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta/token" $qp)
  let req_body = {"audience": $audience, "grantType": $grant_type, "options": $options, "requestedTokenType": $requested_token_type, "scope": $scope, "subjectToken": $subject_token, "subjectTokenType": $subject_token_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
