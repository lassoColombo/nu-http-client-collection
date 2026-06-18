# Auto-generated client for AWS SSO OIDC v2019-06-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sso-oidc/2019-06-10/openapi.json
# Auth: --token flag or $env.AWS_SSO_OIDC_TOKEN

const BASE_URL = "http://oidc.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_SSO_OIDC_TOKEN | default "" }
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

def base-url-completer [] { ["http://oidc.us-east-1.amazonaws.com" "http://oidc.us-east-2.amazonaws.com" "http://oidc.us-west-1.amazonaws.com" "http://oidc.us-west-2.amazonaws.com" "http://oidc.us-gov-west-1.amazonaws.com" "http://oidc.us-gov-east-1.amazonaws.com" "http://oidc.ca-central-1.amazonaws.com" "http://oidc.eu-north-1.amazonaws.com" "http://oidc.eu-west-1.amazonaws.com" "http://oidc.eu-west-2.amazonaws.com" "http://oidc.eu-west-3.amazonaws.com" "http://oidc.eu-central-1.amazonaws.com" "http://oidc.eu-south-1.amazonaws.com" "http://oidc.af-south-1.amazonaws.com" "http://oidc.ap-northeast-1.amazonaws.com" "http://oidc.ap-northeast-2.amazonaws.com" "http://oidc.ap-northeast-3.amazonaws.com" "http://oidc.ap-southeast-1.amazonaws.com" "http://oidc.ap-southeast-2.amazonaws.com" "http://oidc.ap-east-1.amazonaws.com" "http://oidc.ap-south-1.amazonaws.com" "http://oidc.sa-east-1.amazonaws.com" "http://oidc.me-south-1.amazonaws.com" "https://oidc.us-east-1.amazonaws.com" "https://oidc.us-east-2.amazonaws.com" "https://oidc.us-west-1.amazonaws.com" "https://oidc.us-west-2.amazonaws.com" "https://oidc.us-gov-west-1.amazonaws.com" "https://oidc.us-gov-east-1.amazonaws.com" "https://oidc.ca-central-1.amazonaws.com" "https://oidc.eu-north-1.amazonaws.com" "https://oidc.eu-west-1.amazonaws.com" "https://oidc.eu-west-2.amazonaws.com" "https://oidc.eu-west-3.amazonaws.com" "https://oidc.eu-central-1.amazonaws.com" "https://oidc.eu-south-1.amazonaws.com" "https://oidc.af-south-1.amazonaws.com" "https://oidc.ap-northeast-1.amazonaws.com" "https://oidc.ap-northeast-2.amazonaws.com" "https://oidc.ap-northeast-3.amazonaws.com" "https://oidc.ap-southeast-1.amazonaws.com" "https://oidc.ap-southeast-2.amazonaws.com" "https://oidc.ap-east-1.amazonaws.com" "https://oidc.ap-south-1.amazonaws.com" "https://oidc.sa-east-1.amazonaws.com" "https://oidc.me-south-1.amazonaws.com" "http://oidc.cn-north-1.amazonaws.com.cn" "http://oidc.cn-northwest-1.amazonaws.com.cn" "https://oidc.cn-north-1.amazonaws.com.cn" "https://oidc.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "token create" } } | get name | first)
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

# Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
#
# POST /token
# operationId: CreateToken
export def "token create" [
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
  client_id: string # The unique identifier string for each client. This value should come from the persisted result of the RegisterClient API.
  client_secret: string # A secret string generated for the client. This value should come from the persisted result of the RegisterClient API.
  grant_type: string # Supports grant types for the authorization code, refresh token, and device code request. For device code requests, specify the following value: urn:ietf:params:oauth:grant-type:device_code For information about how to obtain the device code, see the StartDeviceAuthorization topic.
  --device-code: string # Used only when calling this API for the device code grant type. This short-term code is used to identify this authentication attempt. This should come from an in-memory reference to the result of the StartDeviceAuthorization API.
  --code: string # The authorization code received from the authorization service. This parameter is required to perform an authorization grant request to get access to a token.
  --refresh-token: string # Currently, refreshToken is not yet implemented and is not supported. For more information about the features and limitations of the current IAM Identity Center OIDC implementation, see Considerations for Using this Guide in the IAM Identity Center OIDC API Reference (https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html). The token used to obtain an access token in the event that the access token is invalid or expired.
  --scope: list<string> # The list of scopes that is defined by the client. Upon authorization, this list is used to restrict permissions when granting an access token.
  --redirect-uri: string # The location of the application that will receive the authorization code. Users authorize the service to send the request to this location.
]: any -> record<accessToken: record, tokenType: record, expiresIn: record, refreshToken: record, idToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret, "grantType": $grant_type, "deviceCode": $device_code, "code": $code, "refreshToken": $refresh_token, "scope": $scope, "redirectUri": $redirect_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Registers a client with IAM Identity Center. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
#
# POST /client/register
# operationId: RegisterClient
export def "client-register create" [
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
  client_name: string # The friendly name of the client.
  client_type: string # The type of client. The service supports only public as a client type. Anything other than public will be rejected by the service.
  --scopes: list<string> # The list of scopes that are defined by the client. Upon authorization, this list is used to restrict permissions when granting an access token.
]: any -> record<clientId: record, clientSecret: record, clientIdIssuedAt: record, clientSecretExpiresAt: record, authorizationEndpoint: record, tokenEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/register")
  let req_body = {"clientName": $client_name, "clientType": $client_type, "scopes": $scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Initiates device authorization by requesting a pair of verification codes from the authorization service.
#
# POST /device_authorization
# operationId: StartDeviceAuthorization
export def "device-authorization start" [
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
  client_id: string # The unique identifier string for the client that is registered with IAM Identity Center. This value should come from the persisted result of the RegisterClient API operation.
  client_secret: string # A secret string that is generated for the client. This value should come from the persisted result of the RegisterClient API operation.
  start_url: string # The URL for the AWS access portal. For more information, see Using the AWS access portal (https://docs.aws.amazon.com/singlesignon/latest/userguide/using-the-portal.html) in the IAM Identity Center User Guide.
]: any -> record<deviceCode: record, userCode: record, verificationUri: record, verificationUriComplete: record, expiresIn: record, interval: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device_authorization")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret, "startUrl": $start_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
