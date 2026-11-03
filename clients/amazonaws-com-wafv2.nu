# Auto-generated client for AWS WAFV2 v2019-07-29
# Source: https://api.apis.guru/v2/specs/amazonaws.com/wafv2/2019-07-29/openapi.json
# Auth: --token flag or $env.AWS_WAFV2_TOKEN

const BASE_URL = "http://wafv2.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_WAFV2_TOKEN | default "" }
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

def base-url-completer [] { ["http://wafv2.us-east-1.amazonaws.com" "http://wafv2.us-east-2.amazonaws.com" "http://wafv2.us-west-1.amazonaws.com" "http://wafv2.us-west-2.amazonaws.com" "http://wafv2.us-gov-west-1.amazonaws.com" "http://wafv2.us-gov-east-1.amazonaws.com" "http://wafv2.ca-central-1.amazonaws.com" "http://wafv2.eu-north-1.amazonaws.com" "http://wafv2.eu-west-1.amazonaws.com" "http://wafv2.eu-west-2.amazonaws.com" "http://wafv2.eu-west-3.amazonaws.com" "http://wafv2.eu-central-1.amazonaws.com" "http://wafv2.eu-south-1.amazonaws.com" "http://wafv2.af-south-1.amazonaws.com" "http://wafv2.ap-northeast-1.amazonaws.com" "http://wafv2.ap-northeast-2.amazonaws.com" "http://wafv2.ap-northeast-3.amazonaws.com" "http://wafv2.ap-southeast-1.amazonaws.com" "http://wafv2.ap-southeast-2.amazonaws.com" "http://wafv2.ap-east-1.amazonaws.com" "http://wafv2.ap-south-1.amazonaws.com" "http://wafv2.sa-east-1.amazonaws.com" "http://wafv2.me-south-1.amazonaws.com" "https://wafv2.us-east-1.amazonaws.com" "https://wafv2.us-east-2.amazonaws.com" "https://wafv2.us-west-1.amazonaws.com" "https://wafv2.us-west-2.amazonaws.com" "https://wafv2.us-gov-west-1.amazonaws.com" "https://wafv2.us-gov-east-1.amazonaws.com" "https://wafv2.ca-central-1.amazonaws.com" "https://wafv2.eu-north-1.amazonaws.com" "https://wafv2.eu-west-1.amazonaws.com" "https://wafv2.eu-west-2.amazonaws.com" "https://wafv2.eu-west-3.amazonaws.com" "https://wafv2.eu-central-1.amazonaws.com" "https://wafv2.eu-south-1.amazonaws.com" "https://wafv2.af-south-1.amazonaws.com" "https://wafv2.ap-northeast-1.amazonaws.com" "https://wafv2.ap-northeast-2.amazonaws.com" "https://wafv2.ap-northeast-3.amazonaws.com" "https://wafv2.ap-southeast-1.amazonaws.com" "https://wafv2.ap-southeast-2.amazonaws.com" "https://wafv2.ap-east-1.amazonaws.com" "https://wafv2.ap-south-1.amazonaws.com" "https://wafv2.sa-east-1.amazonaws.com" "https://wafv2.me-south-1.amazonaws.com" "http://wafv2.cn-north-1.amazonaws.com.cn" "http://wafv2.cn-northwest-1.amazonaws.com.cn" "https://wafv2.cn-north-1.amazonaws.com.cn" "https://wafv2.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSWAF_20190729.AssociateWebACL"] }
def scope-completer [] { ["CLOUDFRONT" "REGIONAL"] }
def x-amz-target-completer-1 [] { ["AWSWAF_20190729.CheckCapacity"] }
def x-amz-target-completer-2 [] { ["AWSWAF_20190729.CreateAPIKey"] }
def ip-address-version-completer [] { ["IPV4" "IPV6"] }
def x-amz-target-completer-3 [] { ["AWSWAF_20190729.CreateIPSet"] }
def x-amz-target-completer-4 [] { ["AWSWAF_20190729.CreateRegexPatternSet"] }
def x-amz-target-completer-5 [] { ["AWSWAF_20190729.CreateRuleGroup"] }
def x-amz-target-completer-6 [] { ["AWSWAF_20190729.CreateWebACL"] }
def x-amz-target-completer-7 [] { ["AWSWAF_20190729.DeleteFirewallManagerRuleGroups"] }
def x-amz-target-completer-8 [] { ["AWSWAF_20190729.DeleteIPSet"] }
def x-amz-target-completer-9 [] { ["AWSWAF_20190729.DeleteLoggingConfiguration"] }
def x-amz-target-completer-10 [] { ["AWSWAF_20190729.DeletePermissionPolicy"] }
def x-amz-target-completer-11 [] { ["AWSWAF_20190729.DeleteRegexPatternSet"] }
def x-amz-target-completer-12 [] { ["AWSWAF_20190729.DeleteRuleGroup"] }
def x-amz-target-completer-13 [] { ["AWSWAF_20190729.DeleteWebACL"] }
def x-amz-target-completer-14 [] { ["AWSWAF_20190729.DescribeManagedRuleGroup"] }
def x-amz-target-completer-15 [] { ["AWSWAF_20190729.DisassociateWebACL"] }
def platform-completer [] { ["ANDROID" "IOS"] }
def x-amz-target-completer-16 [] { ["AWSWAF_20190729.GenerateMobileSdkReleaseUrl"] }
def x-amz-target-completer-17 [] { ["AWSWAF_20190729.GetDecryptedAPIKey"] }
def x-amz-target-completer-18 [] { ["AWSWAF_20190729.GetIPSet"] }
def x-amz-target-completer-19 [] { ["AWSWAF_20190729.GetLoggingConfiguration"] }
def x-amz-target-completer-20 [] { ["AWSWAF_20190729.GetManagedRuleSet"] }
def x-amz-target-completer-21 [] { ["AWSWAF_20190729.GetMobileSdkRelease"] }
def x-amz-target-completer-22 [] { ["AWSWAF_20190729.GetPermissionPolicy"] }
def x-amz-target-completer-23 [] { ["AWSWAF_20190729.GetRateBasedStatementManagedKeys"] }
def x-amz-target-completer-24 [] { ["AWSWAF_20190729.GetRegexPatternSet"] }
def x-amz-target-completer-25 [] { ["AWSWAF_20190729.GetRuleGroup"] }
def x-amz-target-completer-26 [] { ["AWSWAF_20190729.GetSampledRequests"] }
def x-amz-target-completer-27 [] { ["AWSWAF_20190729.GetWebACL"] }
def x-amz-target-completer-28 [] { ["AWSWAF_20190729.GetWebACLForResource"] }
def x-amz-target-completer-29 [] { ["AWSWAF_20190729.ListAPIKeys"] }
def x-amz-target-completer-30 [] { ["AWSWAF_20190729.ListAvailableManagedRuleGroupVersions"] }
def x-amz-target-completer-31 [] { ["AWSWAF_20190729.ListAvailableManagedRuleGroups"] }
def x-amz-target-completer-32 [] { ["AWSWAF_20190729.ListIPSets"] }
def x-amz-target-completer-33 [] { ["AWSWAF_20190729.ListLoggingConfigurations"] }
def x-amz-target-completer-34 [] { ["AWSWAF_20190729.ListManagedRuleSets"] }
def x-amz-target-completer-35 [] { ["AWSWAF_20190729.ListMobileSdkReleases"] }
def x-amz-target-completer-36 [] { ["AWSWAF_20190729.ListRegexPatternSets"] }
def resource-type-completer [] { ["API_GATEWAY" "APPLICATION_LOAD_BALANCER" "APPSYNC" "APP_RUNNER_SERVICE" "COGNITO_USER_POOL"] }
def x-amz-target-completer-37 [] { ["AWSWAF_20190729.ListResourcesForWebACL"] }
def x-amz-target-completer-38 [] { ["AWSWAF_20190729.ListRuleGroups"] }
def x-amz-target-completer-39 [] { ["AWSWAF_20190729.ListTagsForResource"] }
def x-amz-target-completer-40 [] { ["AWSWAF_20190729.ListWebACLs"] }
def x-amz-target-completer-41 [] { ["AWSWAF_20190729.PutLoggingConfiguration"] }
def x-amz-target-completer-42 [] { ["AWSWAF_20190729.PutManagedRuleSetVersions"] }
def x-amz-target-completer-43 [] { ["AWSWAF_20190729.PutPermissionPolicy"] }
def x-amz-target-completer-44 [] { ["AWSWAF_20190729.TagResource"] }
def x-amz-target-completer-45 [] { ["AWSWAF_20190729.UntagResource"] }
def x-amz-target-completer-46 [] { ["AWSWAF_20190729.UpdateIPSet"] }
def x-amz-target-completer-47 [] { ["AWSWAF_20190729.UpdateManagedRuleSetVersionExpiryDate"] }
def x-amz-target-completer-48 [] { ["AWSWAF_20190729.UpdateRegexPatternSet"] }
def x-amz-target-completer-49 [] { ["AWSWAF_20190729.UpdateRuleGroup"] }
def x-amz-target-completer-50 [] { ["AWSWAF_20190729.UpdateWebACL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "associate-web-acl" } } | get name | first)
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

# Associates a web ACL with a regional application resource, to protect the resource. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. For Amazon CloudFront, don't use this call. Instead, use your CloudFront distribution configuration. To associate a web ACL, in the CloudFront call UpdateDistribution, set the web ACL ID to the Amazon Resource Name (ARN) of the web ACL. For information, see UpdateDistribution (https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html) in the Amazon CloudFront Developer Guide. When you make changes to web ACLs or web ACL components, like rules and rule groups, WAF propagates the changes everywhere that the web ACL and its components are stored and used. Your changes are applied within seconds, but there might be a brief period of inconsistency when the changes have arrived in some places and not in others. So, for example, if you change a rule action setting, the action might be the old action in one area and the new action in another area. Or if you add an IP address to an IP set used in a blocking rule, the new address might briefly be blocked in one area while still allowed in another. This temporary inconsistency can occur when you first associate a web ACL with an Amazon Web Services resource and when you change a web ACL that is already associated with a resource. Generally, any inconsistencies of this type last only a few seconds.
#
# POST /
# operationId: AssociateWebACL
export def "associate-web-acl" [
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
  web_acl_arn: string # The Amazon Resource Name (ARN) of the web ACL that you want to associate with the resource.
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to associate with the web ACL. The ARN must be in one of the following formats: For an Application Load Balancer: arn:partition:elasticloadbalancing:region:account-id:loadbalancer/app/load-balancer-name/load-balancer-id For an Amazon API Gateway REST API: arn:partition:apigateway:region::/restapis/api-id/stages/stage-name For an AppSync GraphQL API: arn:partition:appsync:region:account-id:apis/GraphQLApiId For an Amazon Cognito user pool: arn:partition:cognito-idp:region:account-id:userpool/user-pool-id For an App Runner service: arn:partition:apprunner:region:account-id:service/apprunner-service-name/apprunner-service-id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.AssociateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLArn": $web_acl_arn, "ResourceArn": $resource_arn} | compact
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

# Returns the web ACL capacity unit (WCU) requirements for a specified scope and set of rules. You can use this to check the capacity requirements for the rules you want to use in a RuleGroup or WebACL. WAF uses WCUs to calculate and control the operating resources that are used to run your rules, rule groups, and web ACLs. WAF calculates capacity differently for each rule type, to reflect the relative cost of each rule. Simple rules that cost little to run use fewer WCUs than more complex rules that use more processing power. Rule group capacity is fixed at creation, which helps users plan their web ACL WCU usage when they use a rule group. For more information, see WAF web ACL capacity units (WCU) (https://docs.aws.amazon.com/waf/latest/developerguide/aws-waf-capacity-units.html) in the WAF Developer Guide.
#
# POST /
# operationId: CheckCapacity
# --Rules item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
export def "check-capacity" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  rules: list # An array of Rule that you're configuring to use in a rule group or web ACL. — item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
]: any -> record<Capacity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CheckCapacity")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "Rules": $rules} | compact
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

# Creates an API key for use in the integration of the CAPTCHA API in your JavaScript client applications. The integration lets you customize the placement and characteristics of the CAPTCHA puzzle for your end users. For more information about the CAPTCHA JavaScript integration, see WAF client application integration (https://docs.aws.amazon.com/waf/latest/developerguide/waf-application-integration.html) in the WAF Developer Guide. The CAPTCHA API requires a key that authorizes CAPTCHA use from the client application domain. You can use a single key for up to 5 domains. After you generate a key, you can copy it for use in your JavaScript integration.
#
# POST /
# operationId: CreateAPIKey
export def "create-api-key" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  token_domains: list<string> # The client application domains that you want to use this API key for.
]: any -> record<APIKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CreateAPIKey")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "TokenDomains": $token_domains} | compact
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

# Creates an IPSet, which you use to identify web requests that originate from specific IP addresses or ranges of IP addresses. For example, if you're receiving a lot of requests from a ranges of IP addresses, you can configure WAF to block them using an IPSet that lists those IP addresses.
#
# POST /
# operationId: CreateIPSet
# --Tags item shape: {Key: string, Value: string}
export def "create-ip-set" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  name: string # The name of the IP set. You cannot change the name of an IPSet after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --description: string # A description of the IP set that helps with identification.
  ip_address_version: string@ip-address-version-completer # The version of the IP addresses, either IPV4 or IPV6.
  addresses: list<string> # Contains an array of strings that specifies zero or more IP addresses or blocks of IP addresses. All addresses must be specified using Classless Inter-Domain Routing (CIDR) notation. WAF supports all IPv4 and IPv6 CIDR ranges except for /0. Example address strings: To configure WAF to allow, block, or count requests that originated from the IP address 192.0.2.44, specify 192.0.2.44/32. To configure WAF to allow, block, or count requests that originated from IP addresses from 192.0.2.0 to 192.0.2.255, specify 192.0.2.0/24. To configure WAF to allow, block, or count requests that originated from the IP address 1111:0000:0000:0000:0000:0000:0000:0111, specify 1111:0000:0000:0000:0000:0000:0000:0111/128. To configure WAF to allow, block, or count requests that originated from IP addresses 1111:0000:0000:0000:0000:0000:0000:0000 to 1111:0000:0000:0000:ffff:ffff:ffff:ffff, specify 1111:0000:0000:0000:0000:0000:0000:0000/64. For more information about CIDR notation, see the Wikipedia entry Classless Inter-Domain Routing (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). Example JSON Addresses specifications: Empty array: "Addresses": [] Array with one address: "Addresses": ["192.0.2.44/32"] Array with three addresses: "Addresses": ["192.0.2.44/32", "192.0.2.0/24", "192.0.0.0/16"] INVALID specification: "Addresses": [""] INVALID
  --tags: list # An array of key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
]: any -> record<Summary: record<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CreateIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Description": $description, "IPAddressVersion": $ip_address_version, "Addresses": $addresses, "Tags": $tags} | compact
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

# Creates a RegexPatternSet, which you reference in a RegexPatternSetReferenceStatement, to have WAF inspect a web request component for the specified patterns.
#
# POST /
# operationId: CreateRegexPatternSet
# --RegularExpressionList item shape: {RegexString?: string}
# --Tags item shape: {Key: string, Value: string}
export def "create-regex-pattern-set" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  name: string # The name of the set. You cannot change the name after you create the set.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --description: string # A description of the set that helps with identification.
  regular_expression_list: list # Array of regular expression strings. — item shape: {RegexString?: string}
  --tags: list # An array of key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
]: any -> record<Summary: record<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CreateRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Description": $description, "RegularExpressionList": $regular_expression_list, "Tags": $tags} | compact
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

# Creates a RuleGroup per the specifications provided. A rule group defines a collection of rules to inspect and control web requests that you can use in a WebACL. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements.
#
# POST /
# operationId: CreateRuleGroup
# --Rules item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
# --VisibilityConfig shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
# --Tags item shape: {Key: string, Value: string}
export def "create-rule-group" [
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
  name: string # The name of the rule group. You cannot change the name of a rule group after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  capacity: int # The web ACL capacity units (WCUs) required for this rule group. When you create your own rule group, you define this, and you cannot change it after creation. When you add or modify the rules in a rule group, WAF enforces this limit. You can check the capacity for a set of rules using CheckCapacity. WAF uses WCUs to calculate and control the operating resources that are used to run your rules, rule groups, and web ACLs. WAF calculates capacity differently for each rule type, to reflect the relative cost of each rule. Simple rules that cost little to run use fewer WCUs than more complex rules that use more processing power. Rule group capacity is fixed at creation, which helps users plan their web ACL WCU usage when they use a rule group. For more information, see WAF web ACL capacity units (WCU) (https://docs.aws.amazon.com/waf/latest/developerguide/aws-waf-capacity-units.html) in the WAF Developer Guide.
  --description: string # A description of the rule group that helps with identification.
  --rules: list # The Rule statements used to identify the web requests that you want to allow, block, or count. Each rule includes one top-level statement that WAF uses to identify matching web requests, and parameters that govern how WAF handles them. — item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
  visibility_config: record # Defines and enables Amazon CloudWatch metrics and web request sample collection. — shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
  --tags: list # An array of key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --custom-response-bodies: record # A map of custom response keys and content bodies. When you create a rule with a block action, you can send a custom response to the web request. You define these for the rule group, and then use them in the rules that you define in the rule group. For information about customizing web requests and responses, see Customizing web requests and responses in WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-custom-request-response.html) in the WAF Developer Guide. For information about the limits on count and size for custom request and response settings, see WAF quotas (https://docs.aws.amazon.com/waf/latest/developerguide/limits.html) in the WAF Developer Guide.
]: any -> record<Summary: record<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CreateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Capacity": $capacity, "Description": $description, "Rules": $rules, "VisibilityConfig": $visibility_config, "Tags": $tags, "CustomResponseBodies": $custom_response_bodies} | compact
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

# Creates a WebACL per the specifications provided. A web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a web ACL can be a combination of the types Rule, RuleGroup, and managed rule group. You can associate a web ACL with one or more Amazon Web Services resources to protect. The resources can be an Amazon CloudFront distribution, an Amazon API Gateway REST API, an Application Load Balancer, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service.
#
# POST /
# operationId: CreateWebACL
# --DefaultAction shape: {Block?: record, Allow?: record}
# --Rules item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
# --VisibilityConfig shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
# --Tags item shape: {Key: string, Value: string}
# --CaptchaConfig shape: {ImmunityTimeProperty?: record}
# --ChallengeConfig shape: {ImmunityTimeProperty?: record}
# --AssociationConfig shape: {RequestBody?: record}
export def "create-web-acl" [
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
  name: string # The name of the web ACL. You cannot change the name of a web ACL after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  default_action: record # In a WebACL, this is the action that you want WAF to perform when a web request doesn't match any of the rules in the WebACL. The default action must be a terminating action. — shape: {Block?: record, Allow?: record}
  --description: string # A description of the web ACL that helps with identification.
  --rules: list # The Rule statements used to identify the web requests that you want to allow, block, or count. Each rule includes one top-level statement that WAF uses to identify matching web requests, and parameters that govern how WAF handles them. — item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
  visibility_config: record # Defines and enables Amazon CloudWatch metrics and web request sample collection. — shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
  --tags: list # An array of key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --custom-response-bodies: record # A map of custom response keys and content bodies. When you create a rule with a block action, you can send a custom response to the web request. You define these for the web ACL, and then use them in the rules and default actions that you define in the web ACL. For information about customizing web requests and responses, see Customizing web requests and responses in WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-custom-request-response.html) in the WAF Developer Guide. For information about the limits on count and size for custom request and response settings, see WAF quotas (https://docs.aws.amazon.com/waf/latest/developerguide/limits.html) in the WAF Developer Guide.
  --captcha-config: record # Specifies how WAF should handle CAPTCHA evaluations. This is available at the web ACL level and in each rule. — shape: {ImmunityTimeProperty?: record}
  --challenge-config: record # Specifies how WAF should handle Challenge evaluations. This is available at the web ACL level and in each rule. — shape: {ImmunityTimeProperty?: record}
  --token-domains: list<string> # Specifies the domains that WAF should accept in a web request token. This enables the use of tokens across multiple protected websites. When WAF provides a token, it uses the domain of the Amazon Web Services resource that the web ACL is protecting. If you don't specify a list of token domains, WAF accepts tokens only for the domain of the protected resource. With a token domain list, WAF accepts the resource's host domain plus all domains in the token domain list, including their prefixed subdomains. Example JSON: "TokenDomains": { "mywebsite.com", "myotherwebsite.com" } Public suffixes aren't allowed. For example, you can't use usa.gov or co.uk as token domains.
  --association-config: record # Specifies custom configurations for the associations between the web ACL and protected resources. Use this to customize the maximum size of the request body that your protected CloudFront distributions forward to WAF for inspection. The default is 16 KB (16,384 kilobytes). You are charged additional fees when your protected resources forward body sizes that are larger than the default. For more information, see WAF Pricing (http://aws.amazon.com/waf/pricing/). — shape: {RequestBody?: record}
]: any -> record<Summary: record<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.CreateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "DefaultAction": $default_action, "Description": $description, "Rules": $rules, "VisibilityConfig": $visibility_config, "Tags": $tags, "CustomResponseBodies": $custom_response_bodies, "CaptchaConfig": $captcha_config, "ChallengeConfig": $challenge_config, "TokenDomains": $token_domains, "AssociationConfig": $association_config} | compact
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

# Deletes all rule groups that are managed by Firewall Manager for the specified web ACL. You can only use this if ManagedByFirewallManager is false in the specified WebACL.
#
# POST /
# operationId: DeleteFirewallManagerRuleGroups
export def "delete-firewall-manager-rule-groups" [
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
  web_acl_arn: string # The Amazon Resource Name (ARN) of the web ACL.
  web_acl_lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record<NextWebACLLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteFirewallManagerRuleGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLArn": $web_acl_arn, "WebACLLockToken": $web_acl_lock_token} | compact
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

# Deletes the specified IPSet.
#
# POST /
# operationId: DeleteIPSet
export def "delete-ip-set" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  name: string # The name of the IP set. You cannot change the name of an IPSet after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token} | compact
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

# Deletes the LoggingConfiguration from the specified web ACL.
#
# POST /
# operationId: DeleteLoggingConfiguration
export def "delete-logging-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the web ACL from which you want to delete the LoggingConfiguration.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Permanently deletes an IAM policy from the specified rule group. You must be the owner of the rule group to perform this operation.
#
# POST /
# operationId: DeletePermissionPolicy
export def "delete-permission-policy" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the rule group from which you want to delete the policy. You must be the owner of the rule group to perform this operation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeletePermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Deletes the specified RegexPatternSet.
#
# POST /
# operationId: DeleteRegexPatternSet
export def "delete-regex-pattern-set" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  name: string # The name of the set. You cannot change the name after you create the set.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token} | compact
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

# Deletes the specified RuleGroup.
#
# POST /
# operationId: DeleteRuleGroup
export def "delete-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  name: string # The name of the rule group. You cannot change the name of a rule group after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the rule group. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token} | compact
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

# Deletes the specified WebACL. You can only use this if ManagedByFirewallManager is false in the specified WebACL. Before deleting any web ACL, first disassociate it from all resources. To retrieve a list of the resources that are associated with a web ACL, use the following calls: For regional resources, call ListResourcesForWebACL. For Amazon CloudFront distributions, use the CloudFront call ListDistributionsByWebACLId. For information, see ListDistributionsByWebACLId (https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_ListDistributionsByWebACLId.html) in the Amazon CloudFront API Reference. To disassociate a resource from a web ACL, use the following calls: For regional resources, call DisassociateWebACL. For Amazon CloudFront distributions, provide an empty web ACL ID in the CloudFront call UpdateDistribution. For information, see UpdateDistribution (https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html) in the Amazon CloudFront API Reference.
#
# POST /
# operationId: DeleteWebACL
export def "delete-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  name: string # The name of the web ACL. You cannot change the name of a web ACL after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # The unique identifier for the web ACL. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DeleteWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token} | compact
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

# Provides high-level information for a managed rule group, including descriptions of the rules.
#
# POST /
# operationId: DescribeManagedRuleGroup
export def "describe-managed-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  vendor_name: string # The name of the managed rule group vendor. You use this, along with the rule group name, to identify the rule group.
  name: string # The name of the managed rule group. You use this, along with the vendor name, to identify the rule group.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --version-name: string # The version of the rule group. You can only use a version that is not scheduled for expiration. If you don't provide this, WAF uses the vendor's default version.
]: any -> record<VersionName: string, SnsTopicArn: string, Capacity: int, Rules: table<Name: string, Action: record>, LabelNamespace: string, AvailableLabels: table<Name: string>, ConsumedLabels: table<Name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DescribeManagedRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VendorName": $vendor_name, "Name": $name, "Scope": $scope, "VersionName": $version_name} | compact
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

# Disassociates the specified regional application resource from any existing web ACL association. A resource can have at most one web ACL association. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. For Amazon CloudFront, don't use this call. Instead, use your CloudFront distribution configuration. To disassociate a web ACL, provide an empty web ACL ID in the CloudFront call UpdateDistribution. For information, see UpdateDistribution (https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html) in the Amazon CloudFront API Reference.
#
# POST /
# operationId: DisassociateWebACL
export def "disassociate-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to disassociate from the web ACL. The ARN must be in one of the following formats: For an Application Load Balancer: arn:partition:elasticloadbalancing:region:account-id:loadbalancer/app/load-balancer-name/load-balancer-id For an Amazon API Gateway REST API: arn:partition:apigateway:region::/restapis/api-id/stages/stage-name For an AppSync GraphQL API: arn:partition:appsync:region:account-id:apis/GraphQLApiId For an Amazon Cognito user pool: arn:partition:cognito-idp:region:account-id:userpool/user-pool-id For an App Runner service: arn:partition:apprunner:region:account-id:service/apprunner-service-name/apprunner-service-id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.DisassociateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Generates a presigned download URL for the specified release of the mobile SDK. The mobile SDK is not generally available. Customers who have access to the mobile SDK can use it to establish and manage WAF tokens for use in HTTP(S) requests from a mobile device to WAF. For more information, see WAF client application integration (https://docs.aws.amazon.com/waf/latest/developerguide/waf-application-integration.html) in the WAF Developer Guide.
#
# POST /
# operationId: GenerateMobileSdkReleaseUrl
export def "generate-mobile-sdk-release-url" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  platform: string@platform-completer # The device platform.
  release_version: string # The release version. For the latest available version, specify LATEST.
]: any -> record<Url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GenerateMobileSdkReleaseUrl")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Platform": $platform, "ReleaseVersion": $release_version} | compact
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

# Returns your API key in decrypted form. Use this to check the token domains that you have defined for the key.
#
# POST /
# operationId: GetDecryptedAPIKey
export def "get-decrypted-api-key" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  api_key: string # The encrypted API key.
]: any -> record<TokenDomains: list<string>, CreationTimestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetDecryptedAPIKey")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "APIKey": $api_key} | compact
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

# Retrieves the specified IPSet.
#
# POST /
# operationId: GetIPSet
export def "get-ip-set" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  name: string # The name of the IP set. You cannot change the name of an IPSet after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
]: any -> record<IPSet: record<Name: string, Id: string, ARN: string, Description: string, IPAddressVersion: string, Addresses: list<string>>, LockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id} | compact
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

# Returns the LoggingConfiguration for the specified web ACL.
#
# POST /
# operationId: GetLoggingConfiguration
export def "get-logging-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the web ACL for which you want to get the LoggingConfiguration.
]: any -> record<LoggingConfiguration: record<ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields: list<record>, ManagedByFirewallManager: bool, LoggingFilter: record<Filters: list, DefaultBehavior: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Retrieves the specified managed rule set. This is intended for use only by vendors of managed rule sets. Vendors are Amazon Web Services and Amazon Web Services Marketplace sellers. Vendors, you can use the managed rule set APIs to provide controlled rollout of your versioned managed rule group offerings for your customers. The APIs are ListManagedRuleSets, GetManagedRuleSet, PutManagedRuleSetVersions, and UpdateManagedRuleSetVersionExpiryDate.
#
# POST /
# operationId: GetManagedRuleSet
export def "get-managed-rule-set" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  name: string # The name of the managed rule set. You use this, along with the rule set ID, to identify the rule set. This name is assigned to the corresponding managed rule group, which your customers can access and use.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the managed rule set. The ID is returned in the responses to commands like list. You provide it to operations like get and update.
]: any -> record<ManagedRuleSet: record<Name: string, Id: string, ARN: string, Description: string, PublishedVersions: record, RecommendedVersion: string, LabelNamespace: string>, LockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetManagedRuleSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id} | compact
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

# Retrieves information for the specified mobile SDK release, including release notes and tags. The mobile SDK is not generally available. Customers who have access to the mobile SDK can use it to establish and manage WAF tokens for use in HTTP(S) requests from a mobile device to WAF. For more information, see WAF client application integration (https://docs.aws.amazon.com/waf/latest/developerguide/waf-application-integration.html) in the WAF Developer Guide.
#
# POST /
# operationId: GetMobileSdkRelease
export def "get-mobile-sdk-release" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  platform: string@platform-completer # The device platform.
  release_version: string # The release version. For the latest available version, specify LATEST.
]: any -> record<MobileSdkRelease: record<ReleaseVersion: string, Timestamp: string, ReleaseNotes: string, Tags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetMobileSdkRelease")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Platform": $platform, "ReleaseVersion": $release_version} | compact
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

# Returns the IAM policy that is attached to the specified rule group. You must be the owner of the rule group to perform this operation.
#
# POST /
# operationId: GetPermissionPolicy
export def "get-permission-policy" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the rule group for which you want to get the policy.
]: any -> record<Policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetPermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Retrieves the keys that are currently blocked by a rate-based rule instance. The maximum number of managed keys that can be blocked for a single rate-based rule instance is 10,000. If more than 10,000 addresses exceed the rate limit, those with the highest rates are blocked. For a rate-based rule that you've defined inside a rule group, provide the name of the rule group reference statement in your request, in addition to the rate-based rule name and the web ACL name. WAF monitors web requests and manages keys independently for each unique combination of web ACL, optional rule group, and rate-based rule. For example, if you define a rate-based rule inside a rule group, and then use the rule group in a web ACL, WAF monitors web requests and manages keys for that web ACL, rule group reference statement, and rate-based rule instance. If you use the same rule group in a second web ACL, WAF monitors web requests and manages keys for this second usage completely independent of your first.
#
# POST /
# operationId: GetRateBasedStatementManagedKeys
export def "get-rate-based-statement-managed-keys" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  web_acl_name: string # The name of the web ACL. You cannot change the name of a web ACL after you create it.
  web_acl_id: string # The unique identifier for the web ACL. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  --rule-group-rule-name: string # The name of the rule group reference statement in your web ACL. This is required only when you have the rate-based rule nested inside a rule group.
  rule_name: string # The name of the rate-based rule to get the keys for. If you have the rule defined inside a rule group that you're using in your web ACL, also provide the name of the rule group reference statement in the request parameter RuleGroupRuleName.
]: any -> record<ManagedKeysIPV4: record<IPAddressVersion: string, Addresses: list<string>>, ManagedKeysIPV6: record<IPAddressVersion: string, Addresses: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetRateBasedStatementManagedKeys")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "WebACLName": $web_acl_name, "WebACLId": $web_acl_id, "RuleGroupRuleName": $rule_group_rule_name, "RuleName": $rule_name} | compact
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

# Retrieves the specified RegexPatternSet.
#
# POST /
# operationId: GetRegexPatternSet
export def "get-regex-pattern-set" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  name: string # The name of the set. You cannot change the name after you create the set.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
]: any -> record<RegexPatternSet: record<Name: string, Id: string, ARN: string, Description: string, RegularExpressionList: list<record>>, LockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id} | compact
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

# Retrieves the specified RuleGroup.
#
# POST /
# operationId: GetRuleGroup
export def "get-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --name: string # The name of the rule group. You cannot change the name of a rule group after you create it.
  --scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --id: string # A unique identifier for the rule group. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  --arn: string # The Amazon Resource Name (ARN) of the entity.
]: any -> record<RuleGroup: record<Name: string, Id: string, Capacity: int, ARN: string, Description: string, Rules: list<record>, VisibilityConfig: record<SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string>, LabelNamespace: string, CustomResponseBodies: record, AvailableLabels: list<record>, ConsumedLabels: list<record>>, LockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "ARN": $arn} | compact
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

# Gets detailed information about a specified number of requests--a sample--that WAF randomly selects from among the first 5,000 requests that your Amazon Web Services resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours. GetSampledRequests returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, GetSampledRequests returns an updated time range. This new time range indicates the actual period during which WAF selected the requests in the sample.
#
# POST /
# operationId: GetSampledRequests
# --TimeWindow shape: {StartTime: string, EndTime: string}
export def "get-sampled-requests" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  web_acl_arn: string # The Amazon resource name (ARN) of the WebACL for which you want a sample of requests.
  rule_metric_name: string # The metric name assigned to the Rule or RuleGroup dimension for which you want a sample of requests.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  time_window: record # In a GetSampledRequests request, the StartTime and EndTime objects specify the time range for which you want WAF to return a sample of web requests. You must specify the times in Coordinated Universal Time (UTC) format. UTC format includes the special designator, Z. For example, "2016-09-27T14:50Z". You can specify any time range in the previous three hours. In a GetSampledRequests response, the StartTime and EndTime objects specify the time range for which WAF actually returned a sample of web requests. WAF gets the specified number of requests from among the first 5,000 requests that your Amazon Web Services resource receives during the specified time period. If your resource receives more than 5,000 requests during that period, WAF stops sampling after the 5,000th request. In that case, EndTime is the time that WAF received the 5,000th request. — shape: {StartTime: string, EndTime: string}
  max_items: int # The number of requests that you want WAF to return from among the first 5,000 requests that your Amazon Web Services resource received during the time range. If your resource received fewer requests than the value of MaxItems, GetSampledRequests returns information about all of them.
]: any -> record<SampledRequests: table<Request: record, Weight: int, Timestamp: string, Action: string, RuleNameWithinRuleGroup: string, RequestHeadersInserted: list, ResponseCodeSent: int, Labels: list, CaptchaResponse: record, ChallengeResponse: record, OverriddenAction: string>, PopulationSize: int, TimeWindow: record<StartTime: string, EndTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetSampledRequests")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebAclArn": $web_acl_arn, "RuleMetricName": $rule_metric_name, "Scope": $scope, "TimeWindow": $time_window, "MaxItems": $max_items} | compact
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

# Retrieves the specified WebACL.
#
# POST /
# operationId: GetWebACL
export def "get-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  name: string # The name of the web ACL. You cannot change the name of a web ACL after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # The unique identifier for the web ACL. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
]: any -> record<WebACL: record<Name: string, Id: string, ARN: string, DefaultAction: record<Block: record, Allow: record>, Description: string, Rules: list<record>, VisibilityConfig: record<SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string>, Capacity: int, PreProcessFirewallManagerRuleGroups: list<record>, PostProcessFirewallManagerRuleGroups: list<record>, ManagedByFirewallManager: bool, LabelNamespace: string, CustomResponseBodies: record, CaptchaConfig: record<ImmunityTimeProperty: record>, ChallengeConfig: record<ImmunityTimeProperty: record>, TokenDomains: list<string>, AssociationConfig: record<RequestBody: record>>, LockToken: string, ApplicationIntegrationURL: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id} | compact
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

# Retrieves the WebACL for the specified resource.
#
# POST /
# operationId: GetWebACLForResource
export def "get-web-acl-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource whose web ACL you want to retrieve. The ARN must be in one of the following formats: For an Application Load Balancer: arn:partition:elasticloadbalancing:region:account-id:loadbalancer/app/load-balancer-name/load-balancer-id For an Amazon API Gateway REST API: arn:partition:apigateway:region::/restapis/api-id/stages/stage-name For an AppSync GraphQL API: arn:partition:appsync:region:account-id:apis/GraphQLApiId For an Amazon Cognito user pool: arn:partition:cognito-idp:region:account-id:userpool/user-pool-id For an App Runner service: arn:partition:apprunner:region:account-id:service/apprunner-service-name/apprunner-service-id
]: any -> record<WebACL: record<Name: string, Id: string, ARN: string, DefaultAction: record<Block: record, Allow: record>, Description: string, Rules: list<record>, VisibilityConfig: record<SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string>, Capacity: int, PreProcessFirewallManagerRuleGroups: list<record>, PostProcessFirewallManagerRuleGroups: list<record>, ManagedByFirewallManager: bool, LabelNamespace: string, CustomResponseBodies: record, CaptchaConfig: record<ImmunityTimeProperty: record>, ChallengeConfig: record<ImmunityTimeProperty: record>, TokenDomains: list<string>, AssociationConfig: record<RequestBody: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.GetWebACLForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# Retrieves a list of the API keys that you've defined for the specified scope.
#
# POST /
# operationId: ListAPIKeys
export def "list-api-keys" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, APIKeySummaries: table<TokenDomains: list, APIKey: string, CreationTimestamp: string, Version: int>, ApplicationIntegrationURL: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListAPIKeys")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Returns a list of the available versions for the specified managed rule group.
#
# POST /
# operationId: ListAvailableManagedRuleGroupVersions
export def "list-available-managed-rule-group-versions" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  vendor_name: string # The name of the managed rule group vendor. You use this, along with the rule group name, to identify the rule group.
  name: string # The name of the managed rule group. You use this, along with the vendor name, to identify the rule group.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, Versions: table<Name: string, LastUpdateTimestamp: string>, CurrentDefaultVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListAvailableManagedRuleGroupVersions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VendorName": $vendor_name, "Name": $name, "Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves an array of managed rule groups that are available for you to use. This list includes all Amazon Web Services Managed Rules rule groups and all of the Amazon Web Services Marketplace managed rule groups that you're subscribed to.
#
# POST /
# operationId: ListAvailableManagedRuleGroups
export def "list-available-managed-rule-groups" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, ManagedRuleGroups: table<VendorName: string, Name: string, VersioningSupported: bool, Description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListAvailableManagedRuleGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves an array of IPSetSummary objects for the IP sets that you manage.
#
# POST /
# operationId: ListIPSets
export def "list-ip-sets" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, IPSets: table<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListIPSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves an array of your LoggingConfiguration objects.
#
# POST /
# operationId: ListLoggingConfigurations
export def "list-logging-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<LoggingConfigurations: table<ResourceArn: string, LogDestinationConfigs: list, RedactedFields: list, ManagedByFirewallManager: bool, LoggingFilter: record>, NextMarker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListLoggingConfigurations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves the managed rule sets that you own. This is intended for use only by vendors of managed rule sets. Vendors are Amazon Web Services and Amazon Web Services Marketplace sellers. Vendors, you can use the managed rule set APIs to provide controlled rollout of your versioned managed rule group offerings for your customers. The APIs are ListManagedRuleSets, GetManagedRuleSet, PutManagedRuleSetVersions, and UpdateManagedRuleSetVersionExpiryDate.
#
# POST /
# operationId: ListManagedRuleSets
export def "list-managed-rule-sets" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, ManagedRuleSets: table<Name: string, Id: string, Description: string, LockToken: string, ARN: string, LabelNamespace: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListManagedRuleSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves a list of the available releases for the mobile SDK and the specified device platform. The mobile SDK is not generally available. Customers who have access to the mobile SDK can use it to establish and manage WAF tokens for use in HTTP(S) requests from a mobile device to WAF. For more information, see WAF client application integration (https://docs.aws.amazon.com/waf/latest/developerguide/waf-application-integration.html) in the WAF Developer Guide.
#
# POST /
# operationId: ListMobileSdkReleases
export def "list-mobile-sdk-releases" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  platform: string@platform-completer # The device platform to retrieve the list for.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<ReleaseSummaries: table<ReleaseVersion: string, Timestamp: string>, NextMarker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListMobileSdkReleases")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Platform": $platform, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves an array of RegexPatternSetSummary objects for the regex pattern sets that you manage.
#
# POST /
# operationId: ListRegexPatternSets
export def "list-regex-pattern-sets" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, RegexPatternSets: table<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListRegexPatternSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves an array of the Amazon Resource Names (ARNs) for the regional resources that are associated with the specified web ACL. If you want the list of Amazon CloudFront resources, use the CloudFront call ListDistributionsByWebACLId.
#
# POST /
# operationId: ListResourcesForWebACL
export def "list-resources-for-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  web_acl_arn: string # The Amazon Resource Name (ARN) of the web ACL.
  --resource-type: string@resource-type-completer # Used for web ACLs that are scoped for regional applications. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. If you don't provide a resource type, the call uses the resource type APPLICATION_LOAD_BALANCER. Default: APPLICATION_LOAD_BALANCER
]: any -> record<ResourceArns: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListResourcesForWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLArn": $web_acl_arn, "ResourceType": $resource_type} | compact
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

# Retrieves an array of RuleGroupSummary objects for the rule groups that you manage.
#
# POST /
# operationId: ListRuleGroups
export def "list-rule-groups" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, RuleGroups: table<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListRuleGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Retrieves the TagInfoForResource for the specified resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each Amazon Web Services resource, up to 50 tags for a resource. You can tag the Amazon Web Services resources that you manage through WAF: web ACLs, rule groups, IP sets, and regex pattern sets. You can't manage or view tags through the WAF console.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
]: any -> record<NextMarker: string, TagInfoForResource: record<ResourceARN: string, TagList: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit, "ResourceARN": $resource_arn} | compact
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

# Retrieves an array of WebACLSummary objects for the web ACLs that you manage.
#
# POST /
# operationId: ListWebACLs
export def "list-web-ac-ls" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  --next-marker: string # When you request a list of objects with a Limit setting, if the number of objects that are still available for retrieval exceeds the limit, WAF returns a NextMarker value in the response. To retrieve the next batch of objects, provide the marker from the prior call in your next request.
  --limit: int # The maximum number of objects that you want WAF to return for this request. If more objects are available, in the response, WAF provides a NextMarker value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<NextMarker: string, WebACLs: table<Name: string, Id: string, Description: string, LockToken: string, ARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.ListWebACLs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Scope": $scope, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# Enables the specified LoggingConfiguration, to start logging from a web ACL, according to the configuration provided. This operation completely replaces any mutable specifications that you already have for a logging configuration with the ones that you provide to this call. To modify an existing logging configuration, do the following: Retrieve it by calling GetLoggingConfiguration Update its settings as needed Provide the complete logging configuration specification to this call You can define one logging destination per web ACL. You can access information about the traffic that WAF inspects using the following steps: Create your logging destination. You can use an Amazon CloudWatch Logs log group, an Amazon Simple Storage Service (Amazon S3) bucket, or an Amazon Kinesis Data Firehose. The name that you give the destination must start with aws-waf-logs-. Depending on the type of destination, you might need to configure additional settings or permissions. For configuration requirements and pricing information for each destination type, see Logging web ACL traffic (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the WAF Developer Guide. Associate your logging destination to your web ACL using a PutLoggingConfiguration request. When you successfully enable logging using a PutLoggingConfiguration request, WAF creates an additional role or policy that is required to write logs to the logging destination. For an Amazon CloudWatch Logs log group, WAF creates a resource policy on the log group. For an Amazon S3 bucket, WAF creates a bucket policy. For an Amazon Kinesis Data Firehose, WAF creates a service-linked role. For additional information about web ACL logging, see Logging web ACL traffic information (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the WAF Developer Guide.
#
# POST /
# operationId: PutLoggingConfiguration
# --LoggingConfiguration shape: {ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields?: list, ManagedByFirewallManager?: bool, LoggingFilter?: record}
export def "put-logging-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  logging_configuration: record # Defines an association between logging destinations and a web ACL resource, for logging from WAF. As part of the association, you can specify parts of the standard logging fields to keep out of the logs and you can specify filters so that you log only a subset of the logging records. You can define one logging destination per web ACL. You can access information about the traffic that WAF inspects using the following steps: Create your logging destination. You can use an Amazon CloudWatch Logs log group, an Amazon Simple Storage Service (Amazon S3) bucket, or an Amazon Kinesis Data Firehose. The name that you give the destination must start with aws-waf-logs-. Depending on the type of destination, you might need to configure additional settings or permissions. For configuration requirements and pricing information for each destination type, see Logging web ACL traffic (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the WAF Developer Guide. Associate your logging destination to your web ACL using a PutLoggingConfiguration request. When you successfully enable logging using a PutLoggingConfiguration request, WAF creates an additional role or policy that is required to write logs to the logging destination. For an Amazon CloudWatch Logs log group, WAF creates a resource policy on the log group. For an Amazon S3 bucket, WAF creates a bucket policy. For an Amazon Kinesis Data Firehose, WAF creates a service-linked role. For additional information about web ACL logging, see Logging web ACL traffic information (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the WAF Developer Guide. — shape: {ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields?: list, ManagedByFirewallManager?: bool, LoggingFilter?: record}
]: any -> record<LoggingConfiguration: record<ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields: list<record>, ManagedByFirewallManager: bool, LoggingFilter: record<Filters: list, DefaultBehavior: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.PutLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LoggingConfiguration": $logging_configuration} | compact
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

# Defines the versions of your managed rule set that you are offering to the customers. Customers see your offerings as managed rule groups with versioning. This is intended for use only by vendors of managed rule sets. Vendors are Amazon Web Services and Amazon Web Services Marketplace sellers. Vendors, you can use the managed rule set APIs to provide controlled rollout of your versioned managed rule group offerings for your customers. The APIs are ListManagedRuleSets, GetManagedRuleSet, PutManagedRuleSetVersions, and UpdateManagedRuleSetVersionExpiryDate. Customers retrieve their managed rule group list by calling ListAvailableManagedRuleGroups. The name that you provide here for your managed rule set is the name the customer sees for the corresponding managed rule group. Customers can retrieve the available versions for a managed rule group by calling ListAvailableManagedRuleGroupVersions. You provide a rule group specification for each version. For each managed rule set, you must specify a version that you recommend using. To initiate the expiration of a managed rule group version, use UpdateManagedRuleSetVersionExpiryDate.
#
# POST /
# operationId: PutManagedRuleSetVersions
export def "put-managed-rule-set-versions" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  name: string # The name of the managed rule set. You use this, along with the rule set ID, to identify the rule set. This name is assigned to the corresponding managed rule group, which your customers can access and use.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the managed rule set. The ID is returned in the responses to commands like list. You provide it to operations like get and update.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
  --recommended-version: string # The version of the named managed rule group that you'd like your customers to choose, from among your version offerings.
  --versions-to-publish: record # The versions of the named managed rule group that you want to offer to your customers.
]: any -> record<NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.PutManagedRuleSetVersions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token, "RecommendedVersion": $recommended_version, "VersionsToPublish": $versions_to_publish} | compact
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

# Attaches an IAM policy to the specified resource. Use this to share a rule group across accounts. You must be the owner of the rule group to perform this operation. This action is subject to the following restrictions: You can attach only one policy with each PutPermissionPolicy request. The ARN in the request must be a valid WAF RuleGroup ARN and the rule group must exist in the same Region. The user making the request must be the owner of the rule group.
#
# POST /
# operationId: PutPermissionPolicy
export def "put-permission-policy" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the RuleGroup to which you want to attach the policy.
  policy: string # The policy to attach to the specified rule group. The policy specifications must conform to the following: The policy must be composed using IAM Policy version 2012-10-17. The policy must include specifications for Effect, Action, and Principal. Effect must specify Allow. Action must specify wafv2:CreateWebACL, wafv2:UpdateWebACL, and wafv2:PutFirewallManagerRuleGroups and may optionally specify wafv2:GetRuleGroup. WAF rejects any extra actions or wildcard actions in the policy. The policy must not include a Resource parameter. For more information, see IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.PutPermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
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

# Associates tags with the specified Amazon Web Services resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each Amazon Web Services resource, up to 50 tags for a resource. You can tag the Amazon Web Services resources that you manage through WAF: web ACLs, rule groups, IP sets, and regex pattern sets. You can't manage or view tags through the WAF console.
#
# POST /
# operationId: TagResource
# --Tags item shape: {Key: string, Value: string}
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tags: list # An array of key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
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

# Disassociates tags from an Amazon Web Services resource. Tags are key:value pairs that you can associate with Amazon Web Services resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each Amazon Web Services resource.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tag_keys: list<string> # An array of keys identifying the tags to disassociate from the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
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

# Updates the specified IPSet. This operation completely replaces the mutable specifications that you already have for the IP set with the ones that you provide to this call. To modify an IP set, do the following: Retrieve it by calling GetIPSet Update its settings as needed Provide the complete IP set specification to this call When you make changes to web ACLs or web ACL components, like rules and rule groups, WAF propagates the changes everywhere that the web ACL and its components are stored and used. Your changes are applied within seconds, but there might be a brief period of inconsistency when the changes have arrived in some places and not in others. So, for example, if you change a rule action setting, the action might be the old action in one area and the new action in another area. Or if you add an IP address to an IP set used in a blocking rule, the new address might briefly be blocked in one area while still allowed in another. This temporary inconsistency can occur when you first associate a web ACL with an Amazon Web Services resource and when you change a web ACL that is already associated with a resource. Generally, any inconsistencies of this type last only a few seconds.
#
# POST /
# operationId: UpdateIPSet
export def "update-ip-set" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  name: string # The name of the IP set. You cannot change the name of an IPSet after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  --description: string # A description of the IP set that helps with identification.
  addresses: list<string> # Contains an array of strings that specifies zero or more IP addresses or blocks of IP addresses. All addresses must be specified using Classless Inter-Domain Routing (CIDR) notation. WAF supports all IPv4 and IPv6 CIDR ranges except for /0. Example address strings: To configure WAF to allow, block, or count requests that originated from the IP address 192.0.2.44, specify 192.0.2.44/32. To configure WAF to allow, block, or count requests that originated from IP addresses from 192.0.2.0 to 192.0.2.255, specify 192.0.2.0/24. To configure WAF to allow, block, or count requests that originated from the IP address 1111:0000:0000:0000:0000:0000:0000:0111, specify 1111:0000:0000:0000:0000:0000:0000:0111/128. To configure WAF to allow, block, or count requests that originated from IP addresses 1111:0000:0000:0000:0000:0000:0000:0000 to 1111:0000:0000:0000:ffff:ffff:ffff:ffff, specify 1111:0000:0000:0000:0000:0000:0000:0000/64. For more information about CIDR notation, see the Wikipedia entry Classless Inter-Domain Routing (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). Example JSON Addresses specifications: Empty array: "Addresses": [] Array with one address: "Addresses": ["192.0.2.44/32"] Array with three addresses: "Addresses": ["192.0.2.44/32", "192.0.2.0/24", "192.0.0.0/16"] INVALID specification: "Addresses": [""] INVALID
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record<NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UpdateIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "Description": $description, "Addresses": $addresses, "LockToken": $lock_token} | compact
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

# Updates the expiration information for your managed rule set. Use this to initiate the expiration of a managed rule group version. After you initiate expiration for a version, WAF excludes it from the response to ListAvailableManagedRuleGroupVersions for the managed rule group. This is intended for use only by vendors of managed rule sets. Vendors are Amazon Web Services and Amazon Web Services Marketplace sellers. Vendors, you can use the managed rule set APIs to provide controlled rollout of your versioned managed rule group offerings for your customers. The APIs are ListManagedRuleSets, GetManagedRuleSet, PutManagedRuleSetVersions, and UpdateManagedRuleSetVersionExpiryDate.
#
# POST /
# operationId: UpdateManagedRuleSetVersionExpiryDate
export def "update-managed-rule-set-version-expiry-date" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  name: string # The name of the managed rule set. You use this, along with the rule set ID, to identify the rule set. This name is assigned to the corresponding managed rule group, which your customers can access and use.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the managed rule set. The ID is returned in the responses to commands like list. You provide it to operations like get and update.
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
  version_to_expire: string # The version that you want to remove from your list of offerings for the named managed rule group.
  expiry_timestamp: string # The time that you want the version to expire. Times are in Coordinated Universal Time (UTC) format. UTC format includes the special designator, Z. For example, "2016-09-27T14:50Z". (format: date-time)
]: any -> record<ExpiringVersion: string, ExpiryTimestamp: string, NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UpdateManagedRuleSetVersionExpiryDate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "LockToken": $lock_token, "VersionToExpire": $version_to_expire, "ExpiryTimestamp": $expiry_timestamp} | compact
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

# Updates the specified RegexPatternSet. This operation completely replaces the mutable specifications that you already have for the regex pattern set with the ones that you provide to this call. To modify a regex pattern set, do the following: Retrieve it by calling GetRegexPatternSet Update its settings as needed Provide the complete regex pattern set specification to this call When you make changes to web ACLs or web ACL components, like rules and rule groups, WAF propagates the changes everywhere that the web ACL and its components are stored and used. Your changes are applied within seconds, but there might be a brief period of inconsistency when the changes have arrived in some places and not in others. So, for example, if you change a rule action setting, the action might be the old action in one area and the new action in another area. Or if you add an IP address to an IP set used in a blocking rule, the new address might briefly be blocked in one area while still allowed in another. This temporary inconsistency can occur when you first associate a web ACL with an Amazon Web Services resource and when you change a web ACL that is already associated with a resource. Generally, any inconsistencies of this type last only a few seconds.
#
# POST /
# operationId: UpdateRegexPatternSet
# --RegularExpressionList item shape: {RegexString?: string}
export def "update-regex-pattern-set" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  name: string # The name of the set. You cannot change the name after you create the set.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the set. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  --description: string # A description of the set that helps with identification.
  regular_expression_list: list # item shape: {RegexString?: string}
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
]: any -> record<NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UpdateRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "Description": $description, "RegularExpressionList": $regular_expression_list, "LockToken": $lock_token} | compact
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

# Updates the specified RuleGroup. This operation completely replaces the mutable specifications that you already have for the rule group with the ones that you provide to this call. To modify a rule group, do the following: Retrieve it by calling GetRuleGroup Update its settings as needed Provide the complete rule group specification to this call When you make changes to web ACLs or web ACL components, like rules and rule groups, WAF propagates the changes everywhere that the web ACL and its components are stored and used. Your changes are applied within seconds, but there might be a brief period of inconsistency when the changes have arrived in some places and not in others. So, for example, if you change a rule action setting, the action might be the old action in one area and the new action in another area. Or if you add an IP address to an IP set used in a blocking rule, the new address might briefly be blocked in one area while still allowed in another. This temporary inconsistency can occur when you first associate a web ACL with an Amazon Web Services resource and when you change a web ACL that is already associated with a resource. Generally, any inconsistencies of this type last only a few seconds. A rule group defines a collection of rules to inspect and control web requests that you can use in a WebACL. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements.
#
# POST /
# operationId: UpdateRuleGroup
# --Rules item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
# --VisibilityConfig shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
export def "update-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  name: string # The name of the rule group. You cannot change the name of a rule group after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # A unique identifier for the rule group. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  --description: string # A description of the rule group that helps with identification.
  --rules: list # The Rule statements used to identify the web requests that you want to allow, block, or count. Each rule includes one top-level statement that WAF uses to identify matching web requests, and parameters that govern how WAF handles them. — item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
  visibility_config: record # Defines and enables Amazon CloudWatch metrics and web request sample collection. — shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
  --custom-response-bodies: record # A map of custom response keys and content bodies. When you create a rule with a block action, you can send a custom response to the web request. You define these for the rule group, and then use them in the rules that you define in the rule group. For information about customizing web requests and responses, see Customizing web requests and responses in WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-custom-request-response.html) in the WAF Developer Guide. For information about the limits on count and size for custom request and response settings, see WAF quotas (https://docs.aws.amazon.com/waf/latest/developerguide/limits.html) in the WAF Developer Guide.
]: any -> record<NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UpdateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "Description": $description, "Rules": $rules, "VisibilityConfig": $visibility_config, "LockToken": $lock_token, "CustomResponseBodies": $custom_response_bodies} | compact
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

# Updates the specified WebACL. While updating a web ACL, WAF provides continuous coverage to the resources that you have associated with the web ACL. This operation completely replaces the mutable specifications that you already have for the web ACL with the ones that you provide to this call. To modify a web ACL, do the following: Retrieve it by calling GetWebACL Update its settings as needed Provide the complete web ACL specification to this call When you make changes to web ACLs or web ACL components, like rules and rule groups, WAF propagates the changes everywhere that the web ACL and its components are stored and used. Your changes are applied within seconds, but there might be a brief period of inconsistency when the changes have arrived in some places and not in others. So, for example, if you change a rule action setting, the action might be the old action in one area and the new action in another area. Or if you add an IP address to an IP set used in a blocking rule, the new address might briefly be blocked in one area while still allowed in another. This temporary inconsistency can occur when you first associate a web ACL with an Amazon Web Services resource and when you change a web ACL that is already associated with a resource. Generally, any inconsistencies of this type last only a few seconds. A web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a web ACL can be a combination of the types Rule, RuleGroup, and managed rule group. You can associate a web ACL with one or more Amazon Web Services resources to protect. The resources can be an Amazon CloudFront distribution, an Amazon API Gateway REST API, an Application Load Balancer, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service.
#
# POST /
# operationId: UpdateWebACL
# --DefaultAction shape: {Block?: record, Allow?: record}
# --Rules item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
# --VisibilityConfig shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
# --CaptchaConfig shape: {ImmunityTimeProperty?: record}
# --ChallengeConfig shape: {ImmunityTimeProperty?: record}
# --AssociationConfig shape: {RequestBody?: record}
export def "update-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  name: string # The name of the web ACL. You cannot change the name of a web ACL after you create it.
  scope: string@scope-completer # Specifies whether this is for an Amazon CloudFront distribution or for a regional application. A regional application can be an Application Load Balancer (ALB), an Amazon API Gateway REST API, an AppSync GraphQL API, an Amazon Cognito user pool, or an App Runner service. To work with CloudFront, you must also specify the Region US East (N. Virginia) as follows: CLI - Specify the Region when you use the CloudFront scope: --scope=CLOUDFRONT --region=us-east-1. API and SDKs - For all calls, use the Region endpoint us-east-1.
  id: string # The unique identifier for the web ACL. This ID is returned in the responses to create and list commands. You provide it to operations like update and delete.
  default_action: record # In a WebACL, this is the action that you want WAF to perform when a web request doesn't match any of the rules in the WebACL. The default action must be a terminating action. — shape: {Block?: record, Allow?: record}
  --description: string # A description of the web ACL that helps with identification.
  --rules: list # The Rule statements used to identify the web requests that you want to allow, block, or count. Each rule includes one top-level statement that WAF uses to identify matching web requests, and parameters that govern how WAF handles them. — item shape: {Name: string, Priority: int, Statement: record, Action?: record, OverrideAction?: record, RuleLabels?: list, VisibilityConfig: record, CaptchaConfig?: record, ChallengeConfig?: record}
  visibility_config: record # Defines and enables Amazon CloudWatch metrics and web request sample collection. — shape: {SampledRequestsEnabled: bool, CloudWatchMetricsEnabled: bool, MetricName: string}
  lock_token: string # A token used for optimistic locking. WAF returns a token to your get and list requests, to mark the state of the entity at the time of the request. To make changes to the entity associated with the token, you provide the token to operations like update and delete. WAF uses the token to ensure that no changes have been made to the entity since you last retrieved it. If a change has been made, the update fails with a WAFOptimisticLockException. If this happens, perform another get, and use the new token returned by that operation.
  --custom-response-bodies: record # A map of custom response keys and content bodies. When you create a rule with a block action, you can send a custom response to the web request. You define these for the web ACL, and then use them in the rules and default actions that you define in the web ACL. For information about customizing web requests and responses, see Customizing web requests and responses in WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-custom-request-response.html) in the WAF Developer Guide. For information about the limits on count and size for custom request and response settings, see WAF quotas (https://docs.aws.amazon.com/waf/latest/developerguide/limits.html) in the WAF Developer Guide.
  --captcha-config: record # Specifies how WAF should handle CAPTCHA evaluations. This is available at the web ACL level and in each rule. — shape: {ImmunityTimeProperty?: record}
  --challenge-config: record # Specifies how WAF should handle Challenge evaluations. This is available at the web ACL level and in each rule. — shape: {ImmunityTimeProperty?: record}
  --token-domains: list<string> # Specifies the domains that WAF should accept in a web request token. This enables the use of tokens across multiple protected websites. When WAF provides a token, it uses the domain of the Amazon Web Services resource that the web ACL is protecting. If you don't specify a list of token domains, WAF accepts tokens only for the domain of the protected resource. With a token domain list, WAF accepts the resource's host domain plus all domains in the token domain list, including their prefixed subdomains. Example JSON: "TokenDomains": { "mywebsite.com", "myotherwebsite.com" } Public suffixes aren't allowed. For example, you can't use usa.gov or co.uk as token domains.
  --association-config: record # Specifies custom configurations for the associations between the web ACL and protected resources. Use this to customize the maximum size of the request body that your protected CloudFront distributions forward to WAF for inspection. The default is 16 KB (16,384 kilobytes). You are charged additional fees when your protected resources forward body sizes that are larger than the default. For more information, see WAF Pricing (http://aws.amazon.com/waf/pricing/). — shape: {RequestBody?: record}
]: any -> record<NextLockToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20190729.UpdateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Scope": $scope, "Id": $id, "DefaultAction": $default_action, "Description": $description, "Rules": $rules, "VisibilityConfig": $visibility_config, "LockToken": $lock_token, "CustomResponseBodies": $custom_response_bodies, "CaptchaConfig": $captcha_config, "ChallengeConfig": $challenge_config, "TokenDomains": $token_domains, "AssociationConfig": $association_config} | compact
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
