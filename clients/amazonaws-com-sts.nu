# Auto-generated client for AWS Security Token Service v2011-06-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sts/2011-06-15/openapi.json
# Auth: --token flag or $env.AWS_SECURITY_TOKEN_SERVICE_TOKEN

const BASE_URL = "https://sts.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_SECURITY_TOKEN_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://sts.amazonaws.com" "http://sts.us-gov-west-1.amazonaws.com" "http://sts.us-gov-east-1.amazonaws.com" "https://sts.us-gov-west-1.amazonaws.com" "https://sts.us-gov-east-1.amazonaws.com" "http://sts.cn-north-1.amazonaws.com.cn" "http://sts.cn-northwest-1.amazonaws.com.cn" "https://sts.cn-north-1.amazonaws.com.cn" "https://sts.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AssumeRole"] }
def version-completer [] { ["2011-06-15"] }
def action-completer-1 [] { ["AssumeRoleWithSAML"] }
def action-completer-2 [] { ["AssumeRoleWithWebIdentity"] }
def action-completer-3 [] { ["DecodeAuthorizationMessage"] }
def action-completer-4 [] { ["GetAccessKeyInfo"] }
def action-completer-5 [] { ["GetCallerIdentity"] }
def action-completer-6 [] { ["GetFederationToken"] }
def action-completer-7 [] { ["GetSessionToken"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-assume-role" } } | get name | first)
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

# Returns a set of temporary security credentials that you can use to access Amazon Web Services resources. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use AssumeRole within your account or for cross-account access. For a comparison of AssumeRole with other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. Permissions The temporary security credentials created by AssumeRole can be used to make API calls to any Amazon Web Services service with the following exception: You cannot call the Amazon Web Services STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. When you create a role, you create two policies: A role trust policy that specifies who can assume the role and a permissions policy that specifies what can be done with the role. You specify the trusted principal who is allowed to assume the role in the role trust policy. To assume a role from a different account, your Amazon Web Services account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call AssumeRole for the ARN of the role in the other account. To allow a user to assume a role in the same account, you can do either of the following: Attach a policy to the user that allows the user to call AssumeRole (as long as the role's trust policy trusts the account). Add the user as a principal directly in the role's trust policy. You can do either because the role’s trust policy acts as an IAM resource-based policy. When a resource-based policy grants access to a principal in the same account, no additional identity-based policy is required. For more information about trust policies and resource-based policies, see IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) in the IAM User Guide. Tags (Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. Using MFA with AssumeRole (Optional) You can include multi-factor authentication (MFA) information when you call AssumeRole. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an Amazon Web Services MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example. "Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}} For more information, see Configuring MFA-Protected API Access (https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html) in the IAM User Guide guide. To use MFA with AssumeRole, you pass values for the SerialNumber and TokenCode parameters. The SerialNumber value identifies the user's hardware or virtual MFA device. The TokenCode is the time-based one-time password (TOTP) that the MFA device produces.
#
# GET /
# operationId: GET_AssumeRole
export def "api get-assume-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-arn: string # The Amazon Resource Name (ARN) of the role to assume.
  --role-session-name: string # An identifier for the assumed role session. Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their CloudTrail logs. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-
  --policy-arns: list # The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role. This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide.
  --policy: string # An IAM policy in JSON format that you want to use as an inline session policy. This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit.
  --duration-seconds: int # The duration, in seconds, of the role session. The value specified can range from 900 seconds (15 minutes) up to the maximum session duration set for the role. The maximum session duration setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting or the administrator setting (whichever is lower), the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. Role chaining limits your Amazon Web Services CLI or Amazon Web Services API role session to a maximum of one hour. When you use the AssumeRole API operation to assume a role, you can specify the duration of your role session with the DurationSeconds parameter. You can specify a parameter value of up to 43200 seconds (12 hours), depending on the maximum session duration setting for your role. However, if you assume a role using role chaining and provide a DurationSeconds parameter value greater than one hour, the operation fails. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. By default, the value is set to 3600 seconds. The DurationSeconds parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a SessionDuration parameter that specifies the maximum length of the console session. For more information, see Creating a URL that Enables Federated Users to Access the Amazon Web Services Management Console (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html) in the IAM User Guide.
  --tags: list # A list of session tags that you want to pass. Each session tag consists of a key name and an associated value. For more information about session tags, see Tagging Amazon Web Services STS Sessions (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. This parameter is optional. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters, and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is already attached to the role. When you do, session tags override a role tag with the same key. Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate Department and department tag keys. Assume that the role has the Department=Marketing tag and you pass the department=engineering session tag. Department and department are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag. Additionally, if you used temporary credentials to perform this operation, the new session inherits any transitive session tags from the calling session. If you pass a session tag with the same key as an inherited tag, the operation fails. To view the inherited tags for a session, see the CloudTrail logs. For more information, see Viewing Session Tags in CloudTrail (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_ctlogs) in the IAM User Guide.
  --transitive-tag-keys: list # A list of keys for session tags that you want to set as transitive. If you set a tag key as transitive, the corresponding key and value passes to subsequent sessions in a role chain. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. This parameter is optional. When you set session tags as transitive, the session policy and session tags packed binary limit is not affected. If you choose not to specify a transitive tag key, then no tags are passed from this session to any subsequent sessions.
  --external-id: string # A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the ExternalId parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see How to Use an External ID When Granting Access to Your Amazon Web Services Resources to a Third Party (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html) in the IAM User Guide. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-
  --serial-number: string # The identification number of the MFA device that is associated with the user who is making the AssumeRole call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as GAHT12345678) or an Amazon Resource Name (ARN) for a virtual device (such as arn:aws:iam::123456789012:mfa/user). The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-
  --token-code: string # The value provided by the MFA device, if the trust policy of the role being assumed requires MFA. (In other words, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the TokenCode value is missing or expired, the AssumeRole call returns an "access denied" error. The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.
  --source-identity: string # The source identity specified by the principal that is calling the AssumeRole operation. You can require users to specify a source identity when they assume a role. You do this by using the sts:SourceIdentity condition key in a role trust policy. You can use source identity information in CloudTrail logs to determine who took actions with a role. You can use the aws:SourceIdentity condition key to further control access to Amazon Web Services resources based on the value of source identity. For more information about using source identity, see Monitor and control actions taken with assumed roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html) in the IAM User Guide. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-. You cannot use a value that begins with the text aws:. This prefix is reserved for Amazon Web Services internal use.
  --action: string@action-completer
  --version: string@version-completer
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
  let qp = [(serialize-qp "RoleArn" $role_arn "scalar") (serialize-qp "RoleSessionName" $role_session_name "scalar") (serialize-qp "PolicyArns" $policy_arns "multi") (serialize-qp "Policy" $policy "scalar") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "TransitiveTagKeys" $transitive_tag_keys "multi") (serialize-qp "ExternalId" $external_id "scalar") (serialize-qp "SerialNumber" $serial_number "scalar") (serialize-qp "TokenCode" $token_code "scalar") (serialize-qp "SourceIdentity" $source_identity "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RoleArn": $role_arn, "RoleSessionName": $role_session_name, "PolicyArns": $policy_arns, "Policy": $policy, "DurationSeconds": $duration_seconds, "Tags": $tags, "TransitiveTagKeys": $transitive_tag_keys, "ExternalId": $external_id, "SerialNumber": $serial_number, "TokenCode": $token_code, "SourceIdentity": $source_identity, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a set of temporary security credentials that you can use to access Amazon Web Services resources. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use AssumeRole within your account or for cross-account access. For a comparison of AssumeRole with other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. Permissions The temporary security credentials created by AssumeRole can be used to make API calls to any Amazon Web Services service with the following exception: You cannot call the Amazon Web Services STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. When you create a role, you create two policies: A role trust policy that specifies who can assume the role and a permissions policy that specifies what can be done with the role. You specify the trusted principal who is allowed to assume the role in the role trust policy. To assume a role from a different account, your Amazon Web Services account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call AssumeRole for the ARN of the role in the other account. To allow a user to assume a role in the same account, you can do either of the following: Attach a policy to the user that allows the user to call AssumeRole (as long as the role's trust policy trusts the account). Add the user as a principal directly in the role's trust policy. You can do either because the role’s trust policy acts as an IAM resource-based policy. When a resource-based policy grants access to a principal in the same account, no additional identity-based policy is required. For more information about trust policies and resource-based policies, see IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) in the IAM User Guide. Tags (Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. Using MFA with AssumeRole (Optional) You can include multi-factor authentication (MFA) information when you call AssumeRole. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an Amazon Web Services MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example. "Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}} For more information, see Configuring MFA-Protected API Access (https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html) in the IAM User Guide guide. To use MFA with AssumeRole, you pass values for the SerialNumber and TokenCode parameters. The SerialNumber value identifies the user's hardware or virtual MFA device. The TokenCode is the time-based one-time password (TOTP) that the MFA device produces.
#
# POST /
# operationId: POST_AssumeRole
export def "api create-assume-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based Amazon Web Services access without user-specific credentials or configuration. For a comparison of AssumeRoleWithSAML with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to Amazon Web Services services. Session Duration By default, the temporary security credentials created by AssumeRoleWithSAML last for one hour. However, you can use the optional DurationSeconds parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's SessionNotOnOrAfter value, whichever is shorter. You can provide a DurationSeconds value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. The maximum session duration limit applies when you use the AssumeRole* API operations or the assume-role* CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) in the IAM User Guide. Role chaining (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-role-chaining) limits your CLI or Amazon Web Services API role session to a maximum of one hour. When you use the AssumeRole API operation to assume a role, you can specify the duration of your role session with the DurationSeconds parameter. You can specify a parameter value of up to 43200 seconds (12 hours), depending on the maximum session duration setting for your role. However, if you assume a role using role chaining and provide a DurationSeconds parameter value greater than one hour, the operation fails. Permissions The temporary security credentials created by AssumeRoleWithSAML can be used to make API calls to any Amazon Web Services service with the following exception: you cannot call the STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. Calling AssumeRoleWithSAML does not require the use of Amazon Web Services security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. Calling AssumeRoleWithSAML can result in an entry in your CloudTrail logs. The entry includes the value in the NameID element of the SAML assertion. We recommend that you use a NameIDType that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (urn:oasis:names:tc:SAML:2.0:nameid-format:persistent). Tags (Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. SAML Configuration Before your application can call AssumeRoleWithSAML, you must configure your SAML identity provider (IdP) to issue the claims required by Amazon Web Services. Additionally, you must use Identity and Access Management (IAM) to create a SAML provider entity in your Amazon Web Services account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. For more information, see the following resources: About SAML 2.0-based Federation (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html) in the IAM User Guide. Creating SAML Identity Providers (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html) in the IAM User Guide. Configuring a Relying Party and Claims (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html) in the IAM User Guide. Creating a Role for SAML 2.0 Federation (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html) in the IAM User Guide.
#
# GET /
# operationId: GET_AssumeRoleWithSAML
export def "api get-assume-role-with-saml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-arn: string # The Amazon Resource Name (ARN) of the role that the caller is assuming.
  --principal-arn: string # The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  --saml-assertion: string # The base64 encoded SAML authentication response provided by the IdP. For more information, see Configuring a Relying Party and Adding Claims (https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html) in the IAM User Guide.
  --policy-arns: list # The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role. This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide.
  --policy: string # An IAM policy in JSON format that you want to use as an inline session policy. This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit.
  --duration-seconds: int # The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the DurationSeconds parameter, or until the time specified in the SAML authentication response's SessionNotOnOrAfter value, whichever is shorter. You can provide a DurationSeconds value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. By default, the value is set to 3600 seconds. The DurationSeconds parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a SessionDuration parameter that specifies the maximum length of the console session. For more information, see Creating a URL that Enables Federated Users to Access the Amazon Web Services Management Console (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html) in the IAM User Guide.
  --action: string@action-completer-1
  --version: string@version-completer
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
  let qp = [(serialize-qp "RoleArn" $role_arn "scalar") (serialize-qp "PrincipalArn" $principal_arn "scalar") (serialize-qp "SAMLAssertion" $saml_assertion "scalar") (serialize-qp "PolicyArns" $policy_arns "multi") (serialize-qp "Policy" $policy "scalar") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RoleArn": $role_arn, "PrincipalArn": $principal_arn, "SAMLAssertion": $saml_assertion, "PolicyArns": $policy_arns, "Policy": $policy, "DurationSeconds": $duration_seconds, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based Amazon Web Services access without user-specific credentials or configuration. For a comparison of AssumeRoleWithSAML with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to Amazon Web Services services. Session Duration By default, the temporary security credentials created by AssumeRoleWithSAML last for one hour. However, you can use the optional DurationSeconds parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's SessionNotOnOrAfter value, whichever is shorter. You can provide a DurationSeconds value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. The maximum session duration limit applies when you use the AssumeRole* API operations or the assume-role* CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) in the IAM User Guide. Role chaining (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-role-chaining) limits your CLI or Amazon Web Services API role session to a maximum of one hour. When you use the AssumeRole API operation to assume a role, you can specify the duration of your role session with the DurationSeconds parameter. You can specify a parameter value of up to 43200 seconds (12 hours), depending on the maximum session duration setting for your role. However, if you assume a role using role chaining and provide a DurationSeconds parameter value greater than one hour, the operation fails. Permissions The temporary security credentials created by AssumeRoleWithSAML can be used to make API calls to any Amazon Web Services service with the following exception: you cannot call the STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. Calling AssumeRoleWithSAML does not require the use of Amazon Web Services security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. Calling AssumeRoleWithSAML can result in an entry in your CloudTrail logs. The entry includes the value in the NameID element of the SAML assertion. We recommend that you use a NameIDType that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (urn:oasis:names:tc:SAML:2.0:nameid-format:persistent). Tags (Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. SAML Configuration Before your application can call AssumeRoleWithSAML, you must configure your SAML identity provider (IdP) to issue the claims required by Amazon Web Services. Additionally, you must use Identity and Access Management (IAM) to create a SAML provider entity in your Amazon Web Services account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. For more information, see the following resources: About SAML 2.0-based Federation (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html) in the IAM User Guide. Creating SAML Identity Providers (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html) in the IAM User Guide. Configuring a Relying Party and Claims (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html) in the IAM User Guide. Creating a Role for SAML 2.0 Federation (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html) in the IAM User Guide.
#
# POST /
# operationId: POST_AssumeRoleWithSAML
export def "api create-assume-role-with-saml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include the OAuth 2.0 providers Login with Amazon and Facebook, or any OpenID Connect-compatible identity provider such as Google or Amazon Cognito federated identities (https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html). For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the Amazon Web Services SDK for iOS Developer Guide (http://aws.amazon.com/sdkforios/) and the Amazon Web Services SDK for Android Developer Guide (http://aws.amazon.com/sdkforandroid/) to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application. To learn more about Amazon Cognito, see Amazon Cognito Overview (https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840) in Amazon Web Services SDK for Android Developer Guide and Amazon Cognito Overview (https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664) in the Amazon Web Services SDK for iOS Developer Guide. Calling AssumeRoleWithWebIdentity does not require the use of Amazon Web Services security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term Amazon Web Services credentials in the application. You also don't need to deploy server-based proxy services that use long-term Amazon Web Services credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of AssumeRoleWithWebIdentity with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to Amazon Web Services service API operations. Session Duration By default, the temporary security credentials created by AssumeRoleWithWebIdentity last for one hour. However, you can use the optional DurationSeconds parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. The maximum session duration limit applies when you use the AssumeRole* API operations or the assume-role* CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) in the IAM User Guide. Permissions The temporary security credentials created by AssumeRoleWithWebIdentity can be used to make API calls to any Amazon Web Services service with the following exception: you cannot call the STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. Tags (Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. Identities Before your application can call AssumeRoleWithWebIdentity, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. Calling AssumeRoleWithWebIdentity can result in an entry in your CloudTrail logs. The entry includes the Subject (http://openid.net/specs/openid-connect-core-1_0.html#Claims) of the provided web identity token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as suggested in the OIDC specification (http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes). For more information about how to use web identity federation and the AssumeRoleWithWebIdentity API, see the following resources: Using Web Identity Federation API Operations for Mobile Apps (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html) and Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity). Web Identity Federation Playground (https://aws.amazon.com/blogs/aws/the-aws-web-identity-federation-playground/). Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to Amazon Web Services. Amazon Web Services SDK for iOS Developer Guide (http://aws.amazon.com/sdkforios/) and Amazon Web Services SDK for Android Developer Guide (http://aws.amazon.com/sdkforandroid/). These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. Web Identity Federation with Mobile Applications (http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications). This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3.
#
# GET /
# operationId: GET_AssumeRoleWithWebIdentity
export def "api get-assume-role-with-web-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-arn: string # The Amazon Resource Name (ARN) of the role that the caller is assuming.
  --role-session-name: string # An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the AssumedRoleUser response element. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-
  --web-identity-token: string # The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an AssumeRoleWithWebIdentity call.
  --provider-id: string # The fully qualified host component of the domain name of the OAuth 2.0 identity provider. Do not specify this value for an OpenID Connect identity provider. Currently www.amazon.com and graph.facebook.com are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers. Do not specify this value for OpenID Connect ID tokens.
  --policy-arns: list # The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role. This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide.
  --policy: string # An IAM policy in JSON format that you want to use as an inline session policy. This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit.
  --duration-seconds: int # The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. By default, the value is set to 3600 seconds. The DurationSeconds parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a SessionDuration parameter that specifies the maximum length of the console session. For more information, see Creating a URL that Enables Federated Users to Access the Amazon Web Services Management Console (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html) in the IAM User Guide.
  --action: string@action-completer-2
  --version: string@version-completer
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
  let qp = [(serialize-qp "RoleArn" $role_arn "scalar") (serialize-qp "RoleSessionName" $role_session_name "scalar") (serialize-qp "WebIdentityToken" $web_identity_token "scalar") (serialize-qp "ProviderId" $provider_id "scalar") (serialize-qp "PolicyArns" $policy_arns "multi") (serialize-qp "Policy" $policy "scalar") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RoleArn": $role_arn, "RoleSessionName": $role_session_name, "WebIdentityToken": $web_identity_token, "ProviderId": $provider_id, "PolicyArns": $policy_arns, "Policy": $policy, "DurationSeconds": $duration_seconds, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include the OAuth 2.0 providers Login with Amazon and Facebook, or any OpenID Connect-compatible identity provider such as Google or Amazon Cognito federated identities (https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html). For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the Amazon Web Services SDK for iOS Developer Guide (http://aws.amazon.com/sdkforios/) and the Amazon Web Services SDK for Android Developer Guide (http://aws.amazon.com/sdkforandroid/) to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application. To learn more about Amazon Cognito, see Amazon Cognito Overview (https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840) in Amazon Web Services SDK for Android Developer Guide and Amazon Cognito Overview (https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664) in the Amazon Web Services SDK for iOS Developer Guide. Calling AssumeRoleWithWebIdentity does not require the use of Amazon Web Services security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term Amazon Web Services credentials in the application. You also don't need to deploy server-based proxy services that use long-term Amazon Web Services credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of AssumeRoleWithWebIdentity with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to Amazon Web Services service API operations. Session Duration By default, the temporary security credentials created by AssumeRoleWithWebIdentity last for one hour. However, you can use the optional DurationSeconds parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see View the Maximum Session Duration Setting for a Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session) in the IAM User Guide. The maximum session duration limit applies when you use the AssumeRole* API operations or the assume-role* CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) in the IAM User Guide. Permissions The temporary security credentials created by AssumeRoleWithWebIdentity can be used to make API calls to any Amazon Web Services service with the following exception: you cannot call the STS GetFederationToken or GetSessionToken API operations. (Optional) You can pass inline or managed session policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent Amazon Web Services API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. Tags (Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see Chaining Roles with Session Tags (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining) in the IAM User Guide. Identities Before your application can call AssumeRoleWithWebIdentity, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. Calling AssumeRoleWithWebIdentity can result in an entry in your CloudTrail logs. The entry includes the Subject (http://openid.net/specs/openid-connect-core-1_0.html#Claims) of the provided web identity token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as suggested in the OIDC specification (http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes). For more information about how to use web identity federation and the AssumeRoleWithWebIdentity API, see the following resources: Using Web Identity Federation API Operations for Mobile Apps (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html) and Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity). Web Identity Federation Playground (https://aws.amazon.com/blogs/aws/the-aws-web-identity-federation-playground/). Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to Amazon Web Services. Amazon Web Services SDK for iOS Developer Guide (http://aws.amazon.com/sdkforios/) and Amazon Web Services SDK for Android Developer Guide (http://aws.amazon.com/sdkforandroid/). These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. Web Identity Federation with Mobile Applications (http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications). This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3.
#
# POST /
# operationId: POST_AssumeRoleWithWebIdentity
export def "api create-assume-role-with-web-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Decodes additional information about the authorization status of a request from an encoded message returned in response to an Amazon Web Services request. For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a Client.UnauthorizedOperation response (an HTTP 403 response). Some Amazon Web Services operations additionally return an encoded message that can provide details about this authorization failure. Only certain Amazon Web Services operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code. The message is encoded because the details of the authorization status can contain privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions through an IAM policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) to request the DecodeAuthorizationMessage (sts:DecodeAuthorizationMessage) action. The decoded message includes the following type of information: Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see Determining Whether a Request is Allowed or Denied (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow) in the IAM User Guide. The principal who made the request. The requested action. The requested resource. The values of condition keys in the context of the user's request.
#
# GET /
# operationId: GET_DecodeAuthorizationMessage
export def "api get-decode-authorization-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoded-message: string # The encoded message that was returned with the response.
  --action: string@action-completer-3
  --version: string@version-completer
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
  let qp = [(serialize-qp "EncodedMessage" $encoded_message "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EncodedMessage": $encoded_message, "Action": $action, "Version": $version} | compact), body: null}
}

# Decodes additional information about the authorization status of a request from an encoded message returned in response to an Amazon Web Services request. For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a Client.UnauthorizedOperation response (an HTTP 403 response). Some Amazon Web Services operations additionally return an encoded message that can provide details about this authorization failure. Only certain Amazon Web Services operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code. The message is encoded because the details of the authorization status can contain privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions through an IAM policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) to request the DecodeAuthorizationMessage (sts:DecodeAuthorizationMessage) action. The decoded message includes the following type of information: Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see Determining Whether a Request is Allowed or Denied (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow) in the IAM User Guide. The principal who made the request. The requested action. The requested resource. The values of condition keys in the context of the user's request.
#
# POST /
# operationId: POST_DecodeAuthorizationMessage
export def "api create-decode-authorization-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns the account identifier for the specified access key ID. Access keys consist of two parts: an access key ID (for example, AKIAIOSFODNN7EXAMPLE) and a secret access key (for example, wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY). For more information about access keys, see Managing Access Keys for IAM Users (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) in the IAM User Guide. When you pass an access key ID to this operation, it returns the ID of the Amazon Web Services account to which the keys belong. Access key IDs beginning with AKIA are long-term credentials for an IAM user or the Amazon Web Services account root user. Access key IDs beginning with ASIA are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a credentials report (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html) to learn which IAM user owns the keys. To learn who requested the temporary credentials for an ASIA access key, view the STS events in your CloudTrail logs (https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html) in the IAM User Guide. This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.
#
# GET /
# operationId: GET_GetAccessKeyInfo
export def "api get-access-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key-id: string # The identifier of an access key. This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercase letter or digit.
  --action: string@action-completer-4
  --version: string@version-completer
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
  let qp = [(serialize-qp "AccessKeyId" $access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AccessKeyId": $access_key_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns the account identifier for the specified access key ID. Access keys consist of two parts: an access key ID (for example, AKIAIOSFODNN7EXAMPLE) and a secret access key (for example, wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY). For more information about access keys, see Managing Access Keys for IAM Users (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) in the IAM User Guide. When you pass an access key ID to this operation, it returns the ID of the Amazon Web Services account to which the keys belong. Access key IDs beginning with AKIA are long-term credentials for an IAM user or the Amazon Web Services account root user. Access key IDs beginning with ASIA are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a credentials report (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html) to learn which IAM user owns the keys. To learn who requested the temporary credentials for an ASIA access key, view the STS events in your CloudTrail logs (https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html) in the IAM User Guide. This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.
#
# POST /
# operationId: POST_GetAccessKeyInfo
export def "api create-get-access-key-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns details about the IAM user or role whose credentials are used to call the operation. No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the sts:GetCallerIdentity action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice (https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa) in the IAM User Guide.
#
# GET /
# operationId: GET_GetCallerIdentity
export def "api get-caller-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
  --version: string@version-completer
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Returns details about the IAM user or role whose credentials are used to call the operation. No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the sts:GetCallerIdentity action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice (https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa) in the IAM User Guide.
#
# POST /
# operationId: POST_GetCallerIdentity
export def "api create-get-caller-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the GetFederationToken operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of GetFederationToken with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use Amazon Cognito (http://aws.amazon.com/cognito/) or AssumeRoleWithWebIdentity. For more information, see Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity) in the IAM User Guide. You can also call GetFederationToken using the security credentials of an Amazon Web Services account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see IAM Best Practices (https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) in the IAM User Guide. Session duration The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials obtained by using the Amazon Web Services account root user credentials have a maximum duration of 3,600 seconds (1 hour). Permissions You can use the temporary credentials created by GetFederationToken in any Amazon Web Services service with the following exceptions: You cannot call any IAM operations using the CLI or the Amazon Web Services API. This limitation does not apply to console sessions. You cannot call any STS operations except GetCallerIdentity. You can use temporary credentials for single sign-on (SSO) to the console. You must pass an inline or managed session policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. For information about using GetFederationToken to create temporary security credentials, see GetFederationToken—Federation Through a Custom Identity Broker (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken). You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the Principal element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies. Tags (Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use Amazon Cognito (http://aws.amazon.com/cognito/) or AssumeRoleWithWebIdentity. For more information, see Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity) in the IAM User Guide. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate Department and department tag keys. Assume that the user that you are federating has the Department=Marketing tag and you pass the department=engineering session tag. Department and department are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.
#
# GET /
# operationId: GET_GetFederationToken
export def "api get-federation-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the federated user. The name is used as an identifier for the temporary security credentials (such as Bob). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-
  --policy: string # An IAM policy in JSON format that you want to use as an inline session policy. You must pass an inline or managed session policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the Principal element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit.
  --policy-arns: list # The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access. You must pass an inline or managed session policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference. This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the Principal element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit.
  --duration-seconds: int # The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using Amazon Web Services account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  --tags: list # A list of session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. This parameter is optional. You can pass up to 50 session tags. The plaintext session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see IAM and STS Character Limits (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length) in the IAM User Guide. An Amazon Web Services conversion compresses the passed inline session policy, managed policy ARNs, and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plaintext meets the other requirements. The PackedPolicySize response element indicates by percentage how close the policies and tags for your request are to the upper size limit. You can pass a session tag with the same key as a tag that is already attached to the user you are federating. When you do, session tags override a user tag with the same key. Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate Department and department tag keys. Assume that the role has the Department=Marketing tag and you pass the department=engineering session tag. Department and department are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.
  --action: string@action-completer-6
  --version: string@version-completer
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
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Policy" $policy "scalar") (serialize-qp "PolicyArns" $policy_arns "multi") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Name": $name, "Policy": $policy, "PolicyArns": $policy_arns, "DurationSeconds": $duration_seconds, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the GetFederationToken operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of GetFederationToken with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use Amazon Cognito (http://aws.amazon.com/cognito/) or AssumeRoleWithWebIdentity. For more information, see Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity) in the IAM User Guide. You can also call GetFederationToken using the security credentials of an Amazon Web Services account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see IAM Best Practices (https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) in the IAM User Guide. Session duration The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials obtained by using the Amazon Web Services account root user credentials have a maximum duration of 3,600 seconds (1 hour). Permissions You can use the temporary credentials created by GetFederationToken in any Amazon Web Services service with the following exceptions: You cannot call any IAM operations using the CLI or the Amazon Web Services API. This limitation does not apply to console sessions. You cannot call any STS operations except GetCallerIdentity. You can use temporary credentials for single sign-on (SSO) to the console. You must pass an inline or managed session policy (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policy Amazon Resource Names (ARNs) to use as managed session policies. The plaintext that you use for both inline and managed session policies can't exceed 2,048 characters. Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see Session Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session) in the IAM User Guide. For information about using GetFederationToken to create temporary security credentials, see GetFederationToken—Federation Through a Custom Identity Broker (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken). You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the Principal element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies. Tags (Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see Passing Session Tags in STS (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) in the IAM User Guide. You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use Amazon Cognito (http://aws.amazon.com/cognito/) or AssumeRoleWithWebIdentity. For more information, see Federation Through a Web-based Identity Provider (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity) in the IAM User Guide. An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see Tutorial: Using Tags for Attribute-Based Access Control (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html) in the IAM User Guide. Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate Department and department tag keys. Assume that the user that you are federating has the Department=Marketing tag and you pass the department=engineering session tag. Department and department are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.
#
# POST /
# operationId: POST_GetFederationToken
export def "api create-get-federation-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a set of temporary credentials for an Amazon Web Services account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use GetSessionToken if you want to use MFA to protect programmatic calls to specific Amazon Web Services API operations like Amazon EC2 StopInstances. MFA-enabled IAM users would need to call GetSessionToken and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of GetSessionToken with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. No permissions are required for users to perform this operation. The purpose of the sts:GetSessionToken operation is to authenticate the user using MFA. You cannot use policies to control authentication operations. For more information, see Permissions for GetSessionToken (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_getsessiontoken.html) in the IAM User Guide. Session Duration The GetSessionToken operation must be called by using the long-term Amazon Web Services security credentials of the Amazon Web Services account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. Permissions The temporary security credentials created by GetSessionToken can be used to make API calls to any Amazon Web Services service with the following exceptions: You cannot call any IAM API operations unless MFA authentication information is included in the request. You cannot call any STS API except AssumeRole or GetCallerIdentity. We recommend that you do not call GetSessionToken with Amazon Web Services account root user credentials. Instead, follow our best practices (https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users) by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with Amazon Web Services. The credentials that are returned by GetSessionToken are based on permissions associated with the user whose credentials were used to call the operation. If GetSessionToken is called using Amazon Web Services account root user credentials, the temporary credentials have root user permissions. Similarly, if GetSessionToken is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. For more information about using GetSessionToken to create temporary credentials, go to Temporary Credentials for Users in Untrusted Environments (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken) in the IAM User Guide.
#
# GET /
# operationId: GET_GetSessionToken
export def "api get-session-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --duration-seconds: int # The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for Amazon Web Services account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for Amazon Web Services account owners defaults to one hour.
  --serial-number: string # The identification number of the MFA device that is associated with the IAM user who is making the GetSessionToken call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as GAHT12345678) or an Amazon Resource Name (ARN) for a virtual device (such as arn:aws:iam::123456789012:mfa/user). You can find the device for an IAM user by going to the Amazon Web Services Management Console and viewing the user's security credentials. The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-
  --token-code: string # The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication. The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.
  --action: string@action-completer-7
  --version: string@version-completer
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
  let qp = [(serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "SerialNumber" $serial_number "scalar") (serialize-qp "TokenCode" $token_code "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DurationSeconds": $duration_seconds, "SerialNumber": $serial_number, "TokenCode": $token_code, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a set of temporary credentials for an Amazon Web Services account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use GetSessionToken if you want to use MFA to protect programmatic calls to specific Amazon Web Services API operations like Amazon EC2 StopInstances. MFA-enabled IAM users would need to call GetSessionToken and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of GetSessionToken with the other API operations that produce temporary credentials, see Requesting Temporary Security Credentials (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html) and Comparing the Amazon Web Services STS API operations (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison) in the IAM User Guide. No permissions are required for users to perform this operation. The purpose of the sts:GetSessionToken operation is to authenticate the user using MFA. You cannot use policies to control authentication operations. For more information, see Permissions for GetSessionToken (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_getsessiontoken.html) in the IAM User Guide. Session Duration The GetSessionToken operation must be called by using the long-term Amazon Web Services security credentials of the Amazon Web Services account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. Permissions The temporary security credentials created by GetSessionToken can be used to make API calls to any Amazon Web Services service with the following exceptions: You cannot call any IAM API operations unless MFA authentication information is included in the request. You cannot call any STS API except AssumeRole or GetCallerIdentity. We recommend that you do not call GetSessionToken with Amazon Web Services account root user credentials. Instead, follow our best practices (https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users) by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with Amazon Web Services. The credentials that are returned by GetSessionToken are based on permissions associated with the user whose credentials were used to call the operation. If GetSessionToken is called using Amazon Web Services account root user credentials, the temporary credentials have root user permissions. Similarly, if GetSessionToken is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. For more information about using GetSessionToken to create temporary credentials, go to Temporary Credentials for Users in Untrusted Environments (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken) in the IAM User Guide.
#
# POST /
# operationId: POST_GetSessionToken
export def "api create-get-session-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}
