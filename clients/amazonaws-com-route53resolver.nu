# Auto-generated client for Amazon Route 53 Resolver v2018-04-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/route53resolver/2018-04-01/openapi.json
# Auth: --token flag or $env.AMAZON_ROUTE_53_RESOLVER_TOKEN

const BASE_URL = "http://route53resolver.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ROUTE_53_RESOLVER_TOKEN | default "" }
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

def base-url-completer [] { ["http://route53resolver.us-east-1.amazonaws.com" "http://route53resolver.us-east-2.amazonaws.com" "http://route53resolver.us-west-1.amazonaws.com" "http://route53resolver.us-west-2.amazonaws.com" "http://route53resolver.us-gov-west-1.amazonaws.com" "http://route53resolver.us-gov-east-1.amazonaws.com" "http://route53resolver.ca-central-1.amazonaws.com" "http://route53resolver.eu-north-1.amazonaws.com" "http://route53resolver.eu-west-1.amazonaws.com" "http://route53resolver.eu-west-2.amazonaws.com" "http://route53resolver.eu-west-3.amazonaws.com" "http://route53resolver.eu-central-1.amazonaws.com" "http://route53resolver.eu-south-1.amazonaws.com" "http://route53resolver.af-south-1.amazonaws.com" "http://route53resolver.ap-northeast-1.amazonaws.com" "http://route53resolver.ap-northeast-2.amazonaws.com" "http://route53resolver.ap-northeast-3.amazonaws.com" "http://route53resolver.ap-southeast-1.amazonaws.com" "http://route53resolver.ap-southeast-2.amazonaws.com" "http://route53resolver.ap-east-1.amazonaws.com" "http://route53resolver.ap-south-1.amazonaws.com" "http://route53resolver.sa-east-1.amazonaws.com" "http://route53resolver.me-south-1.amazonaws.com" "https://route53resolver.us-east-1.amazonaws.com" "https://route53resolver.us-east-2.amazonaws.com" "https://route53resolver.us-west-1.amazonaws.com" "https://route53resolver.us-west-2.amazonaws.com" "https://route53resolver.us-gov-west-1.amazonaws.com" "https://route53resolver.us-gov-east-1.amazonaws.com" "https://route53resolver.ca-central-1.amazonaws.com" "https://route53resolver.eu-north-1.amazonaws.com" "https://route53resolver.eu-west-1.amazonaws.com" "https://route53resolver.eu-west-2.amazonaws.com" "https://route53resolver.eu-west-3.amazonaws.com" "https://route53resolver.eu-central-1.amazonaws.com" "https://route53resolver.eu-south-1.amazonaws.com" "https://route53resolver.af-south-1.amazonaws.com" "https://route53resolver.ap-northeast-1.amazonaws.com" "https://route53resolver.ap-northeast-2.amazonaws.com" "https://route53resolver.ap-northeast-3.amazonaws.com" "https://route53resolver.ap-southeast-1.amazonaws.com" "https://route53resolver.ap-southeast-2.amazonaws.com" "https://route53resolver.ap-east-1.amazonaws.com" "https://route53resolver.ap-south-1.amazonaws.com" "https://route53resolver.sa-east-1.amazonaws.com" "https://route53resolver.me-south-1.amazonaws.com" "http://route53resolver.cn-north-1.amazonaws.com.cn" "http://route53resolver.cn-northwest-1.amazonaws.com.cn" "https://route53resolver.cn-north-1.amazonaws.com.cn" "https://route53resolver.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mutation-protection-completer [] { ["DISABLED" "ENABLED"] }
def x-amz-target-completer [] { ["Route53Resolver.AssociateFirewallRuleGroup"] }
def x-amz-target-completer-1 [] { ["Route53Resolver.AssociateResolverEndpointIpAddress"] }
def x-amz-target-completer-2 [] { ["Route53Resolver.AssociateResolverQueryLogConfig"] }
def x-amz-target-completer-3 [] { ["Route53Resolver.AssociateResolverRule"] }
def x-amz-target-completer-4 [] { ["Route53Resolver.CreateFirewallDomainList"] }
def action-completer [] { ["ALERT" "ALLOW" "BLOCK"] }
def block-response-completer [] { ["NODATA" "NXDOMAIN" "OVERRIDE"] }
def block-override-dns-type-completer [] { ["CNAME"] }
def x-amz-target-completer-5 [] { ["Route53Resolver.CreateFirewallRule"] }
def x-amz-target-completer-6 [] { ["Route53Resolver.CreateFirewallRuleGroup"] }
def direction-completer [] { ["INBOUND" "OUTBOUND"] }
def resolver-endpoint-type-completer [] { ["DUALSTACK" "IPV4" "IPV6"] }
def x-amz-target-completer-7 [] { ["Route53Resolver.CreateResolverEndpoint"] }
def x-amz-target-completer-8 [] { ["Route53Resolver.CreateResolverQueryLogConfig"] }
def rule-type-completer [] { ["FORWARD" "RECURSIVE" "SYSTEM"] }
def x-amz-target-completer-9 [] { ["Route53Resolver.CreateResolverRule"] }
def x-amz-target-completer-10 [] { ["Route53Resolver.DeleteFirewallDomainList"] }
def x-amz-target-completer-11 [] { ["Route53Resolver.DeleteFirewallRule"] }
def x-amz-target-completer-12 [] { ["Route53Resolver.DeleteFirewallRuleGroup"] }
def x-amz-target-completer-13 [] { ["Route53Resolver.DeleteResolverEndpoint"] }
def x-amz-target-completer-14 [] { ["Route53Resolver.DeleteResolverQueryLogConfig"] }
def x-amz-target-completer-15 [] { ["Route53Resolver.DeleteResolverRule"] }
def x-amz-target-completer-16 [] { ["Route53Resolver.DisassociateFirewallRuleGroup"] }
def x-amz-target-completer-17 [] { ["Route53Resolver.DisassociateResolverEndpointIpAddress"] }
def x-amz-target-completer-18 [] { ["Route53Resolver.DisassociateResolverQueryLogConfig"] }
def x-amz-target-completer-19 [] { ["Route53Resolver.DisassociateResolverRule"] }
def x-amz-target-completer-20 [] { ["Route53Resolver.GetFirewallConfig"] }
def x-amz-target-completer-21 [] { ["Route53Resolver.GetFirewallDomainList"] }
def x-amz-target-completer-22 [] { ["Route53Resolver.GetFirewallRuleGroup"] }
def x-amz-target-completer-23 [] { ["Route53Resolver.GetFirewallRuleGroupAssociation"] }
def x-amz-target-completer-24 [] { ["Route53Resolver.GetFirewallRuleGroupPolicy"] }
def x-amz-target-completer-25 [] { ["Route53Resolver.GetResolverConfig"] }
def x-amz-target-completer-26 [] { ["Route53Resolver.GetResolverDnssecConfig"] }
def x-amz-target-completer-27 [] { ["Route53Resolver.GetResolverEndpoint"] }
def x-amz-target-completer-28 [] { ["Route53Resolver.GetResolverQueryLogConfig"] }
def x-amz-target-completer-29 [] { ["Route53Resolver.GetResolverQueryLogConfigAssociation"] }
def x-amz-target-completer-30 [] { ["Route53Resolver.GetResolverQueryLogConfigPolicy"] }
def x-amz-target-completer-31 [] { ["Route53Resolver.GetResolverRule"] }
def x-amz-target-completer-32 [] { ["Route53Resolver.GetResolverRuleAssociation"] }
def x-amz-target-completer-33 [] { ["Route53Resolver.GetResolverRulePolicy"] }
def operation-completer [] { ["REPLACE"] }
def x-amz-target-completer-34 [] { ["Route53Resolver.ImportFirewallDomains"] }
def x-amz-target-completer-35 [] { ["Route53Resolver.ListFirewallConfigs"] }
def x-amz-target-completer-36 [] { ["Route53Resolver.ListFirewallDomainLists"] }
def x-amz-target-completer-37 [] { ["Route53Resolver.ListFirewallDomains"] }
def status-completer [] { ["COMPLETE" "DELETING" "UPDATING"] }
def x-amz-target-completer-38 [] { ["Route53Resolver.ListFirewallRuleGroupAssociations"] }
def x-amz-target-completer-39 [] { ["Route53Resolver.ListFirewallRuleGroups"] }
def x-amz-target-completer-40 [] { ["Route53Resolver.ListFirewallRules"] }
def x-amz-target-completer-41 [] { ["Route53Resolver.ListResolverConfigs"] }
def x-amz-target-completer-42 [] { ["Route53Resolver.ListResolverDnssecConfigs"] }
def x-amz-target-completer-43 [] { ["Route53Resolver.ListResolverEndpointIpAddresses"] }
def x-amz-target-completer-44 [] { ["Route53Resolver.ListResolverEndpoints"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-45 [] { ["Route53Resolver.ListResolverQueryLogConfigAssociations"] }
def x-amz-target-completer-46 [] { ["Route53Resolver.ListResolverQueryLogConfigs"] }
def x-amz-target-completer-47 [] { ["Route53Resolver.ListResolverRuleAssociations"] }
def x-amz-target-completer-48 [] { ["Route53Resolver.ListResolverRules"] }
def x-amz-target-completer-49 [] { ["Route53Resolver.ListTagsForResource"] }
def x-amz-target-completer-50 [] { ["Route53Resolver.PutFirewallRuleGroupPolicy"] }
def x-amz-target-completer-51 [] { ["Route53Resolver.PutResolverQueryLogConfigPolicy"] }
def x-amz-target-completer-52 [] { ["Route53Resolver.PutResolverRulePolicy"] }
def x-amz-target-completer-53 [] { ["Route53Resolver.TagResource"] }
def x-amz-target-completer-54 [] { ["Route53Resolver.UntagResource"] }
def firewall-fail-open-completer [] { ["DISABLED" "ENABLED" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-55 [] { ["Route53Resolver.UpdateFirewallConfig"] }
def operation-completer-1 [] { ["ADD" "REMOVE" "REPLACE"] }
def x-amz-target-completer-56 [] { ["Route53Resolver.UpdateFirewallDomains"] }
def x-amz-target-completer-57 [] { ["Route53Resolver.UpdateFirewallRule"] }
def x-amz-target-completer-58 [] { ["Route53Resolver.UpdateFirewallRuleGroupAssociation"] }
def autodefined-reverse-flag-completer [] { ["DISABLE" "ENABLE" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-59 [] { ["Route53Resolver.UpdateResolverConfig"] }
def validation-completer [] { ["DISABLE" "ENABLE" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-60 [] { ["Route53Resolver.UpdateResolverDnssecConfig"] }
def x-amz-target-completer-61 [] { ["Route53Resolver.UpdateResolverEndpoint"] }
def x-amz-target-completer-62 [] { ["Route53Resolver.UpdateResolverRule"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "associate-firewall-rule-group" } } | get name | first)
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

# Associates a FirewallRuleGroup with a VPC, to provide DNS filtering for the VPC.
#
# POST /
# operationId: AssociateFirewallRuleGroup
# --Tags item shape: {Key: string, Value: string}
export def "associate-firewall-rule-group" [
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
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  firewall_rule_group_id: string # The unique identifier of the firewall rule group.
  vpc_id: string # The unique identifier of the VPC that you want to associate with the rule group.
  priority: int # The setting that determines the processing order of the rule group among the rule groups that you associate with the specified VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting. You must specify a unique priority for each rule group that you associate with a single VPC. To make it easier to insert rule groups later, leave space between the numbers, for example, use 101, 200, and so on. You can change the priority setting for a rule group association after you create it. The allowed values for Priority are between 100 and 9900.
  name: string # A name that lets you identify the association, to manage and use it.
  --mutation-protection: string@mutation-protection-completer # If enabled, this setting disallows modification or removal of the association, to help prevent against accidentally altering DNS firewall protections. When you create the association, the default setting is DISABLED.
  --tags: list # A list of the tag keys and values that you want to associate with the rule group association. — item shape: {Key: string, Value: string}
]: any -> record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.AssociateFirewallRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "FirewallRuleGroupId": $firewall_rule_group_id, "VpcId": $vpc_id, "Priority": $priority, "Name": $name, "MutationProtection": $mutation_protection, "Tags": $tags} | compact
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

# Adds IP addresses to an inbound or an outbound Resolver endpoint. If you want to add more than one IP address, submit one AssociateResolverEndpointIpAddress request for each IP address. To remove an IP address from an endpoint, see DisassociateResolverEndpointIpAddress (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverEndpointIpAddress.html).
#
# POST /
# operationId: AssociateResolverEndpointIpAddress
# --IpAddress shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
export def "associate-resolver-endpoint-ip-address" [
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
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to associate IP addresses with.
  ip_address: record # In an UpdateResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverEndpoint.html) request, information about an IP address to update. — shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.AssociateResolverEndpointIpAddress")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id, "IpAddress": $ip_address} | compact
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

# Associates an Amazon VPC with a specified query logging configuration. Route 53 Resolver logs DNS queries that originate in all of the Amazon VPCs that are associated with a specified query logging configuration. To associate more than one VPC with a configuration, submit one AssociateResolverQueryLogConfig request for each VPC. The VPCs that you associate with a query logging configuration must be in the same Region as the configuration. To remove a VPC from a query logging configuration, see DisassociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverQueryLogConfig.html).
#
# POST /
# operationId: AssociateResolverQueryLogConfig
export def "associate-resolver-query-log-config" [
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
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to associate a VPC with.
  resource_id: string # The ID of an Amazon VPC that you want this query logging configuration to log queries for. The VPCs and the query logging configuration must be in the same Region.
]: any -> record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.AssociateResolverQueryLogConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverQueryLogConfigId": $resolver_query_log_config_id, "ResourceId": $resource_id} | compact
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

# Associates a Resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see CreateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_CreateResolverRule.html).
#
# POST /
# operationId: AssociateResolverRule
export def "associate-resolver-rule" [
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
  resolver_rule_id: string # The ID of the Resolver rule that you want to associate with the VPC. To list the existing Resolver rules, use ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html).
  --name: string # A name for the association that you're creating between a Resolver rule and a VPC.
  vpc_id: string # The ID of the VPC that you want to associate the Resolver rule with.
]: any -> record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.AssociateResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverRuleId": $resolver_rule_id, "Name": $name, "VPCId": $vpc_id} | compact
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

# Creates an empty firewall domain list for use in DNS Firewall rules. You can populate the domains for the new list with a file, using ImportFirewallDomains, or with domain strings, using UpdateFirewallDomains.
#
# POST /
# operationId: CreateFirewallDomainList
# --Tags item shape: {Key: string, Value: string}
export def "create-firewall-domain-list" [
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
  creator_request_id: string # A unique string that identifies the request and that allows you to retry failed requests without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  name: string # A name that lets you identify the domain list to manage and use it.
  --tags: list # A list of the tag keys and values that you want to associate with the domain list. — item shape: {Key: string, Value: string}
]: any -> record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateFirewallDomainList")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "Name": $name, "Tags": $tags} | compact
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

# Creates a single DNS Firewall rule in the specified rule group, using the specified domain list.
#
# POST /
# operationId: CreateFirewallRule
export def "create-firewall-rule" [
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
  creator_request_id: string # A unique string that identifies the request and that allows you to retry failed requests without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  firewall_rule_group_id: string # The unique identifier of the firewall rule group where you want to create the rule.
  firewall_domain_list_id: string # The ID of the domain list that you want to use in the rule.
  priority: int # The setting that determines the processing order of the rule in the rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting. You must specify a unique priority for each rule in a rule group. To make it easier to insert rules later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for the rules in a rule group at any time.
  action: string@action-completer # The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request and send metrics and logs to Cloud Watch. BLOCK - Disallow the request. This option requires additional details in the rule's BlockResponse.
  --block-response: string@block-response-completer # The way that you want DNS Firewall to block the request, used with the rule action setting BLOCK. NODATA - Respond indicating that the query was successful, but no response is available for it. NXDOMAIN - Respond indicating that the domain name that's in the query doesn't exist. OVERRIDE - Provide a custom override in the response. This option requires custom handling details in the rule's BlockOverride* settings. This setting is required if the rule action setting is BLOCK.
  --block-override-domain: string # The custom DNS record to send back in response to the query. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  --block-override-dns-type: string@block-override-dns-type-completer # The DNS record's type. This determines the format of the record value that you provided in BlockOverrideDomain. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  --block-override-ttl: int # The recommended amount of time, in seconds, for the DNS resolver or web browser to cache the provided override record. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  name: string # A name that lets you identify the rule in the rule group.
]: any -> record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateFirewallRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "FirewallRuleGroupId": $firewall_rule_group_id, "FirewallDomainListId": $firewall_domain_list_id, "Priority": $priority, "Action": $action, "BlockResponse": $block_response, "BlockOverrideDomain": $block_override_domain, "BlockOverrideDnsType": $block_override_dns_type, "BlockOverrideTtl": $block_override_ttl, "Name": $name} | compact
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

# Creates an empty DNS Firewall rule group for filtering DNS network traffic in a VPC. You can add rules to the new rule group by calling CreateFirewallRule.
#
# POST /
# operationId: CreateFirewallRuleGroup
# --Tags item shape: {Key: string, Value: string}
export def "create-firewall-rule-group" [
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
  creator_request_id: string # A unique string defined by you to identify the request. This allows you to retry failed requests without the risk of running the operation twice. This can be any unique string, for example, a timestamp.
  name: string # A name that lets you identify the rule group, to manage and use it.
  --tags: list # A list of the tag keys and values that you want to associate with the rule group. — item shape: {Key: string, Value: string}
]: any -> record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateFirewallRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "Name": $name, "Tags": $tags} | compact
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

# Creates a Resolver endpoint. There are two types of Resolver endpoints, inbound and outbound: An inbound Resolver endpoint forwards DNS queries to the DNS service for a VPC from your network. An outbound Resolver endpoint forwards DNS queries from the DNS service for a VPC to your network.
#
# POST /
# operationId: CreateResolverEndpoint
# --IpAddresses item shape: {SubnetId: string, Ip?: string, Ipv6?: string}
# --Tags item shape: {Key: string, Value: string}
export def "create-resolver-endpoint" [
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
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --name: string # A friendly name that lets you easily find a configuration in the Resolver dashboard in the Route 53 console.
  security_group_ids: list<string> # The ID of one or more security groups that you want to use to control access to this VPC. The security group that you specify must include one or more inbound rules (for inbound Resolver endpoints) or outbound rules (for outbound Resolver endpoints). Inbound and outbound rules must allow TCP and UDP access. For inbound access, open port 53. For outbound access, open the port that you're using for DNS queries on your network.
  direction: string@direction-completer # Specify the applicable value: INBOUND: Resolver forwards DNS queries to the DNS service for a VPC from your network OUTBOUND: Resolver forwards DNS queries from the DNS service for a VPC to your network
  ip_addresses: list # The subnets and IP addresses in your VPC that DNS queries originate from (for outbound endpoints) or that you forward DNS queries to (for inbound endpoints). The subnet ID uniquely identifies a VPC. — item shape: {SubnetId: string, Ip?: string, Ipv6?: string}
  --tags: list # A list of the tag keys and values that you want to associate with the endpoint. — item shape: {Key: string, Value: string}
  --resolver-endpoint-type: string@resolver-endpoint-type-completer # For the endpoint type you can choose either IPv4, IPv6. or dual-stack. A dual-stack endpoint means that it will resolve via both IPv4 and IPv6. This endpoint type is applied to all IP addresses.
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateResolverEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "Name": $name, "SecurityGroupIds": $security_group_ids, "Direction": $direction, "IpAddresses": $ip_addresses, "Tags": $tags, "ResolverEndpointType": $resolver_endpoint_type} | compact
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

# Creates a Resolver query logging configuration, which defines where you want Resolver to save DNS query logs that originate in your VPCs. Resolver can log queries only for VPCs that are in the same Region as the query logging configuration. To specify which VPCs you want to log queries for, you use AssociateResolverQueryLogConfig. For more information, see AssociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverQueryLogConfig.html). You can optionally use Resource Access Manager (RAM) to share a query logging configuration with other Amazon Web Services accounts. The other accounts can then associate VPCs with the configuration. The query logs that Resolver creates for a configuration include all DNS queries that originate in all VPCs that are associated with the configuration.
#
# POST /
# operationId: CreateResolverQueryLogConfig
# --Tags item shape: {Key: string, Value: string}
export def "create-resolver-query-log-config" [
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
  name: string # The name that you want to give the query logging configuration.
  destination_arn: string # The ARN of the resource that you want Resolver to send query logs. You can send query logs to an S3 bucket, a CloudWatch Logs log group, or a Kinesis Data Firehose delivery stream. Examples of valid values include the following: S3 bucket: arn:aws:s3:::examplebucket You can optionally append a file prefix to the end of the ARN. arn:aws:s3:::examplebucket/development/ CloudWatch Logs log group: arn:aws:logs:us-west-1:123456789012:log-group:/mystack-testgroup-12ABC1AB12A1:* Kinesis Data Firehose delivery stream: arn:aws:kinesis:us-east-2:0123456789:stream/my_stream_name
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --tags: list # A list of the tag keys and values that you want to associate with the query logging configuration. — item shape: {Key: string, Value: string}
]: any -> record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateResolverQueryLogConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DestinationArn": $destination_arn, "CreatorRequestId": $creator_request_id, "Tags": $tags} | compact
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

# For DNS queries that originate in your VPCs, specifies which Resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
#
# POST /
# operationId: CreateResolverRule
# --TargetIps item shape: {Ip?: string, Port?: int, Ipv6?: string}
# --Tags item shape: {Key: string, Value: string}
export def "create-resolver-rule" [
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
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --name: string # A friendly name that lets you easily find a rule in the Resolver dashboard in the Route 53 console.
  rule_type: string@rule-type-completer # When you want to forward DNS queries for specified domain name to resolvers on your network, specify FORWARD. When you have a forwarding rule to forward DNS queries for a domain to your network and you want Resolver to process queries for a subdomain of that domain, specify SYSTEM. For example, to forward DNS queries for example.com to resolvers on your network, you create a rule and specify FORWARD for RuleType. To then have Resolver process queries for apex.example.com, you create a rule and specify SYSTEM for RuleType. Currently, only Resolver can create rules that have a value of RECURSIVE for RuleType.
  domain_name: string # DNS queries for this domain name are forwarded to the IP addresses that you specify in TargetIps. If a query matches multiple Resolver rules (example.com and www.example.com), outbound DNS queries are routed using the Resolver rule that contains the most specific domain name (www.example.com).
  --target-ips: list # The IPs that you want Resolver to forward DNS queries to. You can specify only IPv4 addresses. Separate IP addresses with a space. TargetIps is available only when the value of Rule type is FORWARD. — item shape: {Ip?: string, Port?: int, Ipv6?: string}
  --resolver-endpoint-id: string # The ID of the outbound Resolver endpoint that you want to use to route DNS queries to the IP addresses that you specify in TargetIps.
  --tags: list # A list of the tag keys and values that you want to associate with the endpoint. — item shape: {Key: string, Value: string}
]: any -> record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.CreateResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CreatorRequestId": $creator_request_id, "Name": $name, "RuleType": $rule_type, "DomainName": $domain_name, "TargetIps": $target_ips, "ResolverEndpointId": $resolver_endpoint_id, "Tags": $tags} | compact
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

# Deletes the specified domain list.
#
# POST /
# operationId: DeleteFirewallDomainList
export def "delete-firewall-domain-list" [
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
  firewall_domain_list_id: string # The ID of the domain list that you want to delete.
]: any -> record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteFirewallDomainList")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallDomainListId": $firewall_domain_list_id} | compact
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

# Deletes the specified firewall rule.
#
# POST /
# operationId: DeleteFirewallRule
export def "delete-firewall-rule" [
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
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to delete the rule from.
  firewall_domain_list_id: string # The ID of the domain list that's used in the rule.
]: any -> record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteFirewallRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id, "FirewallDomainListId": $firewall_domain_list_id} | compact
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

# Deletes the specified firewall rule group.
#
# POST /
# operationId: DeleteFirewallRuleGroup
export def "delete-firewall-rule-group" [
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
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to delete.
]: any -> record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteFirewallRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id} | compact
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

# Deletes a Resolver endpoint. The effect of deleting a Resolver endpoint depends on whether it's an inbound or an outbound Resolver endpoint: Inbound: DNS queries from your network are no longer routed to the DNS service for the specified VPC. Outbound: DNS queries from a VPC are no longer routed to your network.
#
# POST /
# operationId: DeleteResolverEndpoint
export def "delete-resolver-endpoint" [
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
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to delete.
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteResolverEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id} | compact
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

# Deletes a query logging configuration. When you delete a configuration, Resolver stops logging DNS queries for all of the Amazon VPCs that are associated with the configuration. This also applies if the query logging configuration is shared with other Amazon Web Services accounts, and the other accounts have associated VPCs with the shared configuration. Before you can delete a query logging configuration, you must first disassociate all VPCs from the configuration. See DisassociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverQueryLogConfig.html). If you used Resource Access Manager (RAM) to share a query logging configuration with other accounts, you must stop sharing the configuration before you can delete a configuration. The accounts that you shared the configuration with can first disassociate VPCs that they associated with the configuration, but that's not necessary. If you stop sharing the configuration, those VPCs are automatically disassociated from the configuration.
#
# POST /
# operationId: DeleteResolverQueryLogConfig
export def "delete-resolver-query-log-config" [
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
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to delete.
]: any -> record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteResolverQueryLogConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverQueryLogConfigId": $resolver_query_log_config_id} | compact
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

# Deletes a Resolver rule. Before you can delete a Resolver rule, you must disassociate it from all the VPCs that you associated the Resolver rule with. For more information, see DisassociateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverRule.html).
#
# POST /
# operationId: DeleteResolverRule
export def "delete-resolver-rule" [
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
  resolver_rule_id: string # The ID of the Resolver rule that you want to delete.
]: any -> record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DeleteResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverRuleId": $resolver_rule_id} | compact
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

# Disassociates a FirewallRuleGroup from a VPC, to remove DNS filtering from the VPC.
#
# POST /
# operationId: DisassociateFirewallRuleGroup
export def "disassociate-firewall-rule-group" [
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
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
]: any -> record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DisassociateFirewallRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupAssociationId": $firewall_rule_group_association_id} | compact
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

# Removes IP addresses from an inbound or an outbound Resolver endpoint. If you want to remove more than one IP address, submit one DisassociateResolverEndpointIpAddress request for each IP address. To add an IP address to an endpoint, see AssociateResolverEndpointIpAddress (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverEndpointIpAddress.html).
#
# POST /
# operationId: DisassociateResolverEndpointIpAddress
# --IpAddress shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
export def "disassociate-resolver-endpoint-ip-address" [
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
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to disassociate an IP address from.
  ip_address: record # In an UpdateResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverEndpoint.html) request, information about an IP address to update. — shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DisassociateResolverEndpointIpAddress")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id, "IpAddress": $ip_address} | compact
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

# Disassociates a VPC from a query logging configuration. Before you can delete a query logging configuration, you must first disassociate all VPCs from the configuration. If you used Resource Access Manager (RAM) to share a query logging configuration with other accounts, VPCs can be disassociated from the configuration in the following ways: The accounts that you shared the configuration with can disassociate VPCs from the configuration. You can stop sharing the configuration.
#
# POST /
# operationId: DisassociateResolverQueryLogConfig
export def "disassociate-resolver-query-log-config" [
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
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to disassociate a specified VPC from.
  resource_id: string # The ID of the Amazon VPC that you want to disassociate from a specified query logging configuration.
]: any -> record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DisassociateResolverQueryLogConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverQueryLogConfigId": $resolver_query_log_config_id, "ResourceId": $resource_id} | compact
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

# Removes the association between a specified Resolver rule and a specified VPC. If you disassociate a Resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the Resolver rule.
#
# POST /
# operationId: DisassociateResolverRule
export def "disassociate-resolver-rule" [
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
  vpc_id: string # The ID of the VPC that you want to disassociate the Resolver rule from.
  resolver_rule_id: string # The ID of the Resolver rule that you want to disassociate from the specified VPC.
]: any -> record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.DisassociateResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"VPCId": $vpc_id, "ResolverRuleId": $resolver_rule_id} | compact
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

# Retrieves the configuration of the firewall behavior provided by DNS Firewall for a single VPC from Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# operationId: GetFirewallConfig
export def "get-firewall-config" [
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
  resource_id: string # The ID of the VPC from Amazon VPC that the configuration is for.
]: any -> record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetFirewallConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id} | compact
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

# Retrieves the specified firewall domain list.
#
# POST /
# operationId: GetFirewallDomainList
export def "get-firewall-domain-list" [
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
  firewall_domain_list_id: string # The ID of the domain list.
]: any -> record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetFirewallDomainList")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallDomainListId": $firewall_domain_list_id} | compact
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

# Retrieves the specified firewall rule group.
#
# POST /
# operationId: GetFirewallRuleGroup
export def "get-firewall-rule-group" [
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
  firewall_rule_group_id: string # The unique identifier of the firewall rule group.
]: any -> record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetFirewallRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id} | compact
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

# Retrieves a firewall rule group association, which enables DNS filtering for a VPC with one rule group. A VPC can have more than one firewall rule group association, and a rule group can be associated with more than one VPC.
#
# POST /
# operationId: GetFirewallRuleGroupAssociation
export def "get-firewall-rule-group-association" [
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
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
]: any -> record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetFirewallRuleGroupAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupAssociationId": $firewall_rule_group_association_id} | compact
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

# Returns the Identity and Access Management (Amazon Web Services IAM) policy for sharing the specified rule group. You can use the policy to share the rule group using Resource Access Manager (RAM).
#
# POST /
# operationId: GetFirewallRuleGroupPolicy
export def "get-firewall-rule-group-policy" [
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
  arn: string # The ARN (Amazon Resource Name) for the rule group.
]: any -> record<FirewallRuleGroupPolicy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetFirewallRuleGroupPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn} | compact
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

# Retrieves the behavior configuration of Route 53 Resolver behavior for a single VPC from Amazon Virtual Private Cloud.
#
# POST /
# operationId: GetResolverConfig
export def "get-resolver-config" [
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
  resource_id: string # Resource ID of the Amazon VPC that you want to get information about.
]: any -> record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id} | compact
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

# Gets DNSSEC validation information for a specified resource.
#
# POST /
# operationId: GetResolverDnssecConfig
export def "get-resolver-dnssec-config" [
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
  resource_id: string # The ID of the virtual private cloud (VPC) for the DNSSEC validation status.
]: any -> record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverDnssecConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id} | compact
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

# Gets information about a specified Resolver endpoint, such as whether it's an inbound or an outbound Resolver endpoint, and the current status of the endpoint.
#
# POST /
# operationId: GetResolverEndpoint
export def "get-resolver-endpoint" [
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
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to get information about.
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id} | compact
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

# Gets information about a specified Resolver query logging configuration, such as the number of VPCs that the configuration is logging queries for and the location that logs are sent to.
#
# POST /
# operationId: GetResolverQueryLogConfig
export def "get-resolver-query-log-config" [
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
  resolver_query_log_config_id: string # The ID of the Resolver query logging configuration that you want to get information about.
]: any -> record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverQueryLogConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverQueryLogConfigId": $resolver_query_log_config_id} | compact
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

# Gets information about a specified association between a Resolver query logging configuration and an Amazon VPC. When you associate a VPC with a query logging configuration, Resolver logs DNS queries that originate in that VPC.
#
# POST /
# operationId: GetResolverQueryLogConfigAssociation
export def "get-resolver-query-log-config-association" [
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
  resolver_query_log_config_association_id: string # The ID of the Resolver query logging configuration association that you want to get information about.
]: any -> record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverQueryLogConfigAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverQueryLogConfigAssociationId": $resolver_query_log_config_association_id} | compact
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

# Gets information about a query logging policy. A query logging policy specifies the Resolver query logging operations and resources that you want to allow another Amazon Web Services account to be able to use.
#
# POST /
# operationId: GetResolverQueryLogConfigPolicy
export def "get-resolver-query-log-config-policy" [
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
  arn: string # The ARN of the query logging configuration that you want to get the query logging policy for.
]: any -> record<ResolverQueryLogConfigPolicy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverQueryLogConfigPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn} | compact
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

# Gets information about a specified Resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound Resolver endpoint that the rule is associated with.
#
# POST /
# operationId: GetResolverRule
export def "get-resolver-rule" [
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
  resolver_rule_id: string # The ID of the Resolver rule that you want to get information about.
]: any -> record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverRuleId": $resolver_rule_id} | compact
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

# Gets information about an association between a specified Resolver rule and a VPC. You associate a Resolver rule and a VPC using AssociateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverRule.html).
#
# POST /
# operationId: GetResolverRuleAssociation
export def "get-resolver-rule-association" [
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
  resolver_rule_association_id: string # The ID of the Resolver rule association that you want to get information about.
]: any -> record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverRuleAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverRuleAssociationId": $resolver_rule_association_id} | compact
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

# Gets information about the Resolver rule policy for a specified rule. A Resolver rule policy includes the rule that you want to share with another account, the account that you want to share the rule with, and the Resolver operations that you want to allow the account to use.
#
# POST /
# operationId: GetResolverRulePolicy
export def "get-resolver-rule-policy" [
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
  arn: string # The ID of the Resolver rule that you want to get the Resolver rule policy for.
]: any -> record<ResolverRulePolicy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.GetResolverRulePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn} | compact
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

# Imports domain names from a file into a domain list, for use in a DNS firewall rule group. Each domain specification in your domain list must satisfy the following requirements: It can optionally start with * (asterisk). With the exception of the optional starting asterisk, it must only contain the following characters: A-Z, a-z, 0-9, - (hyphen). It must be from 1-255 characters in length.
#
# POST /
# operationId: ImportFirewallDomains
export def "import-firewall-domains" [
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
  firewall_domain_list_id: string # The ID of the domain list that you want to modify with the import operation.
  operation: string@operation-completer # What you want DNS Firewall to do with the domains that are listed in the file. This must be set to REPLACE, which updates the domain list to exactly match the list in the file.
  domain_file_url: string # The fully qualified URL or URI of the file stored in Amazon Simple Storage Service (Amazon S3) that contains the list of domains to import. The file must be in an S3 bucket that's in the same Region as your DNS Firewall. The file must be a text file and must contain a single domain per line.
]: any -> record<Id: string, Name: string, Status: string, StatusMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ImportFirewallDomains")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallDomainListId": $firewall_domain_list_id, "Operation": $operation, "DomainFileUrl": $domain_file_url} | compact
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

# Retrieves the firewall configurations that you have defined. DNS Firewall uses the configurations to manage firewall behavior for your VPCs. A single call might return only a partial list of the configurations. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallConfigs
export def "list-firewall-configs" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, FirewallConfigs: table<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallConfigs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the firewall domain lists that you have defined. For each firewall domain list, you can retrieve the domains that are defined for a list by calling ListFirewallDomains. A single call to this list operation might return only a partial list of the domain lists. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallDomainLists
export def "list-firewall-domain-lists" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, FirewallDomainLists: table<Id: string, Arn: string, Name: string, CreatorRequestId: string, ManagedOwnerName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallDomainLists")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the domains that you have defined for the specified firewall domain list. A single call might return only a partial list of the domains. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallDomains
export def "list-firewall-domains" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  firewall_domain_list_id: string # The ID of the domain list whose domains you want to retrieve.
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, Domains: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallDomains")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FirewallDomainListId": $firewall_domain_list_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the firewall rule group associations that you have defined. Each association enables DNS filtering for a VPC with one rule group. A single call might return only a partial list of the associations. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallRuleGroupAssociations
export def "list-firewall-rule-group-associations" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  --firewall-rule-group-id: string # The unique identifier of the firewall rule group that you want to retrieve the associations for. Leave this blank to retrieve associations for any rule group.
  --vpc-id: string # The unique identifier of the VPC that you want to retrieve the associations for. Leave this blank to retrieve associations for any VPC.
  --priority: int # The setting that determines the processing order of the rule group among the rule groups that are associated with a single VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting.
  --status: string@status-completer # The association Status setting that you want DNS Firewall to filter on for the list. If you don't specify this, then DNS Firewall returns all associations, regardless of status.
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, FirewallRuleGroupAssociations: table<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallRuleGroupAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id, "VpcId": $vpc_id, "Priority": $priority, "Status": $status, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the minimal high-level information for the rule groups that you have defined. A single call might return only a partial list of the rule groups. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallRuleGroups
export def "list-firewall-rule-groups" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39 # required
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, FirewallRuleGroups: table<Id: string, Arn: string, Name: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallRuleGroups")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the firewall rules that you have defined for the specified firewall rule group. DNS Firewall uses the rules in a rule group to filter DNS network traffic for a VPC. A single call might return only a partial list of the rules. For information, see MaxResults.
#
# POST /
# operationId: ListFirewallRules
export def "list-firewall-rules" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to retrieve the rules for.
  --priority: int # Optional additional filter for the rules to retrieve. The setting that determines the processing order of the rules in a rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting.
  --action: string@action-completer # Optional additional filter for the rules to retrieve. The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request to go through but send an alert to the logs. BLOCK - Disallow the request. If this is specified, additional handling details are provided in the rule's BlockResponse setting.
  --max-results-body: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (body field)
  --next-token-body: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (body field)
]: any -> record<NextToken: string, FirewallRules: table<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListFirewallRules")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id, "Priority": $priority, "Action": $action, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the Resolver configurations that you have defined. Route 53 Resolver uses the configurations to manage DNS resolution behavior for your VPCs.
#
# POST /
# operationId: ListResolverConfigs
export def "list-resolver-configs" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  --max-results-body: int # The maximum number of Resolver configurations that you want to return in the response to a ListResolverConfigs request. If you don't specify a value for MaxResults, up to 100 Resolver configurations are returned. (body field)
  --next-token-body: string # (Optional) If the current Amazon Web Services account has more than MaxResults Resolver configurations, use NextToken to get the second and subsequent pages of results. For the first ListResolverConfigs request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. (body field)
]: any -> record<NextToken: string, ResolverConfigs: table<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverConfigs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the configurations for DNSSEC validation that are associated with the current Amazon Web Services account.
#
# POST /
# operationId: ListResolverDnssecConfigs
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-dnssec-configs" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  --max-results-body: int # Optional: An integer that specifies the maximum number of DNSSEC configuration results that you want Amazon Route 53 to return. If you don't specify a value for MaxResults, Route 53 returns up to 100 configuration per page. (body field)
  --next-token-body: string # (Optional) If the current Amazon Web Services account has more than MaxResults DNSSEC configurations, use NextToken to get the second and subsequent pages of results. For the first ListResolverDnssecConfigs request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. (body field)
  --filters: list # An optional specification to return a subset of objects. — item shape: {Name?: string, Values?: list<string>}
]: any -> record<NextToken: string, ResolverDnssecConfigs: table<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverDnssecConfigs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets the IP addresses for a specified Resolver endpoint.
#
# POST /
# operationId: ListResolverEndpointIpAddresses
export def "list-resolver-endpoint-ip-addresses" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to get IP addresses for.
  --max-results-body: int # The maximum number of IP addresses that you want to return in the response to a ListResolverEndpointIpAddresses request. If you don't specify a value for MaxResults, Resolver returns up to 100 IP addresses. (body field)
  --next-token-body: string # For the first ListResolverEndpointIpAddresses request, omit this value. If the specified Resolver endpoint has more than MaxResults IP addresses, you can submit another ListResolverEndpointIpAddresses request to get the next group of IP addresses. In the next request, specify the value of NextToken from the previous response. (body field)
]: any -> record<NextToken: string, MaxResults: int, IpAddresses: table<IpId: string, SubnetId: string, Ip: string, Ipv6: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverEndpointIpAddresses")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all the Resolver endpoints that were created using the current Amazon Web Services account.
#
# POST /
# operationId: ListResolverEndpoints
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-endpoints" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --max-results-body: int # The maximum number of Resolver endpoints that you want to return in the response to a ListResolverEndpoints request. If you don't specify a value for MaxResults, Resolver returns up to 100 Resolver endpoints. (body field)
  --next-token-body: string # For the first ListResolverEndpoints request, omit this value. If you have more than MaxResults Resolver endpoints, you can submit another ListResolverEndpoints request to get the next group of Resolver endpoints. In the next request, specify the value of NextToken from the previous response. (body field)
  --filters: list # An optional specification to return a subset of Resolver endpoints, such as all inbound Resolver endpoints. If you submit a second or subsequent ListResolverEndpoints request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> record<NextToken: string, MaxResults: int, ResolverEndpoints: table<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverEndpoints")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists information about associations between Amazon VPCs and query logging configurations.
#
# POST /
# operationId: ListResolverQueryLogConfigAssociations
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-query-log-config-associations" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  --max-results-body: int # The maximum number of query logging associations that you want to return in the response to a ListResolverQueryLogConfigAssociations request. If you don't specify a value for MaxResults, Resolver returns up to 100 query logging associations. (body field)
  --next-token-body: string # For the first ListResolverQueryLogConfigAssociations request, omit this value. If there are more than MaxResults query logging associations that match the values that you specify for Filters, you can submit another ListResolverQueryLogConfigAssociations request to get the next group of associations. In the next request, specify the value of NextToken from the previous response. (body field)
  --filters: list # An optional specification to return a subset of query logging associations. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
  --sort-by: string # The element that you want Resolver to sort query logging associations by. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same value for SortBy, if any, as in the previous request. Valid values include the following elements: CreationTime: The ID of the query logging association. Error: If the value of Status is FAILED, the value of Error indicates the cause: DESTINATION_NOT_FOUND: The specified destination (for example, an Amazon S3 bucket) was deleted. ACCESS_DENIED: Permissions don't allow sending logs to the destination. If Status is a value other than FAILED, ERROR is null. Id: The ID of the query logging association ResolverQueryLogConfigId: The ID of the query logging configuration ResourceId: The ID of the VPC that is associated with the query logging configuration Status: The current status of the configuration. Valid values include the following: CREATING: Resolver is creating an association between an Amazon VPC and a query logging configuration. CREATED: The association between an Amazon VPC and a query logging configuration was successfully created. Resolver is logging queries that originate in the specified VPC. DELETING: Resolver is deleting this query logging association. FAILED: Resolver either couldn't create or couldn't delete the query logging association. Here are two common causes: The specified destination (for example, an Amazon S3 bucket) was deleted. Permissions don't allow sending logs to the destination.
  --sort-order: string@sort-order-completer # If you specified a value for SortBy, the order that you want query logging associations to be listed in, ASCENDING or DESCENDING. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same value for SortOrder, if any, as in the previous request.
]: any -> record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigAssociations: table<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverQueryLogConfigAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists information about the specified query logging configurations. Each configuration defines where you want Resolver to save DNS query logs and specifies the VPCs that you want to log queries for.
#
# POST /
# operationId: ListResolverQueryLogConfigs
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-query-log-configs" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  --max-results-body: int # The maximum number of query logging configurations that you want to return in the response to a ListResolverQueryLogConfigs request. If you don't specify a value for MaxResults, Resolver returns up to 100 query logging configurations. (body field)
  --next-token-body: string # For the first ListResolverQueryLogConfigs request, omit this value. If there are more than MaxResults query logging configurations that match the values that you specify for Filters, you can submit another ListResolverQueryLogConfigs request to get the next group of configurations. In the next request, specify the value of NextToken from the previous response. (body field)
  --filters: list # An optional specification to return a subset of query logging configurations. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
  --sort-by: string # The element that you want Resolver to sort query logging configurations by. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same value for SortBy, if any, as in the previous request. Valid values include the following elements: Arn: The ARN of the query logging configuration AssociationCount: The number of VPCs that are associated with the specified configuration CreationTime: The date and time that Resolver returned when the configuration was created CreatorRequestId: The value that was specified for CreatorRequestId when the configuration was created DestinationArn: The location that logs are sent to Id: The ID of the configuration Name: The name of the configuration OwnerId: The Amazon Web Services account number of the account that created the configuration ShareStatus: Whether the configuration is shared with other Amazon Web Services accounts or shared with the current account by another Amazon Web Services account. Sharing is configured through Resource Access Manager (RAM). Status: The current status of the configuration. Valid values include the following: CREATING: Resolver is creating the query logging configuration. CREATED: The query logging configuration was successfully created. Resolver is logging queries that originate in the specified VPC. DELETING: Resolver is deleting this query logging configuration. FAILED: Resolver either couldn't create or couldn't delete the query logging configuration. Here are two common causes: The specified destination (for example, an Amazon S3 bucket) was deleted. Permissions don't allow sending logs to the destination.
  --sort-order: string@sort-order-completer # If you specified a value for SortBy, the order that you want query logging configurations to be listed in, ASCENDING or DESCENDING. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same value for SortOrder, if any, as in the previous request.
]: any -> record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigs: table<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverQueryLogConfigs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the associations that were created between Resolver rules and VPCs using the current Amazon Web Services account.
#
# POST /
# operationId: ListResolverRuleAssociations
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-rule-associations" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  --max-results-body: int # The maximum number of rule associations that you want to return in the response to a ListResolverRuleAssociations request. If you don't specify a value for MaxResults, Resolver returns up to 100 rule associations. (body field)
  --next-token-body: string # For the first ListResolverRuleAssociation request, omit this value. If you have more than MaxResults rule associations, you can submit another ListResolverRuleAssociation request to get the next group of rule associations. In the next request, specify the value of NextToken from the previous response. (body field)
  --filters: list # An optional specification to return a subset of Resolver rules, such as Resolver rules that are associated with the same VPC ID. If you submit a second or subsequent ListResolverRuleAssociations request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> record<NextToken: string, MaxResults: int, ResolverRuleAssociations: table<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverRuleAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the Resolver rules that were created using the current Amazon Web Services account.
#
# POST /
# operationId: ListResolverRules
# --Filters item shape: {Name?: string, Values?: list<string>}
export def "list-resolver-rules" [
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  --max-results-body: int # The maximum number of Resolver rules that you want to return in the response to a ListResolverRules request. If you don't specify a value for MaxResults, Resolver returns up to 100 Resolver rules. (body field)
  --next-token-body: string # For the first ListResolverRules request, omit this value. If you have more than MaxResults Resolver rules, you can submit another ListResolverRules request to get the next group of Resolver rules. In the next request, specify the value of NextToken from the previous response. (body field)
  --filters: list # An optional specification to return a subset of Resolver rules, such as all Resolver rules that are associated with the same Resolver endpoint. If you submit a second or subsequent ListResolverRules request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> record<NextToken: string, MaxResults: int, ResolverRules: table<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListResolverRules")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the tags that you associated with the specified resource.
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to list tags for.
  --max-results-body: int # The maximum number of tags that you want to return in the response to a ListTagsForResource request. If you don't specify a value for MaxResults, Resolver returns up to 100 tags. (body field)
  --next-token-body: string # For the first ListTagsForResource request, omit this value. If you have more than MaxResults tags, you can submit another ListTagsForResource request to get the next group of tags for the resource. In the next request, specify the value of NextToken from the previous response. (body field)
]: any -> record<Tags: table<Key: string, Value: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.ListTagsForResource")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Attaches an Identity and Access Management (Amazon Web Services IAM) policy for sharing the rule group. You can use the policy to share the rule group using Resource Access Manager (RAM).
#
# POST /
# operationId: PutFirewallRuleGroupPolicy
export def "put-firewall-rule-group-policy" [
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
  arn: string # The ARN (Amazon Resource Name) for the rule group that you want to share.
  firewall_rule_group_policy: string # The Identity and Access Management (Amazon Web Services IAM) policy to attach to the rule group.
]: any -> record<ReturnValue: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.PutFirewallRuleGroupPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn, "FirewallRuleGroupPolicy": $firewall_rule_group_policy} | compact
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

# Specifies an Amazon Web Services account that you want to share a query logging configuration with, the query logging configuration that you want to share, and the operations that you want the account to be able to perform on the configuration.
#
# POST /
# operationId: PutResolverQueryLogConfigPolicy
export def "put-resolver-query-log-config-policy" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  arn: string # The Amazon Resource Name (ARN) of the account that you want to share rules with.
  resolver_query_log_config_policy: string # An Identity and Access Management policy statement that lists the query logging configurations that you want to share with another Amazon Web Services account and the operations that you want the account to be able to perform. You can specify the following operations in the Actions section of the statement: route53resolver:AssociateResolverQueryLogConfig route53resolver:DisassociateResolverQueryLogConfig route53resolver:ListResolverQueryLogConfigAssociations route53resolver:ListResolverQueryLogConfigs In the Resource section of the statement, you specify the ARNs for the query logging configurations that you want to share with the account that you specified in Arn.
]: any -> record<ReturnValue: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.PutResolverQueryLogConfigPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn, "ResolverQueryLogConfigPolicy": $resolver_query_log_config_policy} | compact
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

# Specifies an Amazon Web Services rule that you want to share with another account, the account that you want to share the rule with, and the operations that you want the account to be able to perform on the rule.
#
# POST /
# operationId: PutResolverRulePolicy
export def "put-resolver-rule-policy" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  arn: string # The Amazon Resource Name (ARN) of the rule that you want to share with another account.
  resolver_rule_policy: string # An Identity and Access Management policy statement that lists the rules that you want to share with another Amazon Web Services account and the operations that you want the account to be able to perform. You can specify the following operations in the Action section of the statement: route53resolver:GetResolverRule route53resolver:AssociateResolverRule route53resolver:DisassociateResolverRule route53resolver:ListResolverRules route53resolver:ListResolverRuleAssociations In the Resource section of the statement, specify the ARN for the rule that you want to share with another account. Specify the same ARN that you specified in Arn.
]: any -> record<ReturnValue: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.PutResolverRulePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Arn": $arn, "ResolverRulePolicy": $resolver_rule_policy} | compact
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

# Adds one or more tags to a specified resource.
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to add tags to. To get the ARN for a resource, use the applicable Get or List command: GetResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverEndpoint.html) GetResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRule.html) GetResolverRuleAssociation (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRuleAssociation.html) ListResolverEndpoints (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverEndpoints.html) ListResolverRuleAssociations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRuleAssociations.html) ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html)
  tags: list # The tags that you want to add to the specified resource. — item shape: {Key: string, Value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
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

# Removes one or more tags from a specified resource.
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to remove tags from. To get the ARN for a resource, use the applicable Get or List command: GetResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverEndpoint.html) GetResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRule.html) GetResolverRuleAssociation (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRuleAssociation.html) ListResolverEndpoints (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverEndpoints.html) ListResolverRuleAssociations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRuleAssociations.html) ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html)
  tag_keys: list<string> # The tags that you want to remove to the specified resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
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

# Updates the configuration of the firewall behavior provided by DNS Firewall for a single VPC from Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# operationId: UpdateFirewallConfig
export def "update-firewall-config" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  resource_id: string # The ID of the VPC that the configuration is for.
  firewall_fail_open: string@firewall-fail-open-completer # Determines how Route 53 Resolver handles queries during failures, for example when all traffic that is sent to DNS Firewall fails to receive a reply. By default, fail open is disabled, which means the failure mode is closed. This approach favors security over availability. DNS Firewall blocks queries that it is unable to evaluate properly. If you enable this option, the failure mode is open. This approach favors availability over security. DNS Firewall allows queries to proceed if it is unable to properly evaluate them. This behavior is only enforced for VPCs that have at least one DNS Firewall rule group association.
]: any -> record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateFirewallConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "FirewallFailOpen": $firewall_fail_open} | compact
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

# Updates the firewall domain list from an array of domain specifications.
#
# POST /
# operationId: UpdateFirewallDomains
export def "update-firewall-domains" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  firewall_domain_list_id: string # The ID of the domain list whose domains you want to update.
  operation: string@operation-completer-1 # What you want DNS Firewall to do with the domains that you are providing: ADD - Add the domains to the ones that are already in the domain list. REMOVE - Search the domain list for the domains and remove them from the list. REPLACE - Update the domain list to exactly match the list that you are providing.
  domains: list<string> # A list of domains to use in the update operation. There is a limit of 1000 domains per request. Each domain specification in your domain list must satisfy the following requirements: It can optionally start with * (asterisk). With the exception of the optional starting asterisk, it must only contain the following characters: A-Z, a-z, 0-9, - (hyphen). It must be from 1-255 characters in length.
]: any -> record<Id: string, Name: string, Status: string, StatusMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateFirewallDomains")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallDomainListId": $firewall_domain_list_id, "Operation": $operation, "Domains": $domains} | compact
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

# Updates the specified firewall rule.
#
# POST /
# operationId: UpdateFirewallRule
export def "update-firewall-rule" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group for the rule.
  firewall_domain_list_id: string # The ID of the domain list to use in the rule.
  --priority: int # The setting that determines the processing order of the rule in the rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting. You must specify a unique priority for each rule in a rule group. To make it easier to insert rules later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for the rules in a rule group at any time.
  --action: string@action-completer # The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request to go through but send an alert to the logs. BLOCK - Disallow the request. This option requires additional details in the rule's BlockResponse.
  --block-response: string@block-response-completer # The way that you want DNS Firewall to block the request. Used for the rule action setting BLOCK. NODATA - Respond indicating that the query was successful, but no response is available for it. NXDOMAIN - Respond indicating that the domain name that's in the query doesn't exist. OVERRIDE - Provide a custom override in the response. This option requires custom handling details in the rule's BlockOverride* settings.
  --block-override-domain: string # The custom DNS record to send back in response to the query. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --block-override-dns-type: string@block-override-dns-type-completer # The DNS record's type. This determines the format of the record value that you provided in BlockOverrideDomain. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --block-override-ttl: int # The recommended amount of time, in seconds, for the DNS resolver or web browser to cache the provided override record. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --name: string # The name of the rule.
]: any -> record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateFirewallRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupId": $firewall_rule_group_id, "FirewallDomainListId": $firewall_domain_list_id, "Priority": $priority, "Action": $action, "BlockResponse": $block_response, "BlockOverrideDomain": $block_override_domain, "BlockOverrideDnsType": $block_override_dns_type, "BlockOverrideTtl": $block_override_ttl, "Name": $name} | compact
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

# Changes the association of a FirewallRuleGroup with a VPC. The association enables DNS filtering for the VPC.
#
# POST /
# operationId: UpdateFirewallRuleGroupAssociation
export def "update-firewall-rule-group-association" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
  --priority: int # The setting that determines the processing order of the rule group among the rule groups that you associate with the specified VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting. You must specify a unique priority for each rule group that you associate with a single VPC. To make it easier to insert rule groups later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for a rule group association after you create it.
  --mutation-protection: string@mutation-protection-completer # If enabled, this setting disallows modification or removal of the association, to help prevent against accidentally altering DNS firewall protections.
  --name: string # The name of the rule group association.
]: any -> record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateFirewallRuleGroupAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallRuleGroupAssociationId": $firewall_rule_group_association_id, "Priority": $priority, "MutationProtection": $mutation_protection, "Name": $name} | compact
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

# Updates the behavior configuration of Route 53 Resolver behavior for a single VPC from Amazon Virtual Private Cloud.
#
# POST /
# operationId: UpdateResolverConfig
export def "update-resolver-config" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  resource_id: string # Resource ID of the Amazon VPC that you want to update the Resolver configuration for.
  autodefined_reverse_flag: string@autodefined-reverse-flag-completer # Indicates whether or not the Resolver will create autodefined rules for reverse DNS lookups. This is enabled by default. Disabling this option will also affect EC2-Classic instances using ClassicLink. For more information, see ClassicLink (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-classiclink.html) in the Amazon EC2 guide. We are retiring EC2-Classic on August 15, 2022. We recommend that you migrate from EC2-Classic to a VPC. For more information, see Migrate from EC2-Classic to a VPC (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-migrate.html) in the Amazon EC2 guide and the blog EC2-Classic Networking is Retiring – Here’s How to Prepare (http://aws.amazon.com/blogs/aws/ec2-classic-is-retiring-heres-how-to-prepare/). It can take some time for the status change to be completed.
]: any -> record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateResolverConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "AutodefinedReverseFlag": $autodefined_reverse_flag} | compact
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

# Updates an existing DNSSEC validation configuration. If there is no existing DNSSEC validation configuration, one is created.
#
# POST /
# operationId: UpdateResolverDnssecConfig
export def "update-resolver-dnssec-config" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_id: string # The ID of the virtual private cloud (VPC) that you're updating the DNSSEC validation status for.
  validation: string@validation-completer # The new value that you are specifying for DNSSEC validation for the VPC. The value can be ENABLE or DISABLE. Be aware that it can take time for a validation status change to be completed.
]: any -> record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateResolverDnssecConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "Validation": $validation} | compact
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

# Updates the name, or enpoint type for an inbound or an outbound Resolver endpoint. You can only update between IPV4 and DUALSTACK, IPV6 endpoint type can't be updated to other type.
#
# POST /
# operationId: UpdateResolverEndpoint
# --UpdateIpAddresses item shape: {IpId: string, Ipv6: string}
export def "update-resolver-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to update.
  --name: string # The name of the Resolver endpoint that you want to update.
  --resolver-endpoint-type: string@resolver-endpoint-type-completer # Specifies the endpoint type for what type of IP address the endpoint uses to forward DNS queries.
  --update-ip-addresses: list # Updates the Resolver endpoint type to IpV4, Ipv6, or dual-stack. — item shape: {IpId: string, Ipv6: string}
]: any -> record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateResolverEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverEndpointId": $resolver_endpoint_id, "Name": $name, "ResolverEndpointType": $resolver_endpoint_type, "UpdateIpAddresses": $update_ip_addresses} | compact
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

# Updates settings for a specified Resolver rule. ResolverRuleId is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
#
# POST /
# operationId: UpdateResolverRule
# --Config shape: {Name?: string, TargetIps?: list, ResolverEndpointId?: string}
export def "update-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  resolver_rule_id: string # The ID of the Resolver rule that you want to update.
  config: record # In an UpdateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverRule.html) request, information about the changes that you want to make. — shape: {Name?: string, TargetIps?: list, ResolverEndpointId?: string}
]: any -> record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Resolver.UpdateResolverRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResolverRuleId": $resolver_rule_id, "Config": $config} | compact
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
